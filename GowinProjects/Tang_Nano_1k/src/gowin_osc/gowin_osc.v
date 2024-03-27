//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9 (64-bit)
//Part Number: GW1N-LV1QN48C6/I5
//Device: GW1N-1
//Created Time: Wed Mar 20 15:18:54 2024

module Gowin_OSC (oscout);

output oscout;

OSCH osc_inst (
    .OSCOUT(oscout)
);

defparam osc_inst.FREQ_DIV = 84;

endmodule //Gowin_OSC
