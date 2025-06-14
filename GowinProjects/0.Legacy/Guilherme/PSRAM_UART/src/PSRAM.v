/* --------------------------------- ReadMe --------------------------------- */

/*
Module developed to interface with a Lyontech LY68L6400 PSRAM device in a system 
with a quad-SPI interface.

It has two main modules. One for initialization control (i.e delay timing and startup
commands) and another for memory writing and reading processess.

Todo: Increase stability and error handling. Can be optimized.

! Stabilized with 84MHz clock signal. Changes in clock frequency might lead to errors.

/* -------------------------------------------------------------------------- */


/* ------------------------------ Memory Driver ----------------------------- */

//Read and write routines for PSRAM
module memory_driver(
	//INPUT
	input mem_clk,										// 84MHz rPLL generated signal

	//Initialization
	input [7:0] command,								// 8 bit command used in SPI mode
	input [3:0] step,									// Step of PSRAM initialization. Important to ensure a deactivated mem_sio in PSRAM starting
	input spi_start,									// quad_start relative to SPI communication
	input qpi_on,										// Flag - indicates whether QPI mode is enabled (i.e initialization routine is DONE)

	//Read-write in QPI mode
	input [22:0] address,								// 23-bit PSRAM address
	input [1:0] read_write,								// Define read OR write command
	input quad_start,									// Rising-edge detection to request a writing/reading
	input [15:0] data_in,								// Data to be written to PSRAM
	
	//OUTPUT
	output endcommand,									// Flag - indicates when the PSRAM reading/writing process is completed		
	output reg mem_ce,									// PSRAM chip enable signal
	output reg [15:0] data_out,							// Data read from PSRAM

	//INOUT
	inout [3:0] mem_sio									// Communication busbar for PSRAM communication
);

/* -------------------------------- Commands -------------------------------- */

// Reinitialization commands
parameter [7:0] CMD_RSTEN = 8'h66;
parameter [7:0] CMD_RST = 8'h99;
parameter [7:0] SPI2QPI = 8'h35;

// Read & Write start commands
parameter [7:0] CMD_READ = 8'hEB;
parameter [7:0] CMD_WRITE = 8'h38;

/* -------------------------------- Variables ------------------------------- */

reg [5:0] counter;										// Counter to send SPI & QPI commands
reg sendcommand;										// Flag - indicates when sending a command. In fact, responsible for starting communication
reg reading;											// Indicates when in a reading proccess
reg writing;											// Indicates when in a writing proccess
reg [15:0] data_write;									// Receives data_in; reg to be used in procedural routine
reg [3:0] mem_sio_reg;									// mem_sio 4-bit bus to PSRAM communication. Reg to be used in procedural routine.
reg flag;												// Flag - signal to control communication. Might be substituided by sendcommand? (?)
wire com_start;											// Signal used to detect rising edge requisition

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
end

// com_start flag to indicate when communication can initiate
assign com_start = quad_start || spi_start;

// mem_sio is an output when counter < 8 (sending address) and when writing and counter < 12 (sending message)
// Must be LOW when step == 0 (delay step), by datasheet
// It changes every negative-edge transition, to be read in the positive one. Thus, starts right at counter = 0
assign mem_sio = (step == 0 ? 4'h0 : (((reading || spi_start) && (0 <= counter && counter <= 7 )) || (writing && (0 <= counter && counter <= 12))) ? mem_sio_reg : 4'bz);

//Positive edge routine: grab read values
always @(posedge mem_clk) begin
	if(qpi_on) begin
		if(flag && sendcommand) begin
			if (reading) begin
				//! Counter may change with sampling freq (this is for 84MHz)
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
end

// Negative edge rountine: assign values to be WRITTEN (address, messages)
always @(negedge mem_clk) begin
	//* Update registers in order to avoid inferred latches
	flag <= flag;
	sendcommand <= sendcommand;
	data_out <= data_out;
	data_write <= data_write;

	// End of communication
	if(endcommand) begin
		flag <= 0;
	end

	// Start of communication
	if(quad_start) begin
        flag <= 1;
	end

	// When com_start turns high, starts communication
	if(com_start) begin
		counter <= 0;
		sendcommand <= 1;
		// Define reading or writing proccess
		if (quad_start) begin
			if (read_write == 2) begin
                reading <= 1;
			end
			else if(read_write == 1) begin
				writing <= 1;
				data_write <= data_in;
			end
		end
	end
	// 1 clock delay
	if (sendcommand) begin
		mem_ce <= 0;
	end

	case(qpi_on)
		// SPI communication - used during initialization process
		0: begin
			if (sendcommand) begin
				if(counter <= 7) begin
					mem_sio_reg[3:0] = {3'bzzz,command[7-counter]}; // MSB first
				end
				counter <= counter + 1'd1;
			end
			
			//End of command
			if (counter > 4'd9) begin
				sendcommand <= 0;
				counter <= 0;
				mem_ce <= 1;
			end
		end
		// QPI communication - used during normal operation
		1: begin
			if(flag && sendcommand) begin								// Certifies that process's started and a reading or writing is defined
				counter <= counter + 1'd1;
				case (counter)
					// Operation command
					0: begin
						if(read_write == 2) mem_sio_reg <= CMD_READ[7:4]; 
						else if(read_write == 1) mem_sio_reg <= CMD_WRITE[7:4];
					end
					1: begin
						if(read_write == 2) mem_sio_reg <= CMD_READ[3:0];
						else if(read_write == 1) mem_sio_reg <= CMD_WRITE[3:0];
					end
					// Address command
					2: mem_sio_reg <= {1'b0, address[22:20]};
					3: mem_sio_reg <= address[19:16];
					4: mem_sio_reg <= address[15:12];
					5: mem_sio_reg <= address[11:8];
					6: mem_sio_reg <= address[7:4];
					7: mem_sio_reg <= address[3:0];
					//Message
					default: begin
						//If on read proccess
						if (reading) begin								//* Reading has to happen at positive clock due to timing constraints
							mem_sio_reg[3:0] <= 4'hz;   				// Assert high-Z
							reading <= 1;								// Update register
							// Reading proccess ending
							if (counter >= 21) begin
								reading <= 0;  
								mem_ce <= 1;
							end
						end
						else if(writing) begin
							writing <= 1;								// Update register
							if(8 <= counter && counter < 12) begin
								mem_sio_reg <= data_write[15:12]; 		// Sending 4 most significant bits
								data_write <= data_write << 4;    		// 4-bit shift: update next 4 MSB
							end
							// Writing proccess ending
							else if (counter > 12) begin
								writing <= 0;
								mem_sio_reg[3:0] <= 4'hz;
								mem_ce <= 1;
							end
						end
						else begin // End of communication
							mem_sio_reg[3:0] = 4'bzzzz;
							sendcommand <= 0;
							mem_ce <= 1;
							counter <= 0;
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


/* ------------------------------- Top module ------------------------------- */

module psram(

	//INPUT
	input mem_clk,							// 84MHz rPLL generated clock

	//Read-write in QPI mode
	input [22:0] address,								// 23-bit PSRAM address
	input [1:0] read_write,								// Define read OR write command
	input quad_start,									// Rising-edge detection to request a writing/reading
	input [15:0] data_in,								// Data to be written to PSRAM
	
	//OUTPUT
	output endcommand,									// Flag - indicates when the PSRAM reading/writing process is completed		
	output mem_ce,										// PSRAM chip enable signal
	output [15:0] data_out,								// Data read from PSRAM
	output reg qpi_on,									// Indicates whether QPI mode is enabled (i.e initialization routine is DONE)
	output mem_clk_enabled,								//! clk sent to PSRAM only after delay time - startup MUST not have a clock signal

//INOUT
	inout [3:0] mem_sio   	    						// Communication busbar for PSRAM communication

);

/* ---------------------------- Local parameters ---------------------------- */

localparam [2:0] STEP_DELAY = 0; 						// First state, wait for >150us
localparam [2:0] STEP_RSTEN = 1; 						// Second state, RSTEN operation
localparam [2:0] STEP_RST = 2;   						// Third state, RST state
localparam [2:0] STEP_SPI2QPI = 3;						// Forth state, switch to QPI mode
localparam [2:0] STEP_IDLE = 4;							// Idle state, initialization finished

/* -------------------------------- Variables ------------------------------- */

reg [15:0] timer = 0;									// Timer counter used in start up delay
reg [7:0] command;										// SPI 8 bit command
reg spi_start = 0;

reg [3:0] step = STEP_DELAY;   // Indicates the current operation
									// 0: >150us required delay
									// 1: Reset enable (RSTEN) step
									// 2: Reset (RST) step
									// 3: Idle normal operation state

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

//When in delay step, output LOW, defined by datasheet
assign mem_clk_enabled = (step == STEP_DELAY) ? 0 : mem_clk;

always @(posedge mem_clk) begin

	//Enable qpi_on only after initialization is done
    if(step == STEP_IDLE) qpi_on <= 1;
    else qpi_on <= 0;

    step <= step;

    case(step)
        STEP_DELAY: begin
            qpi_on <= 0;
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
endmodule