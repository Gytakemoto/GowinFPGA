//<time_unit>/<time_precision>
`include "simu.v"
`include "grPLL_27_to_84.v"

`timescale 1us/1fs
module Testbench ();

wire clock;
wire clk_PSRAM;
reg enable;

//27MHz
clk_gen clk1(
    .enable(enable),
    .clk(clock)
);

//84Mhz

/*clk_gen clk2(
    .enable(enable),
    .clk(clk_PSRAM) 
);
defparam clk2.FREQ = 84;
*/

Gowin_rPLL_27_to_84MHz clk2(
    .clkout(clk_PSRAM),
    .clkin(clock)
);

parameter real PSRAM_FREQ = 84;
parameter real clk_pd = 1/(PSRAM_FREQ * 1e6) * 1e9;

initial begin
    $display ("PSRAM desired FREQ: %0.3f ns", clk_pd);
    $dumpfile("Testbench.vcd");
    $dumpvars(enable, clock, clk_PSRAM);
    #100 enable = 1;
    #1e3 enable = 0;

    $finish; 
end

endmodule
