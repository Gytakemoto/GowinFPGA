



module data_acquisition(

	//INPUT
	input clk_PSRAM,							        // 84MHz rPLL generated clock

	//Read-write in QPI mode
	input buttonA,								        // 23-bit PSRAM address
	input [23:0] samples_after,							// Number of samples to be written after the threshold
    input [23:0] samples_before,                        // Number of samples to be written before the threshold
    input [7:0] threshold,                         // Threshold type: "T" or "B"]
	input start_acquisition,							// Rising-edge detection to request a writing/reading
    input endcommand,
	
	//OUTPUT
	output reg quad_start,								// Flag - indicates when the PSRAM reading/writing process is completed		
	output reg [15:0] write_UART,										// PSRAM chip enable signal
	output reg send_uart,								// Data read from PSRAM
	output reg stop_acquisition								
);

/* ----------------------- Data acquisition interface ----------------------- */

integer i;
integer i_pivot; 			//Refers to the sample where threshold was detected
reg [22:0] address_debug;	
reg [1:0] buttons_pressed;			//Number of times the buttonA was pressed
reg [11:0] adc_data_in;				//Simulates 12-bit adc data
reg [3:0] process = 0; 			// State-machine of top.v states
reg d_com_start;
reg com_start;

reg [22:0] address;       	   // Address of message to be written/read
reg [15:0] data_in;            // Data to be written (16 bits)
reg [1:0] read_write;		   // Define read or write proccess
	//read_write
	//0	0 : Do nothing
	//0	1 : Write data from PSRAM
    //1	0 : Read data to PSRAM
    //1	1 : Do nothing

//Maximum number of 2-byte addresses (12-bit samples): 8 MB / 2 = 4 MB
//Same as 2^22 = 4MB
//PSARM has 23 bits for addressing, which means that it supports the maximum address # of 8.388.608 - 1 = 8.388.607
//The maximum iteration must be at 2^22 = 4.194.304:
//() * 2 = 8.388.606; thus in the last iteration it will write in the 8.388.606 and 8.388.607
localparam [22:0] i_max = 1 << 22;

localparam [3:0] DATA_ACQUISITION = 1;
localparam [3:0] WAIT = 0;


/* ---------------------------- Button debouncing --------------------------- */

//Button A synchronisation and debouncing
wire buttonA_debounced;


//Debouncing proccesses to avoid noise from button pressing

sync_debouncer debuttonA(
    .clk(clk_PSRAM),
    .button(buttonA),
    .button_once(buttonA_debounced)
);

initial begin
	//Acquisition variables
	i_pivot = 0;
    buttons_pressed <= 0;
	stop_acquisition <= 0;
	address_debug <= 0;
end

always @(posedge clk_PSRAM) begin 
    //todo: inserir um erro caso o processo ainda não esteja finalizado e outra aquisição seja requisitada pela ESP32
    //todo: pensei em:
    //todo: if(start_acquisition) led <= 3'b010; //Purple light if a data recquisition occurs during DATA_ACQUISITION process

    // Detect a rising edge of mcu requisition. Only valid on MCU controlling of WRITE/READs
	quad_start <= (com_start && ~d_com_start);
	d_com_start <= com_start;
	com_start <= 0;

    case(process)
        WAIT: begin
            if(start_acquisition) begin
                process <= DATA_ACQUISITION;
                //* Always begin from start
                i <= 1;						//First sample -> 0 address
                buttons_pressed <= 0;		//Reset threshold button
                i_pivot = 0;				//Reset pivot
                adc_data_in <= 0;
                stop_acquisition <= 0;
            end else process <= WAIT;
        end
        DATA_ACQUISITION: begin
            
            //*Validar button_debounced
            if(!buttonA_debounced) begin
                buttons_pressed = buttons_pressed + 1'd1;
                //When pressing for the first time, "detect threshold"
                //todo: Incluir uma condição para verificar se o tipo de requisição é por botão
                if(buttons_pressed == 1) begin
                    i_pivot = i;
                    address_debug <= i_pivot[22:0];
                end
                else if(buttons_pressed >= 3'd3) begin		//4 button-presses cancel the processing
                    process <= WAIT;
                end
            end

            if(i < i_max) begin
                //If i_pivot = 0, it means threshold wasn't reached
                if(i_pivot > 0) begin
                    if(samples_after == 0) stop_acquisition <= 1;
                    else if((i >= i_pivot && (i - i_pivot) >= samples_after) ||
                    (i < i_pivot && i_max - i_pivot + i >= samples_after)) begin
                        stop_acquisition <= 1;
                    end
                end
                //While stop wasn't requested, write in memory
                if(!stop_acquisition) begin
                        //12 bits fit in 16 bits						
                        data_in <= {4'b0000,adc_data_in};
                        //address increases by 2 each time the sample updates
                        //address starts from 0
                        //!Same as: address_mcu <= 23'd2 *(i[21:0]-23'd1);
                        address <= (i[22:0] - 23'd1) << 1;
                        //@i_max:
                        // address_mcu <= (2^22-1) * 2 = 8.388.606
                        // then, it'll write 8.388.606 and 8.388.607
                        read_write <= 1;	//write in memory
                        com_start <= 1;
                        if(endcommand) begin
                            com_start <= 0;
                            //+1 for each iteration
                            adc_data_in <= adc_data_in + 1'd1;
                            i <= i + 1;		
                        end
                end
                else begin
                    write_UART <= 16'hABCD;	//Dummy mesage to be read by ESP32
                    //led_rgb[2:0] <= {led_rgb[2:0] + 3'd1};
                    send_uart <= 1;  	// Flag to send message via UART
                    process   <= WAIT;   // After finishing the acquisition, go back to IDLEfter finishing the acquisition, go back to IDLE
                end
            end else i <= 1;			//Resetting number of samples to loop through PSRAM
        end
    endcase
end
endmodule
