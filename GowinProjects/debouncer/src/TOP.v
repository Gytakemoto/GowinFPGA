module TOP (

//IO pins
//INPUT
input sys_clk, //Internal 27 MHz oscillator
input buttonA, //Tang Nano Button A
input buttonB, //Tang Nano Button B

output clk_PSRAM,            // pin 47

//Debug external LEDs
output reg [3:0] led
);

gowin_rpll_27_to_84 clk(
    .clkin(sys_clk),
    .clkout(clk_PSRAM)
);

sync sync_buttonA(
    .clock(clk_PSRAM),
    .in(buttonA),
    .out(buttonA_sync)
);

once sync_buttonA_debounced(
    .clk(clk_PSRAM),
    .button(buttonA_deb),
    .button_once(buttonA_once)
);

debouncer deb_buttonA(
    .clock(clk_PSRAM),
    .IN(buttonA_sync),
    .OUT(buttonA_deb)
);

reg [3:0] counter;
//wire buttonA_sync;

initial begin
    counter <=0;
end

always @(posedge clk_PSRAM) begin

   //Activates only when error is present while pressing buttonA
   if(buttonA_once) begin

        counter <= counter + 1'd1;

        //For each button pressed, change debug leds
         case(counter) 
            0: led[3:0] <= 4'b0000;
            1: led[3:0] <= 4'b0001;
            2: led[3:0] <= 4'b0010;
            3: led[3:0] <= 4'b0011;
            4: led[3:0] <= 4'b0100;
            5: led[3:0] <= 4'b0101;
            6: led[3:0] <= 4'b0110;
            7: led[3:0] <= 4'b0111;
            8: led[3:0] <= 4'b1000;
            9: led[3:0] <= 4'b1001;
            10: led[3:0] <= 4'b1010;
            11: led[3:0] <= 4'b1011;
            12: led[3:0] <= 4'b1100;
            13: led[3:0] <= 4'b1101;
            14: led[3:0] <= 4'b1110;
            15: led[3:0] <= 4'b1111;
            default: begin
                counter <= 0;
            end
          endcase
    end
end
endmodule

