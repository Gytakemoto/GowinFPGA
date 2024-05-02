//File created to test PSRAM module in Sipeed Tang Nano 1k

//Memory driver: interprets commands based on Datasheet
module memory_driver(

	//INPUT
	input mem_clk,
	input [7:0] command,
	input [3:0] step,
	input spi_start,
	input qpi_on,
	input [23:0] address,
	input read_sw,
	input write_sw,
	input [15:0] data_in,
	
	output endcommand,
	output reg mem_ce,
	output reg [3:0] mem_sio,
	output reg [15:0] data_out
);

//Reinitialization commands
parameter [7:0] CMD_RSTEN = 8'h66;
parameter [7:0] CMD_RST = 8'h99;
parameter [7:0] SPI2QPI = 8'h35;

//Read & Write start commands
parameter [7:0] CMD_READ = 8'hEB;
parameter [7:0] CMD_WRITE = 8'h38;

//Variables
reg [5:0] counter;						//Counter to send SPI & QPI commands
reg sendcommand;						//Flag indicates when sending a command
reg reading;							//Reg indicates when in a writing proccess
reg writing;							//Reg indicates when in a reading proccess
reg [15:0] data_write;					//Receives data_in; reg to be used in procedural routine

wire quad_start;						//Flag inicates when QUAD com should begin

assign com_start = quad_start || spi_start;
assign quad_start = (~read_sw && write_sw) || (read_sw && ~write_sw);
// quad_start truth table: XOR topology
//				read_sw		         write_sw			quad_start
//					0					 0				 	 0
//					0					 1				 	 1
//					1					 0					 1
//					1					 1					 0

//Initial conditions
initial begin
	counter <= 0;
	sendcommand <= 0;
	mem_ce <= 1;
	reading <= 0;
	writing <= 0;
end

always @(negedge mem_clk) begin

//When com_start turns high, starts communication
	if(com_start) begin

		sendcommand <= 1;
		counter <= 0;

		//Define reading or writing proccess
		if (quad_start) begin
			if (read_sw) begin
				reading <= 1;
			end
			else if (write_sw)  begin
				writing <= 1;
				data_write <= data_in;
			end
		end
	end

	if (sendcommand) mem_ce <= 0;

	case(qpi_on)

		//SPI communication
		0: begin
			if (sendcommand) begin
				mem_sio[3:0] <= {3'bzzz,command[7-counter]}; //MSB first
				counter <= counter + 1'd1;
			end
			
			//End of command of 7 bits
			if (counter > 3'd7) begin
				sendcommand <= 0;
				counter <= 0;
				mem_ce <= 1;
			end
		end

		//QPI communication
		1: begin

			if(quad_start && sendcommand) begin

				counter <= counter + 1'd1;

				case (counter)

				//Operation command
				0: mem_sio <= read_sw ? CMD_READ[7:4] : CMD_WRITE[7:4];
				1: mem_sio <= read_sw ? CMD_READ[3:0] : CMD_WRITE[3:0];

				//Address command
				2: mem_sio <= address[23:20];
				3: mem_sio <= address[19:16];
				4: mem_sio <= address[15:12];
				5: mem_sio <= address[11:8];
				6: mem_sio <= address[7:4];
				7: mem_sio <= address[3:0];

				//Message
				default: begin

					if(reading) begin
						if(counter > 14 && counter <= 18) begin	//Wait for 6 clocks + taclk in read operation. See datasheet for more details.

							data_out <= {data_out[11:0],mem_sio[3:0]}; //MSB is read first
							// data psram: x x x x  y y y y  z z z z  w w w w
							//
							//step 0:
							// data_out = _ _ _ _  _ _ _ _  _ _ _ _  _ _ _ _
							//
							// step 1:
							// mem_sio[3:0] = 4'b x x x x
							// data_out* = _ _ _ _  _ _ _ _  _ _ _ _  x x x x

							// step 2:
							// mem_sio[3:0] = 4'b y y y y
							// data_out = _ _ _ _  _ _ _ _  x x x x  y y y y
							//			-	   data_out*[11:0]     - mem_sio[3:0]
						end
						else if(counter >= 18) begin
							reading <= 0;
						end
						else mem_sio[3:0] <= 4'bzzzz;
					end
					else if(writing) begin
							if(counter < 12) begin
								{mem_sio, data_write[15:4]} <= data_write;								
								//data_write = x x x x  y y y y  z z z z  w w w w
								//
								//step1:
								//mem_sio = x x x x
								//data_write = y y y y  z z z z  w w w w  w w w w
								//
								//step 2:
								//mem_sio = y y y y
								//data_write = z z z z  w w w w  w w w w  w w w w

							end
							else begin
								writing <= 0;
							end
					end

					else begin //End of communication
						mem_sio[3:0] <= 4'bzzzz;
						counter <= 0;
						sendcommand <= 0;
						mem_ce <= 1;
                        writing <= 0;
                        reading <= 0;
					end
					end
				endcase
			end
		end
	endcase
end

assign endcommand = (com_start || quad_start) && ~sendcommand;
//assign endcommand = (~(com_start || quad_start) && sendcommand) || ((com_start || quad_start) && ~sendcommand);

endmodule


//PSRAM "TOP module"
module psram(
	input mem_clk,				// pin 47
    input startbu,              // start button to initialize PSRAM - Tang Nano ButtonA
	input [23:0] address,
	input read_sw,
	input write_sw,
	input [15:0] data_in,
	
	output endcommand,
	output mem_ce,        		// pin 42
	output wire [15:0] data_out,
	output reg qpi_on,

	inout [3:0] mem_sio    	    // sio[0] pin 40, sio[1] pin 39, sio[2] pin 38, sio[3] pin 41
);

//Local parameters
localparam [2:0] STEP_DELAY = 0; //First state, wait for 150us
localparam [2:0] STEP_RSTEN = 1; //Second state, RSTEN operation
localparam [2:0] STEP_RST = 2;   //Third state, RST state
localparam [2:0] STEP_SPI2QPI = 3;
localparam [2:0] STEP_IDLE = 4;

//Variables
reg [3:0] step = STEP_DELAY;   //indicates the current operation
									//0: 150us required delay
									//1: Reset enable (RSTEN) step
									//2: Reset (RST) step
									//3: Idle normal operation state

reg [15:0] timer = 0;			//Counter
reg [7:0] command;				//SPI 8 bit command

reg start = 0;				  	//Start initialization, when button pressed

wire com_start = 0;				//Control communication status during auto-initialization
															//0: End the communication
															//1: Start the communication

reg spi_start = 0;

//reg qpi_on;						//Communication mode
															//0: SPI communication
															//1: QPI communication

memory_driver PSRAM_com(
	.mem_clk(mem_clk),
	.command(command),
	.step(step),
	.spi_start(spi_start),
	.qpi_on(qpi_on),
	.address(address),
	.read_sw(read_sw),
	.write_sw(write_sw),
	.data_in(data_in),
	
	.endcommand(endcommand),
	.mem_ce(mem_ce),
	.mem_sio(mem_sio),
	.data_out(data_out)
);

initial begin
	step <= STEP_DELAY;
	timer <= 0;
	spi_start <= 0;
	qpi_on <= 0;
end

always @(posedge mem_clk) begin

	if(!startbu) begin
		 start = 1;	    //Detect button pressed
	end

	if(start) begin		//Begin initialization if mem isn't idle, startbu was pressed and message isn't being sent
		case(step)
			STEP_DELAY: begin
				timer <= timer + 1'd1;
				if(timer[15:8] == 8'h32) begin 		// #32h = #50d. 50 * 256 (thus the 8-bit swap) = 12.800 clocks inputs. At 84Mhz, we have a t ~= 152 us.
					step <= STEP_RSTEN;
					timer <= 16'b0;					//Reset timer
				end
        	end
			STEP_RSTEN: begin
				command <= PSRAM_com.CMD_RSTEN;
				spi_start <= 1;
				qpi_on <= 0;
				if(endcommand) begin
					step <= STEP_RST;
					spi_start <= 0;
				end
			end
			STEP_RST: begin
				command <= PSRAM_com.CMD_RST;
				spi_start <= 1;
				qpi_on <= 0;
				if(endcommand) begin
					step <= STEP_SPI2QPI;
					spi_start <= 0;
				end
			end
			STEP_SPI2QPI: begin
				command <= PSRAM_com.SPI2QPI;
				spi_start <= 1;
				qpi_on <= 0;
				if(endcommand) begin
					step <= STEP_IDLE;
					spi_start <= 0;
				end 
			end
			STEP_IDLE: begin
				spi_start <= 0;
				qpi_on <= 1;
			end
		endcase	
	end
end
endmodule