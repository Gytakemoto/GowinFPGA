module uart
#(
    parameter DELAY_FRAMES = 234 // 27Mhz / 115200 Baud Rate
)
(
    input sys_clk,       //Internal system clock of 27MHz
    input uart_rx,       //Rx channel - input
    input btn,           //Button for ???

    output uart_tx,      //Tx channel - output
    output reg [3:0] led //
);

localparam HALF_DELAY_WAIT = DELAY_FRAMES / 2; //Divide by to to choose middle of bit

//Variables
reg [3:0] rxState = 0;          //State machine variable
reg [12:0] rxCounter = 0;       //Counter to keeep track of clock count
reg [2:0] rxBitNumber = 0;      //How many bits were read
reg [7:0] dataIn = 0;           //Stores the command
reg byteReady = 0;              //Flag to tell wether UART protocol is finished


//State machine states
localparam RX_IDLE = 0;
localparam RX_START_BIT = 1;
localparam RX_READ_WAIT = 2;
localparam RX_READ = 3;
localparam RX_STOP_BIT = 5;

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
end

endmodule

