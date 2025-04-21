/* --------------------------------- ReadMe --------------------------------- */

/*
*Basic UART module based on LUSHAY LABS. 

Adapted in order to operate using an user defined message package. 
*This package consists of 4 and 6 bytes for reading and writing, respectively.

READ REQUISITION PACKAGE
    Byte0: R in ASCII (00x52)
    Byte1, Byte2, Byte3: 23-bit PSRAM Address to be read

WRITE REQUISITION PACKAGE
    Byte0: W in ASCII (00x57)
    Byte1, Byte2, Byte3: 23-bit PSRAM Address to be written
    Byte4 and Byte5: 16-bit data to be written at the selected address

Upon a requisition, the UART module will generate a rising edge on the com_start 
signal, starting a process to read or write data from/to PSRAM. After its completion,
TOP.v will produce a rising edge one the send_uart signal, starting a transmission.

The transmission package consists of 2 bytes, which includes the message read/written.

/* -------------------------------------------------------------------------- */

module uart
#(
    parameter CLK = 60,
    parameter BUFFER_LENGTH = 10
)(
    input clk_PSRAM,                          // rPLL clock of 84MHz
    input uart_rx,                            // Rx channel - input
    input send_uart,                          // Flag for data transmission       
    //output reg [1:0] read_write,            // Correspond to reg [1:0] read_write
    input [15:0] send_msg,                    // Message to be sent

    //output reg quad_start,                  // Rising edge detection
    //output reg [22:0] address,              // Read-write address defined by UART
    //output reg [15:0] data_in,              // Message to be written to PSRAM
    //output reg [3:0] led,                   // Debug LEDs
    output reg [7:0] trigger,                 // Trigger type: "T" or "B"]
    output reg [12:0] threshold,
    output reg [21:0] samples_after,          // Number of samples to be written after the trigger
    output reg [21:0] samples_before,         // Number of samples to be written before the trigger
    output reg flag_acq,                      // Flag to start acquisition
    output reg flag_end_tx,
    output reg flag_debug,
    output uart_tx                            // Tx channel - output
);

localparam HALF_DELAY_WAIT = DELAY_FRAMES / 2; //Divide by two to choose middle of bit

/* -------------------------------- Variables ------------------------------- */

// Variable used in for looping
integer i;

// Detect a rising edge of UART requisition. Only valid on UART controlling of WRITE/READ (Idle process)
reg com_start;
reg d_com_start;

//Receiver
reg [2:0] rxState = 0;          // State machine variable
reg [12:0] rxCounter = 0;       // Counter to keeep track of clocks count
reg [$clog2(BUFFER_LENGTH)-1:0] rxByteCounter = 0;    // Number of bytes received
reg [2:0] rxBitNumber = 0;      // How many bits were read
reg [7:0] dataIn = 0;           // Stores the command
reg byteReady = 0;              // Flag to tell wether UART protocol is finished

//Transmitter
reg [2:0] txState = 0;          // State machine variable
reg [10:0] txCounter = 0;       // Counter to keep track of clocks count
reg [7:0] dataOut = 0;          //
reg txPinRegister = 1;          // Register linked with uart_tx; output of transmission
reg [2:0] txBitNumber = 0;      // Keep track of number of bits transmitted
reg [1:0] txByteCounter = 0;    // Keep track of number of bytes transmitted

//Register to wiring interface
assign uart_tx = txPinRegister;

// 8-bit array Buffer to acquire received data
reg [7:0] buffer [BUFFER_LENGTH-1:0];

/* ---------------------------- Local parameters ---------------------------- */

// State machine states for receiver state
localparam RX_IDLE = 0;
localparam RX_START_BIT = 1;
localparam RX_READ_WAIT = 2;
localparam RX_READ = 3;
localparam RX_STOP_BIT = 5;

// State machine states for transmitter state
localparam TX_IDLE = 0;
localparam TX_START_BIT = 1;
localparam TX_WRITE = 2;
localparam TX_STOP_BIT = 3;

//UART speed
localparam UART_SPEED = 921600;
localparam integer DELAY_FRAMES = (CLK * 1_000_000) / UART_SPEED;

/* --------------------------------- Script --------------------------------- */

initial begin
    for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
        buffer[i] <= 8'h00;
    end
    rxByteCounter <= 0;
    //read_write <= 0;
    //com_start <= 0;
    //d_com_start <= 0;
    //quad_start <= 0;
    //led <= 0;
    flag_end_tx <= 0;
    txState <= TX_IDLE;
    flag_acq <= 0;
end

always @(posedge clk_PSRAM) begin

    // Rising edge detection
    //quad_start <= com_start && !d_com_start;
    //d_com_start <= com_start;
    //com_start <= 0;
    //read_write = read_write;

/* ---------------------------- Receiving routine --------------------------- */

    case(rxState)
        RX_IDLE: begin           
            byteReady <= 0;
            if(!uart_rx) begin                          // Low-edge trigger detected on Rx channel - start of message
                rxState <= RX_START_BIT;
                rxCounter <= 1;                         // Include current 'clock pulse' in the UART bit frame
                rxBitNumber <= 0;                       // Resets number of bits received
                com_start <= 0;                         // Idle start is LOW. Only HIGH when receive state is DONE.
            end
        end
        RX_START_BIT: begin                             // Shifts the bit frame once in order to make sure it's stable when collecting info
            if(rxCounter == HALF_DELAY_WAIT) begin  
                rxState <= RX_READ_WAIT;
                rxCounter <= 1;
            end
            else rxCounter <= {rxCounter + 10'b1};
        end
        RX_READ_WAIT: begin                             // Wait for (DELAY_FRAMES) clock pulses to read. Resulting baud rate is 115200 bps
            rxCounter <= {rxCounter + 10'b1};
            if((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_READ;
            end
        end
        RX_READ: begin
            rxCounter <= 1;
            // UART sends data from LSB to MSB
            dataIn <= {uart_rx, dataIn[7:1]};           // Shift register -> Shifts one bit to the right
            rxBitNumber <= {rxBitNumber + 3'b1};        // Increment bit number
            if(rxBitNumber == 3'b111) begin
                rxState <= RX_STOP_BIT;                 // If one byte were received, shift to next byte
            end
            else rxState <= RX_READ_WAIT;
        end
        RX_STOP_BIT: begin
            rxCounter <= {rxCounter + 10'b1};
            if((rxCounter + 1) == DELAY_FRAMES) begin   // Re-shifting bit frame to end communcation
                rxState <= RX_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase

/* ----------------------- Interpreting received data ----------------------- */

        //Flag to be used by automatic debugging
        flag_debug <= 0;

    if(byteReady) begin
        rxByteCounter <= {rxByteCounter + 6'b1};        // Increment bytes number
        buffer[rxByteCounter] <= dataIn;                 // Storing received byte into buffer
        
        if(rxByteCounter >= 0) begin

        //* Added start_acq, setting to zero for rising edge detection on TOP module
        flag_acq <= 0;

            //Start requested by Python. Used in debugging
            if(dataIn == 8'h53) begin
                flag_debug <= 1;
                //Resetting buffer
                rxByteCounter <= 0;
                buffer[0] <= 0;
                dataIn <= 0;
            end

            //Data acquistion start - buffer[0] = A
            else if(buffer[0] == 8'h41) begin
                if(rxByteCounter >= 9) begin
                    trigger <= buffer[1];
                    threshold <= {buffer[2][4:0], buffer[3]};   // User selected threshold trigger. 12 bits gets stored in var threshold.
                    //threshold <= 13'b1111111111111;
                    //else threshold[12] <= 1'b1;                                // User selected button trigger. Asserts 13 bits to threshold, a value that is never reached.
                    samples_after <= {buffer[4][5:0], buffer[5], buffer[6]};   //22 bits: Represents 2^22-1 possible values
                    samples_before <= {buffer[7][5:0], buffer[8], dataIn};     //22 bits: Represents 2^22-1 possible values 
                    buffer[0] <= 0;
                    dataIn <= 0;
                    //
                    // Reset counter
                    rxByteCounter <= 0;
                    flag_acq <= 1;
                end
            end

            
            /*
            //Read operation - buffer[0] = R
            else if(buffer[0] == 8'h52) begin
                if(rxByteCounter >= 3) begin            // Forth byte transmitted
                    read_write = 2;                     // Address collected, ready for read operation
                    //led <= led + 1;
                    com_start <= 1;                     // Receive is done! Proceed to start reading proccess with PSRAM
                    address = {buffer[1][6:0], buffer[2], buffer[3]};   // Messsage's address MUST be defined here, before buffer resets
                    //
                    // Reset counter
                    rxByteCounter <= 0;
                    // Clear buffer
                    for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
                        buffer[i] = 8'h00;
                    end
                end
            end

            // Writing operation - dataIn = W
            else if(buffer[0] == 8'h57) begin
                if(rxByteCounter >= 5) begin                    // Sixth byte were transmitted
                    read_write = 1;                     // Address & message collected, ready for read operation. Might not work
                    com_start <= 1;                     // Receive is done! Proceed to start reading proccess with PSRAM
                    data_in = {buffer[4], buffer[5]};   // Data_in to be written. MSB received first
                    address = {buffer[1][6:0], buffer[2], buffer[3]};   // Messsage's address MUST be defined here, before buffer resets
                    //
                    // Reset counter
                    rxByteCounter <= 0;
                    // Clear buffer
                    for (i = 0; i <= BUFFER_LENGTH-1; i = i + 1) begin
                        buffer[i] = 8'h00;
                    end
                end
            end
            */
            //! Create a failure detection routine
            //else begin
            //    rxByteCounter <= 0;
            //end
        end
    end

/* -------------------------- Transmitting routine -------------------------- */

    case(txState)
        TX_IDLE: begin
            if (send_uart) begin                            // If send_uart is HIGH, start transmission state through TX channel. If else, output HIGH state (nothing happens)
                flag_end_tx <= 0;
                {buffer[0],buffer[1]} <= send_msg;
                txState <= TX_START_BIT;
                txCounter <= 0;
                txByteCounter <= 0;
                //led <= led + 1;                             //* Increasing debug LEDs. Tx send correctly assigned by UART module
            end
            else begin
                txPinRegister <= 1;
            end
        end
        TX_START_BIT: begin                                 // First cycle of UART tranmission. Just throw a negative edge signal
            txPinRegister <= 0;                             // Negative-edge at TX. Microcontroller will know a message will be sent
            if ((txCounter + 1) == DELAY_FRAMES) begin      // Doesn't need to shift half baud rate, because is SENDING a message (no risk to GET noisy data)
                txState <= TX_WRITE;
                dataOut <= buffer[txByteCounter];           // Gets next byte to be transmitted based on buffer
                txBitNumber <= 0;
                txCounter <= 0;
            end else 
            txCounter <= {txCounter + 9'b1};
        end
        TX_WRITE: begin
            txPinRegister <= dataOut[txBitNumber];          // Updates tx register (TX channel) to output current bit
            if ((txCounter + 1) == DELAY_FRAMES) begin  
                if (txBitNumber == 3'b111) begin            // If 8 bits were transmitted, stop transmitting current BYTE
                    txState <= TX_STOP_BIT;
                end else begin
                    txState <= TX_WRITE;                    // Transmits next bit
                    txBitNumber <= {txBitNumber + 3'b1};
                end
                txCounter <= 0;
            end else 
            txCounter <= {txCounter + 9'b1};
        end
        TX_STOP_BIT: begin
            txPinRegister <= 1;                             // Write HIGH state to TX (end of byte transmission)
            if ((txCounter + 1) == DELAY_FRAMES) begin
                if (txByteCounter == 1) begin               //* If all 2 bytes were transmitted, stop proccess - These Bytes are the message
                    txState <= TX_IDLE;                     // Debounce not needed: signal flag
                    flag_end_tx <= 1;
                end else begin
                txByteCounter <= {txByteCounter + 2'b1};    // If else, move to next byte
                    txState <= TX_START_BIT;
                end
                txCounter <= 0;
            end else 
            txCounter <= {txCounter + 9'b1};
        end
    endcase
end
endmodule

