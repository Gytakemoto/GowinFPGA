//<time_unit>/<time_precision>
`timescale 1ps/1fs
`include "simu.v"

module Testbench ();

wire clock;
wire clk_PSRAM;
reg enable;


clk_gen clk1(
    .enable(enable),
    .clk(clock)
);

clk_gen clk2(
    .enable(enable),
    .clk(clk_PSRAM) 
);
defparam clk2.FREQ = 84;

//

parameter real PSRAM_FREQ = 84;
parameter real clk_pd = 1/(PSRAM_FREQ * 1e6) * 1e9;

initial begin
    $display ("PSRAM desired FREQ: %0.3f ns", clk_pd);
    $dumpfile("Testbench.vcd");
    $dumpvars(enable, clock, clk_PSRAM);
    #100 enable = 1;
    #1e4 enable = 0;

    $finish; 
end

endmodule
