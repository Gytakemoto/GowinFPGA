//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8.06-1
//Part Number: GW1NZ-LV1QN48C6/I5
//Device: GW1NZ-1
//Created Time: Thu Aug 04 12:14:25 2022

module Gowin_CLKDIV2 (clkout, hclkin, resetn);

output clkout;
input hclkin;
input resetn;

CLKDIV2 clkdiv2_inst (
    .CLKOUT(clkout),
    .HCLKIN(hclkin),
    .RESETN(resetn)
);

endmodule //Gowin_CLKDIV2
