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
	input [1:0] read_write,
//	input read_write,
//  input [15:0] data_in,
//  input quad_start,
	
	output endcommand,
	output reg mem_ce,
	inout [3:0] mem_sio,
//  output reg [15:0] data_out
    inout [15:0] message 
);

//Reinitialization commands
parameter [7:0] CMD_RSTEN = 8'h66;
parameter [7:0] CMD_RST = 8'h99;
parameter [7:0] SPI2QPI = 8'h35;

//Read & Write start commands
parameter [7:0] CMD_READ = 8'hEB;
parameter [7:0] CMD_WRITE = 8'h38;

//Variables

//REG

reg [5:0] counter;						//Counter to send SPI & QPI commands
reg sendcommand;						//Flag indicates when sending a command
reg quad_start;                         //Flag indicates when a QPI communication has started
reg [1:0] d_read_write;                 //Aux reg to store read_write value
reg able_2_end;                        //Flag indicates when endcommand can be assigned

//reg [15:0] data_write;


reg reading;							//Reg indicates when in a writing proccess
reg writing;							//Reg indicates when in a reading proccess
reg [15:0] data;                        //Receives data_in OR data_out; reg to be used in procedural routine
reg flag;

reg [3:0] mem_sio_reg;

assign com_start = quad_start || spi_start;

//mem_sio is an output when counter < 8 (sending address) and when writing and counter < 12 (sending message)
assign mem_sio = (0 < counter < 8+1 || (read_write == 1 && 8+1 <=counter < 12+1)) ? mem_sio_reg : 4'bzzzz;
//assign mem_sio = (counter < 8+1 || (!read_write && 8+1<=counter < 12+1)) ? mem_sio_reg : 4'bzzzz;


//Message is an output only when reading AND counter == 19
assign message = (read_write == 2 && counter > 18) ? data : 16'hz;
//assign message = (read_write && counter > 18) ? data : 16'hz;


//Initial conditions
initial begin
	counter <= 0;
	sendcommand <= 0;
	mem_ce <= 1;
	reading <= 0;
	writing <= 0;
    quad_start <= 0;
    flag <= 0;
    able_2_end <= 0;
end

always @(negedge mem_clk) begin

    able_2_end <= 0;

    //This part of script allows to communicate only changing the state of read_write

    //Sets flag to HIGH when a change of read_write requisition occurs. ie: read_write from 0 to 1 (idle to writing) or 1 to 2 (writing to reading)
    //Besides, read_write NEEDS to be 1 OR 2 (aka write or read)
    if((read_write != d_read_write) && (read_write == 1 || read_write == 2)) begin
        flag <= 1;
    end
    //When there's no apparent change, sets flag LOW in order not to trigger quad_start AGAIN, only upon a change in read_write
    else begin
        flag <= 0;
    end

    //if flag is HIGH, a once only requisition was ordered. Thus, a communication's to be started. Sendcommand is also triggered because of endcommand (otherwise it'd not work)
    if(flag) begin
        quad_start <= 1;
    end

    d_read_write <= read_write;

//When com_start turns high, starts communication
	if(com_start) begin
        
		counter <= 0;
        sendcommand <= 1;

		//Define reading or writing proccess
		if (quad_start) begin
			if (read_write == 2) begin
//			if (read_write) begin
				reading <= 1;
			end
			else if(read_write == 1) begin
//			else if(!read_write) begin
				writing <= 1;
                data <= message;
				//data_write <= data_in;
			end
		end
	end

    // 1 clock delay
	if (sendcommand) mem_ce <= 0;

	case(qpi_on)

		//SPI communication
		0: begin
			if (sendcommand) begin
				mem_sio_reg[3:0] <= {3'bzzz,command[7-counter]}; //MSB first
				counter <= counter + 1'd1;
			end
			
			//End of command of 8 bits
			if (counter > 3'd7) begin
				sendcommand <= 0;
				counter <= 0;
				mem_ce <= 1;
			end
		end

		//QPI communication
		1: begin

			if(com_start & sendcommand) begin

				counter <= counter + 1'd1;

				case (counter)

				//Operation command
//				0: mem_sio_reg <= (read_write == 2) ? CMD_READ[7:4] : CMD_WRITE[7:4];
//				1: mem_sio_reg <= (read_write == 2) ? CMD_READ[3:0] : CMD_WRITE[3:0];
				0: mem_sio_reg <= (read_write == 2) ? CMD_READ[7:4] : CMD_WRITE[7:4];
				1: mem_sio_reg <= (read_write == 2) ? CMD_READ[3:0] : CMD_WRITE[3:0];
				//Address command
				2: mem_sio_reg <= address[23:20];
				3: mem_sio_reg <= address[19:16];
				4: mem_sio_reg <= address[15:12];
				5: mem_sio_reg <= address[11:8];
				6: mem_sio_reg <= address[7:4];
				7: mem_sio_reg <= address[3:0];

				//Message
				default: begin

					if(reading) begin
						if(counter > 14 && counter <= 18) begin	//Wait for 6 clocks + taclk in read operation. See datasheet for more details.

							data <= {data[11:0],mem_sio[3:0]}; //MSB is read first
							// data psram: x x x x  y y y y  z z z z  w w w w
							//
							//step 0:
							// data = _ _ _ _  _ _ _ _  _ _ _ _  _ _ _ _
							//
							// step 1:
							// mem_sio[3:0] = 4'b x x x x
							// data* = _ _ _ _  _ _ _ _  _ _ _ _  x x x x

							// step 2:
							// mem_sio[3:0] = 4'b y y y y
							// data = _ _ _ _  _ _ _ _  x x x x  y y y y
							//			-	   data*[11:0]     - mem_sio[3:0]
						end
						else if(counter >= 18) begin
							reading <= 0;
						end
						else mem_sio_reg[3:0] <= 4'bzzzz;
					end
					else if(writing) begin
							if(counter < 12) begin
								{mem_sio_reg, data[15:4]} <= data;								
								//data = x x x x  y y y y  z z z z  w w w w
								//
								//step1:
								//mem_sio = x x x x
								//data = y y y y  z z z z  w w w w  w w w w
								//
								//step 2:
								//mem_sio = y y y y
								//data = z z z z  w w w w  w w w w  w w w w

							end
							else begin
								writing <= 0;
							end
					end

					else begin //End of communication
						mem_sio_reg[3:0] <= 4'bzzzz;
						sendcommand <= 0;
						mem_ce <= 1;
                        able_2_end <= 1;
                        quad_start <= 0;
                        
                    //Necessary, otherwise proccess goes wrong => writing OR reading goes to HIGH due to quad_start = 1
                        writing <= 0;
                        reading <= 0;
					end
					end
				endcase
			end
		end
	endcase
end

//endcommand assigned HIGH when communication is finished
//In QPI: able_2_end is only high when sendcommand went from 0 to 1 and 0 again, COMPLETING THE communication
assign endcommand = (spi_start || able_2_end) && ~sendcommand;

endmodule


//PSRAM "TOP module"
module psram(
	input mem_clk,				// pin 47
    input startbu,              // start button to initialize PSRAM - Tang Nano ButtonA
	input [23:0] address,
	input [1:0] read_write,
//	input read_write,
//  input [15:0] data_in,
//  input quad_start,
	
	output endcommand,
	output mem_ce,        		// pin 42
	output reg qpi_on,

	inout [3:0] mem_sio,    	    // sio[0] pin 40, sio[1] pin 39, sio[2] pin 38, sio[3] pin 41
//  output [15:0] data_out    

inout [15:0] message
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
	.read_write(read_write),
//  .quad_start(quad_start),

	
	.endcommand(endcommand),
	.mem_ce(mem_ce),
	.mem_sio(mem_sio),
//	.data_in(data_in),
//  .data_out(data_out
    .message(message)
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

	if(start) begin		//Begin initialization if startbu was pressed
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