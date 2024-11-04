//Basic UART module based on LUSHAY LABS

module uart
#(
    parameter DELAY_FRAMES = 730, // 27Mhz / 115200 Baud Rate
    parameter BUFFER_LENGTH = 50
)(
    input clk_PSRAM,          //Internal system clock of 27MHz
    input uart_rx,          //Rx channel - input
    input send_uart,        //Flag for transmit data        
    output reg [1:0] read_write,    //Correspond to reg [1:0] data_write
    input [15:0] send_msg,

    output reg quad_start,
    output reg [22:0] address,
    output reg [15:0] data_in,
    output reg [3:0] led,
    output uart_tx               //Tx channel - output
    //output reg com_start
    //output reg [3:0] led,       //Debug LEDs
    //output reg [2:0] led_rgb    //RGB LED -> se for reg, em TOP deve ser wire


    //inout [1:0] read_write_psram,
    //Message var, whether it's coming from PSRAM (read) or going to it (write)
    //inout [15:0] message
);

localparam HALF_DELAY_WAIT = DELAY_FRAMES / 2; //Divide by two to choose middle of bit

//------- Variables -------

integer i;

//If writing proccess is finished (denoted by write_uart), message assumes an output state of {buffer[5],buffer[4]} (data to be written)
//MIGHT NOT WORK
//assign message = !read_write ? msg_reg : 16'hz;

//Define whether is read or write operation. Must be an output when receiving. Otherwise, must be left high-Z
//assign read_write_psram = () ? : 2'bzz;

//Receiver
reg [3:0] rxState = 0;          //State machine variable
reg [12:0] rxCounter = 0;       //Counter to keeep track of clocks count
reg [5:0] rxByteCounter = 0;
reg [2:0] rxBitNumber = 0;      //How many bits were read
reg [7:0] dataIn = 0;           //Stores the command
reg byteReady = 0;              //Flag to tell wether UART protocol is finished
//reg msg_reg;
reg com_start;

//Transmitter
reg [3:0] txState = 0;          //State machine variable
reg [10:0] txCounter = 0;       //Counter to keep track of clocks count
reg [7:0] dataOut = 0;          //
reg txPinRegister = 1;          //Register linked with uart_tx; output of transmission
reg [2:0] txBitNumber = 0;      //Keep track of number of bits transmitted
reg [1:0] txByteCounter = 0;    //Keep track of number of bytes transmitted

//Register to wiring interface
assign uart_tx = txPinRegister;

//Debug
reg wrong_command;
reg [22:0] debug_address;
reg [15:0] debug_data_in;
reg debug;
reg [15:0] latch_msg;
reg send_tx;
reg [2:0] counter;

//Detect a rising edge of UART requisition. Only valid on UART controlling of WRITE/READ (Idle process)
reg d_com_start;

//Buffer to acquire received data
reg [7:0] buffer [BUFFER_LENGTH-1:0];

//------- Local params -------

//State machine states for receiver state
localparam RX_IDLE = 0;
localparam RX_START_BIT = 1;
localparam RX_READ_WAIT = 2;
localparam RX_READ = 3;
localparam RX_STOP_BIT = 5;

//State machine states for transmitter state
localparam TX_IDLE = 0;
localparam TX_START_BIT = 1;
localparam TX_WRITE = 2;
localparam TX_STOP_BIT = 3;
localparam TX_DEBOUNCE = 4;

//------- Script -------

initial begin
    for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
        buffer[i] <= 8'h00;
    end
    rxByteCounter <= 0;
    wrong_command <= 0;
    read_write <= 0;
    debug_address <= 0;
    debug <= 0;
    com_start <= 0;
    d_com_start <= 0;
    quad_start <= 0;
    send_tx <= 0;
    latch_msg <= 0;
    led <= 0;
end

always @(negedge clk_PSRAM) begin

    quad_start <= com_start && !d_com_start;
    d_com_start <= com_start;
    com_start <= 0;
    read_write = read_write;
    if(quad_start) debug <= 1;

    case(rxState)
        RX_IDLE: begin           
            byteReady <= 0;
            if(!uart_rx) begin              //Low-edge trigger detected on Rx channel - start of message
                rxState <= RX_START_BIT;
                rxCounter <= 1;             //Include current 'clock pulse' in the UART bit frame
                rxBitNumber <= 0;
                 //Idle start is LOW. Only HIGH when receive state is DONE.
                com_start <= 0;
            end
        end
        RX_START_BIT: begin                         //Just shifts the bit frame once
            if(rxCounter == HALF_DELAY_WAIT) begin  //Shift half of the bit one time and then proceed to wait 1 complete cycle
                rxState <= RX_READ_WAIT;
                rxCounter <= 1;
            end
            else rxCounter <= {rxCounter + 10'b1};
        end
        RX_READ_WAIT: begin                         //Wait for x clock pulses to read
            rxCounter <= {rxCounter + 10'b1};
            if((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_READ;
            end
        end
        RX_READ: begin
            rxCounter <= 1;
            //UART sends data from LSB to MSB
            dataIn <= {uart_rx, dataIn[7:1]};  //Move one bit towards LSB and add uart_rx: Shift register
            rxBitNumber <= {rxBitNumber + 3'b1}; 
            if(rxBitNumber == 3'b111) rxState <= RX_STOP_BIT;
            else rxState <= RX_READ_WAIT;
        end
        RX_STOP_BIT: begin
            rxCounter <= {rxCounter + 10'b1};
            if((rxCounter + 1) == DELAY_FRAMES) begin   //Re-shifting bit frame to end communcation
                rxState <= RX_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase

    //Reseting flags in the next clock they're triggered
    //might not work
    //read_write <= 1'hZ;

    if(byteReady) begin

        //led <= dataIn[3:0];
        //led_rgb <= 3'b101;
        rxByteCounter <= {rxByteCounter + 6'b1};

        buffer[rxByteCounter] = dataIn;

        if(rxByteCounter >= 0) begin
            //Read operation - dataIn = R
            if(buffer[0] == 8'h52) begin
                //Forth byte transmitted
                if(rxByteCounter >= 3) begin
                    //read_uart = 2 -> Address collected, ready for read operation. Might not work
                    read_write = 2;

                    //DESSE PONTO, Address DEVE ESTAR DEFINIDO!

                    //Address of message
                    address = {buffer[1][6:0], buffer[2], buffer[3]};

                    //com_start = LOW: receive is done! Proceed to start reading proccess with PSRAM
                    com_start <= 1;

                    //Reset counter
                    rxByteCounter <= 0;

                    debug_address <= address;

                    //Clear buffer
                    for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
                        //Maybe change to 8'h00
                        buffer[i] = 8'h00;
                    end

                end
            end

            //Writing operation - dataIn = W
            else if(buffer[0] == 8'h57) begin

                //Sixth byte were transmitted
                if(rxByteCounter >= 5) begin

                    //read_uart = 1 -> Address & message collected, ready for read operation. Might not work
                    read_write = 1;

                    //Address of message
                    address = {buffer[1][6:0], buffer[2], buffer[3]};

                    //Data_in to be written. MSB received first
                    data_in = {buffer[4], buffer[5]};
                    //msg_reg <= {buffer[5],buffer[4]};

                    //com_start = HIGH: receive is done! Proceed to start writing proccess with PSRAM
                    com_start <= 1;

                    //Reset counter
                    rxByteCounter <= 0;

                    debug_address <= address;
                    debug_data_in <= data_in;

                    //DESSE PONTO, MESSAGE & Address DEVEM ESTAR DEFINIDOS!

                    //Clear buffer
                    for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
                        buffer[i] = 8'h00;
                    end
                end
            end
            else begin
                rxByteCounter <= 0;
                wrong_command <= 1;

                //for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
                //Maybe change to 8'h00
                //    buffer[i] <= 8'hzz;
                //end

            end
        end
    end


    if(send_uart == 1) begin            //Detect transmission requisition outside of TX_IDLE
        send_tx <= 1;                   //Storage detection in spare variables
        latch_msg <= send_msg;
    end

    if(send_tx == 1 && txState == TX_IDLE) begin
        send_tx <= 0;    //After returning to TX_IDLE, stop requisition
        latch_msg <= 15'h0000;
    end


    case(txState)

    TX_IDLE: begin

        if (send_tx) begin                         //If read_write is HIGH, start transmission state through TX channel. If else, output HIGH state (nothing happens)
            {buffer[0],buffer[1]} <= send_msg;
            txState <= TX_START_BIT;
            txCounter <= 0;
            txByteCounter <= 0;
            led <= led + 1;            
        end
        else begin
            txPinRegister <= 1;
        end
    end
    TX_START_BIT: begin                             //First cycle of UART tranmission. Just throw a negative edge signal
        txPinRegister <= 0;                         //Negative-edge at TX. Microcontroller will know a message will be sent
        if ((txCounter + 1) == DELAY_FRAMES) begin  //Doesn't need to shift half baud rate, because is SENDING a message (no risk to GET noisy data)
            txState <= TX_WRITE;
            dataOut <= buffer[txByteCounter];   //Gets next byte to be transmitted based on buffer
            txBitNumber <= 0;
            txCounter <= 0;
        end else 
            txCounter <= {txCounter + 9'b1};
    end
    TX_WRITE: begin
        txPinRegister <= dataOut[txBitNumber];      //Updates tx register (TX channel) to output current bit
        if ((txCounter + 1) == DELAY_FRAMES) begin  
            if (txBitNumber == 3'b111) begin        //If 8 bits were transmitted, stop transmitting current BYTE
                txState <= TX_STOP_BIT;
            end else begin
                txState <= TX_WRITE;                //Transmits next bit
                txBitNumber <= {txBitNumber + 3'b1};
            end
            txCounter <= 0;
        end else 
            txCounter <= {txCounter + 9'b1};
    end
    TX_STOP_BIT: begin
        txPinRegister <= 1;                         //Write HIGH state to TX (end of byte transmission)
        if ((txCounter + 1) == DELAY_FRAMES) begin
            if (txByteCounter == 1) begin   //If all 2 bytes were transmitted, stop proccess 
                txState <= TX_DEBOUNCE;
                //txState <= TX_IDLE;         //Debounce not needed: signal flag
            end else begin
                txByteCounter <= {txByteCounter + 2'b1};         //If else, move to next byte
                txState <= TX_START_BIT;
            end
            txCounter <= 0;
        end else 
            txCounter <= {txCounter + 9'b1};
    end
    TX_DEBOUNCE: begin                              //Guarantees that by pressing button once, it will occurs ONCE
        if (txCounter == 5'b11111) begin
            if (send_uart == 0) 
                txState <= TX_IDLE;
        end else
            txCounter <= {txCounter + 9'b1};
    end
    endcase
end
endmodule

