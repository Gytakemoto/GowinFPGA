//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//GOWIN Version: V1.9.8.06-1
//Part Number: GW1NZ-LV1QN48C6/I5
//Device: GW1NZ-1
//Created Time: Thu Aug 04 15:13:49 2022

module Gowin_OSC (oscout, oscen);

output oscout;
input oscen;

OSCZ osc_inst (
    .OSCOUT(oscout),
    .OSCEN(oscen)
);

defparam osc_inst.FREQ_DIV = 16;
defparam osc_inst.S_RATE = "SLOW";

endmodule //Gowin_OSC
