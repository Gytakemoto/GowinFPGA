//Basic UART module based on LUSHAY LABS

module uart
#(
    parameter DELAY_FRAMES = 234 // 27Mhz / 115200 Baud Rate
)
(
    input sys_clk,       //Internal system clock of 27MHz
    input uart_rx,       //Rx channel - input
    input btn,           //Button for transmit data

    output uart_tx,      //Tx channel - output
    output reg [3:0] led //Debug LEDs
);

localparam HALF_DELAY_WAIT = DELAY_FRAMES / 2; //Divide by to to choose middle of bit

//Variables

//Receiver
reg [3:0] rxState = 0;          //State machine variable
reg [12:0] rxCounter = 0;       //Counter to keeep track of clocks count
reg [2:0] rxBitNumber = 0;      //How many bits were read
reg [7:0] dataIn = 0;           //Stores the command
reg byteReady = 0;              //Flag to tell wether UART protocol is finished

//Transmitter
reg [3:0] txState = 0;          //State machine variable
reg [24:0] txCounter = 0;       //Counter to keep track of clocks count
reg [7:0] dataOut = 0;          //
reg txPinRegister = 1;          //Register linked with uart_tx; output of transmission
reg [2:0] txBitNumber = 0;      //Keep track of number of bits transmitted
reg [3:0] txByteCounter = 0;    //Keep track of number of bytes transmitted

//Register to wiring interface
assign uart_tx = txPinRegister;

localparam MEMORY_LENGTH = 12;
reg [7:0] testMemory [MEMORY_LENGTH-1:0];

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

//Simulates a 'memory message'
initial begin
    testMemory[0] = "L";
    testMemory[1] = "u";
    testMemory[2] = "s";
    testMemory[3] = "h";
    testMemory[4] = "a";
    testMemory[5] = "y";
    testMemory[6] = " ";
    testMemory[7] = "L";
    testMemory[8] = "a";
    testMemory[9] = "b";
    testMemory[10] = "s";
    testMemory[10] = " ";
end

always @(posedge sys_clk) begin

    case(rxState)

        RX_IDLE: begin
            if(!uart_rx) begin              //Low-edge trigger detected on Rx channel - start of message
                rxState <= RX_START_BIT;
                rxCounter <= 1;             //Include current 'clock pulse' in the UART bit frame
                rxBitNumber <= 0;
                byteReady <= 0;
            end
        end
        RX_START_BIT: begin                         //Just shifts the bit frame once
            if(rxCounter == HALF_DELAY_WAIT) begin  //Shift half of the bit one time and then proceed to wait 1 complete cycle
                rxState <= RX_READ_WAIT;
                rxCounter <= 1;
            end
            else rxCounter <= rxCounter + 1;
        end
        RX_READ_WAIT: begin                         //Wait for x clock pulses to read
            rxCounter <= rxCounter + 1;
            if((rxCounter + 1) == DELAY_FRAMES) begin
                rxState <= RX_READ;
            end
        end
        RX_READ: begin
            rxCounter <= 1;
            //UART sends data from LSB to MSB
            dataIn <= {uart_rx, dataIn[7:1]};  //Move one bit towards LSB and add uart_rx: Shift register
            rxBitNumber <= rxBitNumber + 1; 
            if(rxBitNumber == 3'b111) rxState <= RX_STOP_BIT;
            else rxState <= RX_READ_WAIT;
        end
        RX_STOP_BIT: begin
            rxCounter <= rxCounter + 1;
            if((rxCounter + 1) == DELAY_FRAMES) begin   //Re-shifting bit frame to end communcation
                rxState <= RX_IDLE;
                rxCounter <= 0;
                byteReady <= 1;
            end
        end
    endcase

    if(byteReady) begin
        led <= dataIn[3:0];
    end

    case(txState)

    TX_IDLE: begin
        if (btn == 0) begin                         //If button is pressed, start transmission state through TX channel. If else, output HIGH state (nothing happens)
            txState <= TX_START_BIT;
            txCounter <= 0;
            txByteCounter <= 0;             
        end
        else begin
            txPinRegister <= 1;
        end
    end
    TX_START_BIT: begin                             //First cycle of UART tranmission. Just throw a negative edge signal
        txPinRegister <= 0;                         //Negative-edge at TX. Microcontroller will know a message will be sent
        if ((txCounter + 1) == DELAY_FRAMES) begin  //Doesn't need to shift half baud rate, because is SENDING a message (no risk to GET noisy data)
            txState <= TX_WRITE;
            dataOut <= testMemory[txByteCounter];   //Gets next byte to be transmitted based on testMemory
            txBitNumber <= 0;
            txCounter <= 0;
        end else 
            txCounter <= txCounter + 1;
    end
    TX_WRITE: begin
        txPinRegister <= dataOut[txBitNumber];      //Updates tx register (TX channel) to output current bit
        if ((txCounter + 1) == DELAY_FRAMES) begin  
            if (txBitNumber == 3'b111) begin        //If 8 bits were transmitted, stop transmitting current BYTE
                txState <= TX_STOP_BIT;
            end else begin
                txState <= TX_WRITE;                //Transmits next bit
                txBitNumber <= txBitNumber + 1;
            end
            txCounter <= 0;
        end else 
            txCounter <= txCounter + 1;
    end
    TX_STOP_BIT: begin
        txPinRegister <= 1;                         //Write HIGH state to TX (end of byte transmission)
        if ((txCounter + 1) == DELAY_FRAMES) begin
            if (txByteCounter == MEMORY_LENGTH - 1) begin   //If all data were transmitted, stop proccess 
                txState <= TX_DEBOUNCE;
            end else begin
                txByteCounter <= txByteCounter + 1;         //If else, move to next byte
                txState <= TX_START_BIT;
            end
            txCounter <= 0;
        end else 
            txCounter <= txCounter + 1;
    end
    TX_DEBOUNCE: begin                              //Guarantees that by pressing button once, it will occurs ONCE
        if (txCounter == 23'b111111111111111111) begin
            if (btn == 1) 
                txState <= TX_IDLE;
        end else
            txCounter <= txCounter + 1;
    end
    endcase
end

endmodule

