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
localparam PSRAM_DATA_WIDTH = 16;
//This parameter has to be in accordance with rpll clock
localparam PSRAM_CLK_FREQ = 60; //MHz

//UART
localparam UART_BUFF_LENGTH = 11;

//Ping-pong Buffer
localparam PP_BUFF_DEPTH = 128;
localparam PP_DATA_WIDTH = 16;

//FIFO
localparam FIFO_BUFF_DEPTH = 128;
localparam FIFO_DATA_WIDTH = 12;

//Start-up check parameters
localparam [15:0] INITIAL_MSG = 16'h5678;
localparam [23:0] INITIAL_ADDRESS = 24'h00000;

//Used for DEBUG purposes-only
//localparam [21:0] SAMPLES_AFTER = 4_000_000;
//localparam [21:0] SAMPLES_BEFORE = 0;

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
        reg [PSRAM_DATA_WIDTH-1:0] data_in_1;     // Data to be written at PSRAM1
        reg [PSRAM_DATA_WIDTH-1:0] data_in_2;     // Data to be written at PSRAM2
        reg [PSRAM_DATA_WIDTH-1:0] data_in_3;     // Data to be written at PSRAM3
        
        wire [PSRAM_DATA_WIDTH-1:0] data_out_1;   // Data read from PSRAM1
        wire [PSRAM_DATA_WIDTH-1:0] data_out_2;   // Data read from PSRAM2
        wire [PSRAM_DATA_WIDTH-1:0] data_out_3;   // Data read from PSRAM3

        wire [FIFO_DATA_WIDTH-1:0] data_out;
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
    wire [23:0] samples_after;                  // Number of samples to be written after the trigger
    wire [23:0] samples_before;                 // Number of samples to be written before the trigger
    wire [21:0] samples_after_rd;              // Shrunk samples_after
    wire [21:0] samples_before_rd;             // Shrunk samples_before
    wire [3:0] samples_after_rmd;               // Samples_after remainder
    wire [3:0] samples_before_rmd;               // Samples_after remainder

// Inputs (Consult UART.v)
    reg send_uart;				                // Flag - inform UART to send data through Tx
    reg [15:0] read;              	            // Message to be sent through UART

/* -------------------------- Internal variables -------------------------- */

reg error;                                      // Error flag
reg [3:0] process; 					            // State-machine of top.v states

// Request read or write through MCU
    reg com_start;							    // Detect rising edge to start quad_start
    reg d_com_start;						    // (same)

// Directly control write and read process, through MCU (Gowin)
    reg quad_start_mcu;								// Quad_start at initial check

/* ----------------------- Data acquisition interface ----------------------- */

//Iteration control
    reg [21:0] i;                               // Acquisition iteration index
    reg [21:0] i_pivot; 						// Refers to the sample where trigger was detected
    reg i_pivot_valid;	                        // Flag to determine if pivot was triggered

    wire flag_acq;                              // Detect rising edge to start data acquisition
    reg d_flag_acq;
    reg start_acquisition;
    reg [1:0] buttons_pressed;				    // Number of times the buttonA was pressed
    reg stop_acquisition;                       // Stop acquisition due to samples_after being reached
			
    reg [22:0] address_acq;                     // Address of next message

    wire [21:0] i_minus_i_pivot = i - i_pivot;
    wire [21:0] i_max_minus_i_pivot_plus_i = IMAX - i_pivot + i;
    reg [21:0] i_minus_i_pivot_reg;
    reg [21:0] samples_after_adjusted;
    reg condition1_reg, condition2_reg, condition3_reg;
    assign samples_after_rd = samples_after >> 2;
    assign samples_before_rd = samples_before >> 2;
    assign samples_after_rmd = samples_after % 4;   //Remainder of division to treat samples_after
    assign samples_before_rmd = samples_before % 4;

/* ------------------------------ Post Process ------------------------------ */
reg rst_PP;
reg en_write_PP;
reg en_read_PP;
wire buffer_full_PP;
wire buffer_empty_PP;
wire UART_finished;
reg read_clk_PP;
wire [15:0] read_PP;
reg [22:0] address_PP;        //Post-process address. Considers i_pivot - samples_before
reg write_clk_PP;
reg first_pong;
reg d_first_pong;
reg uart_start;
reg [22:0] address_finish;
reg bypass;
wire [12:0] threshold;
reg [11:0] d_fifo_out;
reg [11:0] d_fifo_out_1;

//wire adc_enable;
assign adc_enable = (process == DATA_ACQUISITION) && !stop_acquisition ? 1:0;

wire [11:0] adc_data;
wire [11:0] fifo_out;
wire fifo_empty;
reg fifo_rst;
//wire fifo_wr;
//wire fifo_full;

/* ------------------------------- Submodules ------------------------------- */
/* --------------------- 84Mhz generated by Gowin's PLL --------------------- */
gowin_rpll clk2(
	.clkout(clk_PSRAM), 	// 60MHz
	.clkin(sys_clk), 		// 27MHz
    .clkoutd(clk_ADC)       // User defined (needs to generate rPLL file with desired frequency)
);

/* ---------------------------------- PSRAM --------------------------------- */
//*Obs: Change parameters value above
psram # (
            .DATA_WIDTH(PSRAM_DATA_WIDTH)
        )initialize(

        //CLOCK
            .clk_PSRAM(clk_PSRAM),

        //Read-write in QPI mode
            .address(address),
            .read_write(read_write),
            .quad_start(quad_start_mcu),
            .qpi_on(qpi_on),

        //Control writing
            .burst_mode(burst_mode),
            .fifo_empty(fifo_empty),
            .stop_acquisition(stop_acquisition),
            .fifo_rd(fifo_rd),
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

/* ---------------------------- Ping Pong Buffer ---------------------------- */
//*Obs: Change parameters value above
ping_pong_buffer #(
        .DATA_WIDTH(PP_DATA_WIDTH),
        .BUFFER_DEPTH(PP_BUFF_DEPTH)
    ) PP_post_process (
	//input
    .clk(clk_PSRAM),
	.flag_write(write_clk_PP),               	// Clock para o domínio de escrita
	.flag_read(read_clk_PP),                			// Clock para o domínio de leitura
  	.reset(rst_PP),     		            // Sinal de reset
  	.en_rd(en_read_PP),		            		// Sinal para habilitar escrita
    .en_wr(en_write_PP),
  	.write_data(data_out), 					// Dados de entrada para escrita
	.first_pong(first_pong),

	//output
  	.read_data(read_PP),  						// Dados de saída para leitura
  	.buffer_full(buffer_full_PP),            // Indica que o buffer ativo de escrita está cheio
  	.buffer_empty(buffer_empty_PP),  			// Indicates the reading buffer is empty
    .read_cmp(read_cmp),
    .stop_PP(stop_PP)
);


/* ------------------------------- ADC Module ------------------------------- */
//*Obs: Change parameters value above
adc_module ADC_submodule(
    //input
    .clk_PSRAM(clk_PSRAM),
    .clk_ADC(clk_ADC),
    .adc_out(adc_out),
    .adc_OTR(adc_OTR),
    .adc_enable(adc_enable),
    .adc_data(adc_data),
    .adc_ready(fifo_wr)
);

/* ------------------------------- FIFO buffer ------------------------------ */
fifo_adc #(
        .DATA_WIDTH(FIFO_DATA_WIDTH),   // Set data width (can be 12 or 16 bits)
        .FIFO_DEPTH(FIFO_BUFF_DEPTH)    // Set FIFO depth (adjust as needed)
    ) fifo_inst (
        .clk(clk_PSRAM),
        .wr_en(fifo_wr),
        .reset(fifo_rst),
        .adc_data_in(adc_data),
        .rd_en(fifo_rd),
        .data_out(fifo_out),
        .full(fifo_full),
        .debug(debug),
        .empty(fifo_empty)
    );

/* ---------------------------- Local parameters ---------------------------- */
//Testbench read & write
localparam [3:0] WRITE_MCU_INIT = 0;
localparam [3:0] READ_MCU_INIT = 1;
localparam [3:0] CHECK_STARTUP = 2;
localparam [3:0] IDLE = 3;
localparam [3:0] DATA_ACQUISITION = 4;
localparam [3:0] READ_CHECK = 5;
localparam [3:0] SEND_UART = 6;

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
	process <= WRITE_MCU_INIT;
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
            //data_in_1 <= {fifo_out_1[11:8],fifo_out_2[11:8],fifo_out_3[11:8],fifo_out_4[11:8]};
            //data_in_2 <= {fifo_out_1[7:4],fifo_out_2[7:4],fifo_out_3[7:4],fifo_out_4[7:4]};
            //data_in_3 <= {fifo_out_1[3:0],fifo_out_2[3:0],fifo_out_3[3:0],fifo_out_4[3:0]};
        end
        SEND_UART: begin
            read_write <= 2;
            address <= address_PP;
            data_in_1 <= 8'hzz;
        end
        WRITE_MCU_INIT: begin
            read_write <= 1;
            address <= INITIAL_ADDRESS;
            data_in_3 <= INITIAL_MSG;
        end
        READ_MCU_INIT: begin
            read_write <= 2;
            address <= INITIAL_ADDRESS;
        end
    endcase

	//* Only when QPI is ready
	if (qpi_on) begin
		case (process)
		//todo: inserir uma verificação de aquisição fora do IDLE
		//todo: semelhante ao todo lá embaixo, talvez expandido para qualquer fluxo na implementação final
		    // Writing operation to test PSRAM before starting
			WRITE_MCU_INIT: begin
				com_start <= 1;
				if(next_step) begin
					com_start <= 0;
					process <= READ_MCU_INIT;
				end
			end
			READ_MCU_INIT: begin
				com_start <= 1;
				if(next_step) begin
					read <= data_out_3;
					com_start <= 0;
					process <= CHECK_STARTUP;
				end
			end
			CHECK_STARTUP: begin
				//* If writing and reading processess were OK
				if(read == INITIAL_MSG) begin
					led_rgb <= 3'b101;
					error <= 0;
					process <= IDLE;
				end
				// If not...
				else begin
                    led_rgb[2:0] <= 3'b011;
					error <= 1;
				end
			end
			IDLE: begin

				//Green LED to inform end of data acquisition
				led_rgb[2:0] <= 3'b101;
                //start_acquisition <= 1;

					//* Always begin from start
					i <= 0;						//First sample -> 0 address
                    address_acq <= 0;
					buttons_pressed <= 0;		//Reset trigger button
					i_pivot <= 0;				//Reset pivot
					//adc_data_in <= 0;
                    i_pivot_valid <= 0;
					stop_acquisition <= 0;
                    condition1_reg <= 0;
                    condition2_reg <= 0;
                    condition3_reg <= 0;
                    i_minus_i_pivot_reg <= 0;
                    samples_after_adjusted <= 0;
                    bypass <= 1;
                    if(fifo_rst) fifo_rst <= 0;
				
				//Start acquisition rising edge detected
				if(start_acquisition) begin
					process <= DATA_ACQUISITION;
                    led_rgb <= 3'b000;
                    burst_mode <= 1;
                    d_fifo_out <= 0;
                    d_fifo_out_1 <= 0;
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
                if(!i_pivot_valid) begin
                        d_fifo_out <= fifo_out;
                        d_fifo_out_1 <= d_fifo_out;
                    //It is fifo_out <= threshold because ADC inputs are inverted: +5V is #000 and -5V is #FFF
                    //d_fifo_out to get the transition state!
                    if((trigger == 8'h42 && buttons_pressed == 1) 
                    || (trigger == 8'h54 && ({1'b0,fifo_out} <= threshold) && ({1'b0,d_fifo_out} > threshold) && ({1'b0,d_fifo_out_1} > threshold))) begin
                        i_pivot <= i;
                        i_pivot_valid <= 1;
                        address_PP <= (i - samples_before_rd) << 1;
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
                        samples_after_adjusted <= (samples_after_rd - (IMAX - i_pivot)) - 1'd1;
                        //samples_after_adjusted <= (SAMPLES_AFTER - (IMAX - i_pivot)) - 1'd1;

                        //First stage: compute conditions
                        condition1_reg <= samples_after_rd == 21'd0 ? 1 : 0;                                   //In case samples_after = 0
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

                        if(next_write) begin
                            i <= {i + 22'd1};
                            address_acq <= {address_acq + 23'd2};
                        end

                        if(!com_start && !fifo_empty) begin
                            com_start <= 1;					
                        end
                        if(com_start && endcommand) begin 
                            com_start <= 0;
                            

                            //+1 for each iteration
                            //if(i_pivot_valid) adc_data_in <= adc_data_in + 1'd1;
                            //else adc_data_in <= 0;

                            //adc_data_in <= adc_data_in + 1'd1;
                            //Acho que eu não preciso mudar esse cara...
                            //address starts from 0 and increases by 2 each time the sample updates
                            //

                            //@i_max:
                            // address_mcu <= (2^22-1) * 2 = 8.388.606
                            // then, it'll write 8.388.606 and 8.388.607

							//* Last address_acq is the samples_after-ish
                        end
					end
					else if (com_start && next_step) begin
						com_start <= 0;                        
						
						//Blue LED to inform end of data acquisition
						led_rgb[2:0] <= 3'b110;

						//Dummy mesage to be read by ESP32
						//send_uart <= 1;  	// Flag to send message via UART
                        //read <= 16'hABCD;
                        
                        //Reset post process to start conditions
                        //address_finish <= address_acq + 2'd2;
                        en_write_PP <= 1;
                        en_read_PP <= 0;
                        rst_PP <= 1;
                        first_pong <= 0;
						process <= SEND_UART;   // After finishing the acquisition, go back to IDLEfter finishing the acquisition, go back to IDLE
					end
				end
			end
            SEND_UART: begin
                rst_PP <= 0;
                write_clk_PP <= 0;
                read_clk_PP <= 0;
                read <= read_PP;
                d_first_pong <= first_pong;
                send_uart <= 0;
                burst_mode <= 0;
                
                //Wait for ping-pong buffer reset
                if(!rst_PP) begin
                    if(!stop_PP) begin

                        //Read from PSRAM, write on ping-pong buffer
                        if(en_write_PP) begin
                            if(!(buffer_full_PP || com_start || write_clk_PP)) begin
                                //Start reading
                                com_start <= 1;
                            end

                            //Delay . . .

                            //Reading has ended
                            if(next_step && com_start) begin
                                //First bypass is needed to avoid failing when samples_after + samples_before = IMAX
                                if(!bypass) begin
                                    //When address_PP reaches address_acq + 2'd2 it means the last required message was just sent
                                    if (address_PP == address_acq + 2'd2) begin
                                    //if (address_PP == (i << 1) + 2'd2) begin
                                        en_write_PP <= 0;
                                    end
                                end
                                else bypass <= 0;
                                //Updating address for next message
                                address_PP <= {address_PP + 23'd2};
                                com_start <= 0;
                                //Save read data in ping pong buffer
                                write_clk_PP <= 1;
                            end
                        end

                        //!Se send_uart nunca for 1, não tem como UART_finished = 1
                        //! O que acontece se uart começar a ler antes do primeiro switch? Vai estar lendo coisas que nem foram escritas; Tem que esperar o primeiro switch
                        //E se samples_after + samples_before for tão pequeno que não dá o switch ? daí temos que forçar um switch;

                        //Starting reading
                        if(first_pong && !d_first_pong) begin
                            read_clk_PP <= 1;
                        end

                        //Condition 1: Awaits for writing completion to begin UART transfer
                        //Condition 2: Writing was disabled before first pong, which means the buffer needs to be swiched and read needs to start
                        if((buffer_full_PP && !en_read_PP) || (!first_pong && !en_write_PP && !en_read_PP)) begin
                            en_read_PP <= 1;
                            first_pong <= 1;
                        end

                        
                        //Read from PP buffer and send to UART
                        if(UART_finished && uart_start && !buffer_empty_PP && en_read_PP) begin
                            //j <= j + 1'd1;
                            //if(j == SAMPLES_AFTER + SAMPLES_BEFORE) en_read_PP <= 0;
                            read_clk_PP <= 1;
                            uart_start <= 0;
                        end
                        
                        
                        //1-clock delay to read from ping pong buffer
                        if(read_cmp) begin
                            send_uart <= 1;
                        end

                        //Message sent, uart can start again
                        if(send_uart) uart_start <= 1;
                    end
                    else begin
                        process <= IDLE;
                        led_rgb <= 3'b100;
                        fifo_rst <= 1;
                    end
                end
			end
		endcase
	end
end
endmodule

