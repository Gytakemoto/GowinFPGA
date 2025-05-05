/* ------------------------------- TOP MODULE ------------------------------- */
module TOP (

//Tang Nano 1k
input sys_clk,                	// Internal 27 MHz oscillator

//UART
input uart_rx,                 	// RX UART wire [pin 18]

//Data acquisition
input buttonA, 					//Button that requests data acquisition		

//ADC signals
output clk_ADC,
input [11:0] adc_out,
input adc_OTR,

//PSRAM mem chip
inout [3:0] mem_sio_1,     		// Communication busbar for PSRAM communication - [sio[0] pin 40, sio[1] pin 39, sio[2] pin 38, sio[3] pin 41]
inout [3:0] mem_sio_2,
inout [3:0] mem_sio_3,
output mem_ce,                	// PSRAM chip enable - [pin 42]
output mem_clk_enabled,         // PSRAM clock pin - [pin 6]
output uart_tx,                	// TX UART wire [pin 17]

//DEBUGGING
//output fifo_rd,
//output adc_enable,
//output fifo_full,
//output debug_2,
//output fifo_wr,
//output debug,
//Debug RGB LED
output reg [2:0] led_rgb     	// RGB LEDs
);

//! --------------------------- USER CONFIGURATION --------------------------- */
//Change the following parameters according to your preferences.
//*Obs: Always check for timing closure upon Place & Route > Timing Analisys Report.

//PSRAM
//This parameter has to be in accordance with rpll clock
localparam PSRAM_CLK_FREQ = 24; //MHz

//UART
localparam UART_BUFF_LENGTH = 11;

//ACQUISITION BRAM
localparam ACQ_DEPTH = 16;

//Used for DEBUG purposes-only
localparam [21:0] SAMPLES_AFTER = 0;
localparam [21:0] SAMPLES_BEFORE = 0;

/* -------------------------------- Variables ------------------------------- */

// Master clock
    wire clk_PSRAM;				   				// 84MHz rPLL generated clock. Used in PSRAM interface

/* ----------------------------- PSRAM interface ---------------------------- */

// Outputs (consult PSRAM.v)
    wire qpi_on;				   			    // Input flag - indicates whether QPI communication is on

// Inputs (consult PSRAM.v)
    reg burst_mode;                             // Tell to PSRAM wheter burst mode is allowed (it is on writing)
    reg next_step;  							// Register that stores endcommand. Pipeline process to meet timing closure

    //Read-write
        reg [22:0] address;                     // Address of message to be written/read
        reg [63:0] data_in;
        wire [15:0] data_in_1;     // Data to be written at PSRAM1
        wire [15:0] data_in_2;     // Data to be written at PSRAM2
        wire [15:0] data_in_3;     // Data to be written at PSRAM3
        
        wire [15:0] data_out_1;   // Data read from PSRAM1
        wire [15:0] data_out_2;   // Data read from PSRAM2
        wire [15:0] data_out_3;   // Data read from PSRAM3
        reg [1:0] read_write;		   			// Define read or write proccess
            //read_write
            //0	0 : Do nothing
            //0	1 : Write data from PSRAM
            //1	0 : Read data to PSRAM
            //1	1 : Do nothing

/* ----------------------------- UART interface ----------------------------- */

// Outputs (Consult UART.v)
    wire start_acq;							    // Flag to start acquisition
    wire [7:0] trigger;                         // Trigger type: "T" or "B"]
    wire [21:0] samples_after;                  // Number of samples to be written after the trigger
    wire [21:0] samples_before;                 // Number of samples to be written before the trigger

// Inputs (Consult UART.v)
    reg send_uart;				                // Flag - inform UART to send data through Tx
    reg [15:0] read;              	            // Message to be sent through UART

/* -------------------------- Internal variables -------------------------- */

reg error;                                      // Error flag
reg [2:0] process; 					            // State-machine of top.v states

// Request read or write through MCU
    reg com_start;							    // Detect rising edge to start quad_start
    reg d_com_start;						    // (same)

// Directly control write and read process, through MCU (Gowin)
    reg quad_start_mcu;								// Quad_start at initial check

/* ----------------------- Data acquisition interface ----------------------- */

//Iteration control
    reg begin_acq;                              // BRAM start-up
    reg [21:0] i;                               // Acquisition iteration index
    reg [21:0] i_pivot; 						// Refers to the sample where trigger was detected
    reg i_pivot_valid;	                        // Flag to determine if pivot was triggered

    wire flag_acq;                              // Detect rising edge to start data acquisition
    reg d_flag_acq;
    reg start_acquisition;
    
//Trigger
    reg [1:0] buttons_pressed;				    // Number of times the buttonA was pressed
    wire [12:0] threshold;
    reg [11:0] d_fifo_out;
    reg [11:0] d_fifo_out_1;


    reg stop_acquisition;                       // Stop acquisition due to samples_after being reached
			
    reg [22:0] address_acq;                     // Address of next message

//Stop condition
    wire [21:0] i_minus_i_pivot = i - i_pivot;
    wire [21:0] i_max_minus_i_pivot_plus_i = IMAX - i_pivot + i;
    reg [21:0] i_minus_i_pivot_reg;
    reg [21:0] samples_after_adjusted;
    reg condition1_reg, condition2_reg, condition3_reg;

//BRAM
    wire BRAM_empty;
    wire acq_rd;
    wire acq_wr;
    wire endcommand;
    wire next_write;
    wire flag_debug;

/* ------------------------------ Post Process ------------------------------ */
    //PSRAM interface
    reg [22:0] address_PP;        //Post-process address. Considers i_pivot - samples_before
    reg bypass;
    wire UART_finished;
    reg wait_uart;
    reg delay;

    //UART BRAM variables
    reg begin_PP;
    reg end_PP;
    wire [15:0] data_uart;
    reg BRAM_wr;
    reg BRAM_rd;
    wire bram_full;
    wire bram_empty;
    wire write_read;
    wire ended;
    


//ADC FIFO variables
    wire [11:0] adc_data;
    wire adc_enable;
        assign adc_enable = (process == DATA_ACQUISITION) && !stop_acquisition ? 1:0;

/* ------------------------------- Submodules ------------------------------- */
/* --------------------- 84Mhz generated by Gowin's PLL --------------------- */
gowin_rpll5 clk2(
	.clkout(clk_PSRAM), 	// 60MHz
	.clkin(sys_clk), 		// 27MHz
    .clkoutd(clk_ADC)       // User defined (needs to generate rPLL file with desired frequency)
);

/* ---------------------------------- PSRAM --------------------------------- */
//*Obs: Change parameters value above
psram initialize(

        //CLOCK
            .clk_PSRAM(clk_PSRAM),

        //Read-write in QPI mode
            .address(address),
            .read_write(read_write),
            .quad_start(quad_start_mcu),
            .qpi_on(qpi_on),

        //Control writing
            .burst_mode(burst_mode),
            .BRAM_empty(BRAM_empty),
            .stop_acquisition(stop_acquisition),
            .acq_rd(acq_rd),
            .endcommand(endcommand),
            .next_write(next_write),

        //PSRAM
            .mem_ce(mem_ce),
            .mem_clk_enabled(mem_clk_enabled),

            //PSRAM1
            .mem_sio_1(mem_sio_1),
            .data_in_1(data_in_1),
            .data_out_1(data_out_1),

            //PSRAM2
            .mem_sio_2(mem_sio_2),
            .data_in_2(data_in_2),
            .data_out_2(data_out_2),

            //PSRAM3
            .mem_sio_3(mem_sio_3),
            .data_in_3(data_in_3),
            .data_out_3(data_out_3)
);

/* ----------------------- UART1 channel communication ---------------------- */
//*Obs: Change parameters value above
uart #(
        .CLK(PSRAM_CLK_FREQ), 
        .BUFFER_LENGTH(UART_BUFF_LENGTH)
    ) UART1 (
	//input
        .clk_PSRAM(clk_PSRAM),
        .uart_rx(uart_rx),
        .send_msg(read),
        .send_uart(send_uart),
	
	//output
        .trigger(trigger),
        .threshold(threshold),
        .samples_after(samples_after),        // Number of samples to be written after the trigger
        .samples_before(samples_before),       // Number of samples to be written before the trigger
        .flag_acq(flag_acq),
        .flag_debug(flag_debug),
        .flag_end_tx(UART_finished),
        .uart_tx(uart_tx)
);

/* ---------------------------- Post-process BRAM ---------------------------- */

Post_Process BRAM_pp (
        .clk(clk_PSRAM),
        .end_PP(end_PP),
        .begin_PP(begin_PP),
        .data_in(data_in),
        .data_out(data_uart),
        .write(BRAM_wr),
        .read(BRAM_rd),
        .bram_full(bram_full),
        .bram_empty(bram_empty),
        .step(write_read),
        .ended(ended)
    );

/* ------------------------------- ADC Module ------------------------------- */
adc_module ADC_submodule(
    //input
    .clk_PSRAM(clk_PSRAM),
    .clk_ADC(clk_ADC),
    .adc_out(adc_out),
    .adc_OTR(adc_OTR),
    .adc_enable(adc_enable),
    .adc_data(adc_data),
    .adc_ready(acq_wr)
);

/* ------------------------------- FIFO buffer ------------------------------ */
acquisition #(
        .ACQ_DEPTH(ACQ_DEPTH)    // Set FIFO depth (adjust as needed)
    ) BRAM_acq (
        .clk(clk_PSRAM),
        .begin_acq(begin_acq),
        .data_out_1(data_in_1),
        .data_out_2(data_in_2),
        .data_out_3(data_in_3),
        //.data_in(12'hABC),
        .data_in(adc_data),
        .wr_clk(acq_wr),
        .rd_clk(acq_rd),
        .BRAM_empty(BRAM_empty)
    );

/* ---------------------------- Local parameters ---------------------------- */
//Testbench read & write
localparam [2:0] IDLE = 0;
localparam [2:0] DATA_ACQUISITION = 1;
localparam [2:0] READ_CHECK = 2;
localparam [2:0] SEND_UART = 3;

//Each time, 12-bit ADC data will be stored in 3 PSRAM, which means 4-bit of each sample will be stored in each PSRAM.
//Those PSRAM are 8-bit addressable, and have 8MB addresses.
//!Up to 16MB samples can be stored (samples_after + samples_before <= 16MB)
//Previous ver. used to deal with 16-bit messages, resulting in 2^22 = 4.194.304 possible addresses.
    //In order to minimize changes, this structure was maintained.
//Thus, the iteration limit must be: 2^22 - 1 = 4.194.303.
// When i = 4.194.303, address will be 8.388.606 and 8.388.606 and 8.388.607 addresses will be written.
localparam [21:0] IMAX = (1 << 22) - 1;

/* ---------------------------- Button debouncing --------------------------- */

//Button A synchronisation and debouncing
wire buttonA_debounced;

//Debouncing proccesses to avoid noise from button pressing
sync_debouncer debuttonA(
    .clk(clk_PSRAM),
    .button(buttonA),
    .button_once(buttonA_debounced)
);

/* --------------------------- Procedural routine --------------------------- */

initial begin
	process <= IDLE;
	error <= 0;
	read <= 0;
	send_uart <= 0;
	com_start <= 0;
	d_com_start <= 0;

	//MCU read-write variables
	quad_start_mcu <= 0;
    led_rgb <= 3'b111;

	//Acquisition variables
	i_pivot = 0;
    start_acquisition <= 0;
    buttons_pressed <= 0;
	stop_acquisition <= 0;
    address_acq <= 0;
    i_pivot_valid <= 0;
    i_minus_i_pivot_reg <= 0;
    samples_after_adjusted <= 0;
    next_step <= 0;
    bypass <= 0;
    burst_mode <= 0;
    begin_PP <= 0;
    begin_acq <= 0;
end

always @(posedge clk_PSRAM) begin

	// Detect a rising edge of mcu requisition. Only valid on MCU controlling of WRITE/READs
	quad_start_mcu <= (com_start && ~d_com_start);
	d_com_start <= com_start;
	//com_start <= 0;

	// Detect a rising edge of UART requisition
	start_acquisition <= (flag_acq && ~d_flag_acq);
	d_flag_acq <= flag_acq;

    next_step <= endcommand;

    case (process)
        DATA_ACQUISITION: begin
            read_write <= 1;
            address <= address_acq;
        end
        SEND_UART: begin
            read_write <= 2;
            address <= address_PP;
        end
    endcase

	//* Only when QPI is ready
	if (qpi_on) begin
		case (process)

            IDLE: begin
				//Green LED to inform end of data acquisition
				led_rgb[2:0] <= 3'b101;
                //start_acquisition <= 1;

					//* Always begin from start
					i <= 0;						//First sample -> 0 address
                    address_acq <= 0;
					buttons_pressed <= 0;		//Reset trigger button
					i_pivot <= 0;				//Reset pivot
                    i_pivot_valid <= 0;
					stop_acquisition <= 0;
                    condition1_reg <= 0;
                    condition2_reg <= 0;
                    condition3_reg <= 0;
                    i_minus_i_pivot_reg <= 0;
                    samples_after_adjusted <= 0;
                    bypass <= 1;
				
				//Start acquisition rising edge detected
				if(start_acquisition) begin
					process <= DATA_ACQUISITION;
                    led_rgb <= 3'b000;
                    burst_mode <= 1;
                    begin_acq <= 1;
                    //d_fifo_out <= 0;
                    //d_fifo_out_1 <= 0;
				end else process <= IDLE;

			end

/* ---------------------------- Acquisition step ---------------------------- */

			DATA_ACQUISITION: begin    

            //apagar
            //i_pivot_valid <= 1;

            /* ------------------------- Detect external trigger ------------------------ */
				//if(buttonA_debounced || flag_debug) begin
                if(buttonA_debounced) begin
					buttons_pressed <= buttons_pressed + 1'd1;
                    //When pressing for the first time, "detect trigger"
                    //todo: Incluir uma condição para verificar se o tipo de requisição é por botão
                end
                //if(buttons_pressed == 1'd1 && !i_pivot_valid && !com_start) begin
                if(!i_pivot_valid && !com_start) begin
                        //d_fifo_out <= fifo_out;
                        //d_fifo_out_1 <= d_fifo_out;
                    //It is fifo_out <= threshold because ADC inputs are inverted: +5V is #000 and -5V is #FFF
                    //d_fifo_out to get the transition state!
                    //if((trigger == 8'h42 && buttons_pressed == 1) 
                    //|| (trigger == 8'h54 && ({1'b0,fifo_out} <= threshold) && ({1'b0,d_fifo_out} > threshold) && ({1'b0,d_fifo_out_1} > threshold))) begin
                    if(trigger == 8'h42 && buttons_pressed == 1)  begin
                        i_pivot <= i;
                        i_pivot_valid <= 1;
                        address_PP <= (i - samples_before) << 1;
                        //address_PP <= (i - SAMPLES_BEFORE) << 1;
                    end
				end

            /* ------------------------ Evaluate stop conditions ------------------------ */
				if(i <= IMAX) begin
					
					//If i_pivot_valid = 0, it means trigger wasn't reached
                    if (i_pivot_valid) begin

                        // Precompute intermediate values
                        i_minus_i_pivot_reg <= i - i_pivot;

                        //! -1 because of zero (i = 0)
                        samples_after_adjusted <= (samples_after - (IMAX - i_pivot)) - 1'd1;
                        //samples_after_adjusted <= (SAMPLES_AFTER - (IMAX - i_pivot)) - 1'd1;

                        //First stage: compute conditions
                        condition1_reg <= samples_after == 21'd0 ? 1 : 0;                                   //In case samples_after = 0
                        //condition1_reg <= SAMPLES_AFTER == 21'd0 ? 1 : 0;
                        condition2_reg <= (i >= i_pivot) && (i_minus_i_pivot_reg >= (samples_after));       //In case i_pivot + samples_after is smaller than i_max
                        //condition2_reg <= (i >= i_pivot) && (i_minus_i_pivot_reg >= (SAMPLES_AFTER));
                        condition3_reg <= (i >= samples_after_adjusted) && (i < i_pivot);                   //In case i_pivot + samples_before is greater than i_max

                        // Second stage: compute final result
                        stop_acquisition <= (condition1_reg || condition2_reg || condition3_reg);
                    end

                /* ------------------------ Parallel PSRAM save data ------------------------ */
					//While stop wasn't requested, write in memory
					if(!stop_acquisition) begin

                        //Transmission is done, updates iteration
                        if(next_write) begin
                            i <= {i + 22'd1};
                            address_acq <= {address_acq + 23'd2};
                        end
                        if(!com_start && !BRAM_empty) begin
                            com_start <= 1;					
                        end
                        if(com_start && endcommand) begin 
                            com_start <= 0;
                        end
					end
					else if (com_start && next_step) begin
						com_start <= 0;                        
						
						//Blue LED to inform end of data acquisition
						led_rgb[2:0] <= 3'b110;
                        end_PP <= 0;
                        begin_PP <= 1;
                        wait_uart <= 0;
                        begin_acq <= 0; 
						process <= SEND_UART;   // After finishing the acquisition, go back to IDLEfter finishing the acquisition, go back to IDLE
					end
				end
			end
            SEND_UART: begin

                //Reset previous configuration
                burst_mode <= 0;

                //Idle state of UART FIFO variables to avoid trash data
                send_uart <= 0;
                BRAM_wr <= 0;
                BRAM_rd <= 0;
                delay <= 0;

                //two-clock delay
                if(BRAM_wr) delay <= 1;
                if(delay) com_start <= 0;

                //Read from PSRAM and write on BRAM
                if(!bram_full && !com_start && !end_PP && !write_read) begin         //If communication ended and write enable...
                    com_start <= 1;
                end

                //PSRAM read ended
                if(com_start && next_step) begin 

                    
                    //64-bit message
                    data_in <= {4'hF, data_out_1[15:12], data_out_2[15:12], data_out_3[15:12],
                                4'hF, data_out_1[11:8], data_out_2[11:8], data_out_3[11:8],
                                4'hF, data_out_1[7:4], data_out_2[7:4], data_out_3[7:4],
                                4'hF, data_out_1[3:0], data_out_2[3:0], data_out_3[3:0]};
                    
                    
                    /*
                    data_in <= {4'hF, 4'h1, 4'h2, 4'h3,
                                4'hF, 4'h4, 4'h5, 4'h6,
                                4'hF, 4'h7, 4'h8, 4'h9,
                                4'hF, 4'hA, 4'hB, 4'hC};
                    */

                    //Write data to BRAM
                    BRAM_wr <= 1;

                    //First bypass is needed to avoid failing when samples_after + samples_before = IMAX
                    if(!bypass) begin
                        //When address_PP reaches address_acq + 2'd2 it means the last required message was just sent
                        if (address_PP == address_acq + 2'd2) begin
                            end_PP <= 1;                //End Post process
                        end
                    end
                    else bypass <= 0;

                    //Get ready for next iteration
                    address_PP <= {address_PP + 23'd2};
                end

                //Send to UART
                if(!bram_empty && write_read) begin      // If communication ended and read enable...
                    if(!wait_uart) BRAM_rd <= 1;
                    if(BRAM_rd) delay <= 1;
                end

                    //One clock delay to wait BRAM proceeding
                    if (delay) begin
                        read <= data_uart;
                        send_uart <= 1;
                        //read <= {4'hF,data_uart[11:0]};
                    end

                    if(send_uart) wait_uart <= 1;

                if(UART_finished && wait_uart) begin
                    if (ended) begin
                        process <= IDLE;
                        begin_PP <= 0;
                        led_rgb <= 3'b100;
                    end
                    else wait_uart <= 0;
                end
            end
		endcase
	end
end
endmodule

