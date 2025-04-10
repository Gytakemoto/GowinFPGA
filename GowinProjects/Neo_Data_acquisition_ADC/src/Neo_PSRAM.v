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
module memory_driver# (
    parameter ADC_FREQ = 6        // Desired sampling frequency in MHz
)(
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
    input burst_mode,
    input fifo_empty,
	
	//OUTPUT
    output endcommand,
	output mem_ce,									// PSRAM chip enable signal
	output reg [15:0] data_out,							// Data read from PSRAM
    //output reg debug,
    output reg debug_2,
    output reg fifo_rd,

	//INOUT
	inout [3:0] mem_sio									// Communication busbar for PSRAM communication
);

/* -------------------------------- Commands -------------------------------- */

// Read & Write start commands
localparam [7:0] CMD_READ = 8'hEB;
localparam [7:0] CMD_WRITE = 8'h38;
localparam BURST_INTERVAL = 8; //us
localparam TIMER = 116; 

/* -------------------------------- Variables ------------------------------- */

// Counter to send SPI & QPI commands
reg [5:0] counter;

reg [$clog2(TIMER)-1 : 0] burst_counter;	
reg [15:0] data_write;
reg [22:0] address_reg;

//Start flag
wire start; // Start read/write
assign start = quad_start || spi_start;

//Endcommand
reg ended;
//mem_ce for single message
assign mem_ce = !(start || !ended); //needs to change in burst mode

//Reading or writing process
reg writing;
reg reading;

//PSRAM communication
reg [3:0] mem_sio_reg; // mem_sio 4-bit bus to PSRAM communication. Reg to be used in procedural routine.
assign mem_sio = (step == 0 ? 4'h0 :
((((read_write == 2'd2) || spi_start) && (counter <= 8)) || (read_write == 2'd1 && (counter <= 12)) && (start || !ended)) ? mem_sio_reg : 4'bz);

//Identify ended posedge
reg prev_ended;
assign endcommand = (ended && !prev_ended) ? 1:0;

//Decide whether stop burst com or not
reg stop_burst;

initial begin
	data_out <= 16'h0000;
    counter <= 0;
    ended <= 1;
    burst_counter <= 0;
    mem_sio_reg <= 4'bz;
    //debug <= 0;
end

//Working at negedge to sincronize with PSRAM positive clock. Changing right before PSRAM
always @(negedge mem_clk) begin

    prev_ended <= ended;
    //apagar depois
    //data_write <= 16'hABCd;
    address_reg <= address;
    fifo_rd <= 0;
    ended <= ended;
    
    if(start) begin
		ended <= 0;
    end

    if(start || !ended) counter <= counter + 1'd1;

	// SPI communication - used during initialization process
    if (!qpi_on && counter <= 7 && (start || !ended)) begin
        mem_sio_reg[3:0] = {3'bzzz,command[7-counter]}; // MSB first
    end
    
    //End of command
    if (!qpi_on && counter > 4'd7) begin
        ended <= 1;
        counter <= 0;
    end

	// QPI communication - used during normal operation
    if(qpi_on && (start || !ended)) begin								// Certifies that process's started and a reading or writing is defined
        case (counter)
            // Operation command
            0: begin
                if(read_write == 2'd2) begin
                    mem_sio_reg <= CMD_READ[7:4]; 
                    reading <= 1;
                end
                else if(read_write == 2'd1) begin
                    mem_sio_reg <= CMD_WRITE[7:4];
                    writing <= 1;
                    if(burst_mode) fifo_rd <= 1;
                end
            end
            1: begin
                if(reading) mem_sio_reg <= CMD_READ[3:0];
                else if(writing) begin
                    mem_sio_reg <= CMD_WRITE[3:0];
                    data_write <= data_in;
                end
                
            end
            2: mem_sio_reg <= {1'b0, address_reg[22:20]};
            3: mem_sio_reg <= address_reg[19:16];
            4: mem_sio_reg <= address_reg[15:12];
            5: mem_sio_reg <= address_reg[11:8];
            6: mem_sio_reg <= address_reg[7:4];
            7: mem_sio_reg <= address_reg[3:0];
            default: begin
                    //If on read proccess
                    if (reading) begin								//* Reading has to happen at positive clock due to timing constraints
                        if (counter >= 15 && counter < 19) begin
                            data_out <= {data_out[11:0], mem_sio[3:0]}; // Concatenar os novos bits
                        end
                        // Reading proccess ending
                        if (counter == 20) begin
                            ended <= 1;
                            counter <= 0;
                            reading <= 0;
                        end
                    end
                    else if (writing) begin
                        // Enviar os 4 MSB atuais
                        case(counter)
                            //!xx
                            8: begin
                                mem_sio_reg <= data_write[15:12];
                                //debug <= !debug;
                            end
                            9: begin 
                                mem_sio_reg <= data_write[11:8];
                                
                            end
                            10: begin
                                mem_sio_reg <= data_write[7:4];
                                
                                if(burst_counter == TIMER || fifo_empty) begin   // If fifo has message
                                        burst_counter <= 0;  
                                end
                                else begin
                                    fifo_rd <= 1;       // Collect next data_in;
                                end
                            end
                            11: begin
                                    mem_sio_reg <= data_write[3:0];
                                if(fifo_rd) begin     
                                    counter <= 8;   //Immediately ammend next command
                                    data_write <= data_in;    //Update data_write for next write.
                                    burst_counter <= burst_counter + 1'd1;
                                end
                            end
                            12: begin   //Normal com
                                ended <= 1;
                                counter <= 0;
                                writing <= 0;
                                //debug_2 <= !debug_2;
                            end
                        endcase
                    end
                end
        endcase
    end
end
endmodule


/* ------------------------------- Top module ------------------------------- */

module psram # (
    parameter ADC_FREQ = 5        // Desired sampling frequency in MHz
)(

	//INPUT
	input mem_clk,							// 84MHz rPLL generated clock

	//Read-write in QPI mode
	input [22:0] address,								// 23-bit PSRAM address
	input [1:0] read_write,								// Define read OR write command
	input quad_start,									// Rising-edge detection to request a writing/reading
	input [15:0] data_in,								// Data to be written to PSRAM
    input burst_mode,
    input fifo_empty,
	
	//OUTPUT
	output endcommand,									// Flag - indicates when the PSRAM reading/writing process is completed		
	output mem_ce,										// PSRAM chip enable signal
	output [15:0] data_out,								// Data read from PSRAM
	output reg qpi_on,									// Indicates whether QPI mode is enabled (i.e initialization routine is DONE)
	output mem_clk_enabled,								//! clk sent to PSRAM only after delay time - startup MUST not have a clock signal
    //output debug,
    output debug_2,
    output fifo_rd,

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
wire [7:0] command;										// SPI 8 bit command

assign command = (step == STEP_RSTEN) ? CMD_RSTEN : 
(step == STEP_RST) ? CMD_RST :
(step == STEP_SPI2QPI) ? SPI2QPI : 0;

reg spi_start = 0;

reg [3:0] step = STEP_DELAY;   // Indicates the current operation
									// 0: >150us required delay
									// 1: Reset enable (RSTEN) step
									// 2: Reset (RST) step
									// 3: Idle normal operation state

// Reinitialization commands
localparam [7:0] CMD_RSTEN = 8'h66;
localparam [7:0] CMD_RST = 8'h99;
localparam [7:0] SPI2QPI = 8'h35;

memory_driver # (.ADC_FREQ(ADC_FREQ)) PSRAM_com(
	.mem_clk(mem_clk),
	.command(command),
	.step(step),
	.spi_start(spi_start),
	.qpi_on(qpi_on),
	.address(address),
	.read_write(read_write),
	.quad_start(quad_start),
	.data_in(data_in),
    .burst_mode(burst_mode),
    .endcommand(endcommand),
	.mem_ce(mem_ce),
	.mem_sio(mem_sio),
    //.debug(debug),
    .debug_2(debug_2),
    .fifo_rd(fifo_rd),
    .fifo_empty(fifo_empty),
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


    case(step)
        STEP_DELAY: begin
            //qpi_on <= 0;
            timer <= timer + 1'd1;
            if(timer[15:8] == 8'h50) begin 		// #50h = #80d. 80 * 256 (thus the 8-bit swap) = 12.800 clocks inputs. At 84Mhz, we have a t ~= 243 us.
                step <= STEP_RSTEN;
                timer <= 16'b0;					//Reset timer
            end
        end
        STEP_RSTEN: begin
            //command <= CMD_RSTEN;
            spi_start <= 1;
            if(endcommand) begin
                step <= STEP_RST;
                spi_start <= 0;
            end
        end
        STEP_RST: begin
            //command <= CMD_RST;
            spi_start <= 1;
            if(endcommand) begin
                step <= STEP_SPI2QPI;
                spi_start <= 0;
            end
        end
        STEP_SPI2QPI: begin
             //command <= SPI2QPI;
            spi_start <= 1;
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