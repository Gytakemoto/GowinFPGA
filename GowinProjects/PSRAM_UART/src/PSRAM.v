//File created to test PSRAM module in Sipeed Tang Nano 1k

//Memory driver: interprets commands based on Datasheet
module memory_driver(

	//INPUT
	input mem_clk,
	input [7:0] command,
	input [3:0] step,
	input spi_start,
	input qpi_on,
	input [22:0] address,
	input [1:0] read_write,
	input quad_start,
	input [15:0] data_in,
	
	output endcommand,
	output reg mem_ce,
	output reg [15:0] data_out,
	//output reg read_psram,

	//inout [15:0] message,
	inout [3:0] mem_sio
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
reg sendcommand;							//Flag indicates when sending a command. In faact, responsible for starting communication.

reg reading;									//Reg indicates when in a reading proccess
reg writing;									//Reg indicates when in a writing proccess
reg [15:0] data_write;				//Receives data_in; reg to be used in procedural routine
reg [3:0] mem_sio_reg;				//mem_sio 4-bit bus to PSRAM communication. Reg to be used in procedural routine.
reg flag;											//Flag signal to control communication. Might be substituided by sendcommand? (?)
reg [15:0] debug;

//Initial conditions
initial begin
	counter <= 0;
	sendcommand <= 0;
	reading <= 0;
	writing <= 0;
	mem_ce <= 1;
	mem_sio_reg <= 4'h0;
	flag <= 0;
	data_out <= 0;
	data_write <= 0;
    debug <= 3;
end

// com_start flag to indicate when communication can initiate
assign com_start = quad_start || spi_start;

//mem_sio is an output when counter < 8 (sending address) and when writing and counter < 12 (sending message)
//Must be LOW when step == 0 (delay step), by datasheet
//It changes every negative-edge transition, to be read in the positive one. Thus, starts right at counter = 0
assign mem_sio = (step == 0 ? 4'h0 : (((reading || spi_start) && (0 <= counter && counter <= 7 )) || (writing && (0 <= counter && counter <= 12))) ? mem_sio_reg : 4'bz);

//assign message = read_write ? 

//Positive edge routine: grab read values
always @(posedge mem_clk) begin
	case(qpi_on)
			1: begin
				if(flag && sendcommand) begin

					if (reading) begin
						//Obs*: Counter may change with sampling freq (this is for 84MHz)
							case (counter)
									16: begin
											data_out[15:12] <= mem_sio[3:0];  // 4 most significant bits       
									end
									17: begin
											data_out[11:8] <= mem_sio[3:0];  // Read next 4 bits
									end
									18: begin
											data_out[7:4] <= mem_sio[3:0];   // Read next 4 bits
									end
									19: begin
											data_out[3:0] <= mem_sio[3:0];   // Read last 4 bits
									end
							endcase
					end	
				end
			end
	endcase
end

//Negative edge rountine: assign values to be WRITTEN (address, messages)
always @(negedge mem_clk) begin

	//Update registers in order to avoid implicit latch
	flag <= flag;
	sendcommand <= sendcommand;
	data_out <= data_out;
	data_write <= data_write;

	//End of coms
	if(endcommand) begin
			flag <= 0;
	end

	//Start of coms
	if(quad_start) begin
        flag <= 1;
	end

	//When com_start turns high, starts communication
	if(com_start) begin
				
		counter <= 0;
		sendcommand <= 1;

		//Define reading or writing proccess
		if (quad_start) begin

            debug <= read_write;

			if (read_write == 2) begin
                reading <= 1;
			end
			else if(read_write == 1) begin
					writing <= 1;
					data_write <= data_in;
					//data <= message;
                    //debug <= data_in;
			end
		end
	end

		// 1 clock delay
	if (sendcommand) begin
				mem_ce <= 0;
	end

	case(qpi_on)

		//SPI communication
		0: begin
			if (sendcommand) begin
				if(counter <= 7) begin
					mem_sio_reg[3:0] = {3'bzzz,command[7-counter]}; //MSB first
				end
				counter <= counter + 1'd1;
			end
			
			//End of command of 8 bits
			if (counter > 4'd9) begin
				sendcommand <= 0;
				counter <= 0;
				mem_ce <= 1;
			end
		end

		//QPI communication
		1: begin

			if(flag && sendcommand) begin

				counter <= counter + 1'd1;

				case (counter)

					//Operation command
					0: begin
						if(read_write == 2) mem_sio_reg <= CMD_READ[7:4]; 
						else if(read_write == 1) mem_sio_reg <= CMD_WRITE[7:4];
					end
					1: begin
						if(read_write == 2) mem_sio_reg <= CMD_READ[3:0];
						else if(read_write == 1) mem_sio_reg <= CMD_WRITE[3:0];
					end
					//Address command
					2: mem_sio_reg <= {1'b0, address[22:20]};
					3: mem_sio_reg <= address[19:16];
					4: mem_sio_reg <= address[15:12];
					5: mem_sio_reg <= address[11:8];
					6: mem_sio_reg <= address[7:4];
					7: mem_sio_reg <= address[3:0];

					//Message
					default: begin

						//If on read proccess
						if (reading) begin

							mem_sio_reg[3:0] <= 4'hz;   	//Assert high-Z
							reading <= 1;					//Update register

							//Reading proccess ending
							if (counter >= 21) begin
									reading <= 0;  
									mem_ce <= 1;
							end
						end
						else if(writing) begin
							
							writing <= 1;														//Update register

							if(8 <= counter && counter < 12) begin
								mem_sio_reg <= data_write[15:12]; 		//Sending 4 most significant bits
								data_write <= data_write << 4;    		// 4-bit shift: update next 4 MSB
							end
							//Writing proccess ending
							else if (counter > 12) begin
								writing <= 0;
									mem_sio_reg[3:0] <= 4'hz;
									mem_ce <= 1;
							end
						end
						else begin //End of communication
							mem_sio_reg[3:0] = 4'bzzzz;
							sendcommand <= 0;
							mem_ce <= 1;

							//Maybe can be removed(?)
							counter <= 0;
							//Necessary, otherwise proccess goes wrong => writing OR reading goes to HIGH due to quad_start = 1
							writing <= 0;
							reading <= 0;
                            //debug <= 1;
						end
					end
				endcase
			end
		end
	endcase
end

//endcommand assigned HIGH when communication is finished
assign endcommand = (flag || spi_start) && ~sendcommand;

endmodule


//PSRAM "TOP module"
module psram(
	input mem_clk,							// Pin 47
    input startbu,              // start button to initialize PSRAM - Tang Nano ButtonA
	input [22:0] address,
	input [1:0] read_write,
	input quad_start,
	input [15:0] data_in,
	
	output endcommand,
	output mem_ce,        		// pin 42
	output [15:0] data_out,
	output reg qpi_on,
	output mem_clk_enabled,					//clk sent to PSRAM after delay time
	//output reg read_psram,
	//inout [15:0] message,
	inout [3:0] mem_sio   	    // sio[0] pin 40, sio[1] pin 39, sio[2] pin 38, sio[3] pin 41

);

//Local parameters
localparam [2:0] STEP_DELAY = 0; //First state, wait for >150us
localparam [2:0] STEP_RSTEN = 1; //Second state, RSTEN operation
localparam [2:0] STEP_RST = 2;   //Third state, RST state
localparam [2:0] STEP_SPI2QPI = 3;
localparam [2:0] STEP_IDLE = 4;

//Variables
reg [15:0] timer = 0;			//Counter
reg [7:0] command;				//SPI 8 bit command
reg start = 0;				  	//Start initialization, when button pressed
reg spi_start = 0;
reg [3:0] step = STEP_DELAY;   //indicates the current operation
									//0: >150us required delay
									//1: Reset enable (RSTEN) step
									//2: Reset (RST) step
									//3: Idle normal operation state

memory_driver PSRAM_com(
	.mem_clk(mem_clk),
	.command(command),
	.step(step),
	.spi_start(spi_start),
	.qpi_on(qpi_on),
	.address(address),
	.read_write(read_write),
	.quad_start(quad_start),
	.data_in(data_in),
	
  //	.read_psram(read_psram),
	.endcommand(endcommand),
	.mem_ce(mem_ce),
	.mem_sio(mem_sio),
	.data_out(data_out)
	//.message(message)
);

initial begin
	step <= STEP_DELAY;
	timer <= 0;
	spi_start <= 0;
	qpi_on <= 0;
end

//When in delay step, output LOW, defined by datasheet
assign mem_clk_enabled = (step == STEP_DELAY) ? 0 : mem_clk;

always @(posedge mem_clk) begin

	if(!startbu) begin
		 start = 1;	    //Detect button pressed
	end

	if(start) begin		//Begin initialization if startbu was pressed
		case(step)
			STEP_DELAY: begin
				timer <= timer + 1'd1;
				if(timer[15:8] == 8'h50) begin 		// #50h = #80d. 80 * 256 (thus the 8-bit swap) = 12.800 clocks inputs. At 84Mhz, we have a t ~= 243 us.
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