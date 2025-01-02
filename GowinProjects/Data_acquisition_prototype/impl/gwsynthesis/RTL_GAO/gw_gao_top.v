module gw_gao(
    \i[21] ,
    \i[20] ,
    \i[19] ,
    \i[18] ,
    \i[17] ,
    \i[16] ,
    \i[15] ,
    \i[14] ,
    \i[13] ,
    \i[12] ,
    \i[11] ,
    \i[10] ,
    \i[9] ,
    \i[8] ,
    \i[7] ,
    \i[6] ,
    \i[5] ,
    \i[4] ,
    \i[3] ,
    \i[2] ,
    \i[1] ,
    \i[0] ,
    clk_PSRAM,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \i[21] ;
input \i[20] ;
input \i[19] ;
input \i[18] ;
input \i[17] ;
input \i[16] ;
input \i[15] ;
input \i[14] ;
input \i[13] ;
input \i[12] ;
input \i[11] ;
input \i[10] ;
input \i[9] ;
input \i[8] ;
input \i[7] ;
input \i[6] ;
input \i[5] ;
input \i[4] ;
input \i[3] ;
input \i[2] ;
input \i[1] ;
input \i[0] ;
input clk_PSRAM;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \i[21] ;
wire \i[20] ;
wire \i[19] ;
wire \i[18] ;
wire \i[17] ;
wire \i[16] ;
wire \i[15] ;
wire \i[14] ;
wire \i[13] ;
wire \i[12] ;
wire \i[11] ;
wire \i[10] ;
wire \i[9] ;
wire \i[8] ;
wire \i[7] ;
wire \i[6] ;
wire \i[5] ;
wire \i[4] ;
wire \i[3] ;
wire \i[2] ;
wire \i[1] ;
wire \i[0] ;
wire clk_PSRAM;
wire tms_pad_i;
wire tck_pad_i;
wire tdi_pad_i;
wire tdo_pad_o;
wire tms_i_c;
wire tck_i_c;
wire tdi_i_c;
wire tdo_o_c;
wire [9:0] control0;
wire gao_jtag_tck;
wire gao_jtag_reset;
wire run_test_idle_er1;
wire run_test_idle_er2;
wire shift_dr_capture_dr;
wire update_dr;
wire pause_dr;
wire enable_er1;
wire enable_er2;
wire gao_jtag_tdi;
wire tdo_er1;

IBUF tms_ibuf (
    .I(tms_pad_i),
    .O(tms_i_c)
);

IBUF tck_ibuf (
    .I(tck_pad_i),
    .O(tck_i_c)
);

IBUF tdi_ibuf (
    .I(tdi_pad_i),
    .O(tdi_i_c)
);

OBUF tdo_obuf (
    .I(tdo_o_c),
    .O(tdo_pad_o)
);

GW_JTAG  u_gw_jtag(
    .tms_pad_i(tms_i_c),
    .tck_pad_i(tck_i_c),
    .tdi_pad_i(tdi_i_c),
    .tdo_pad_o(tdo_o_c),
    .tck_o(gao_jtag_tck),
    .test_logic_reset_o(gao_jtag_reset),
    .run_test_idle_er1_o(run_test_idle_er1),
    .run_test_idle_er2_o(run_test_idle_er2),
    .shift_dr_capture_dr_o(shift_dr_capture_dr),
    .update_dr_o(update_dr),
    .pause_dr_o(pause_dr),
    .enable_er1_o(enable_er1),
    .enable_er2_o(enable_er2),
    .tdi_o(gao_jtag_tdi),
    .tdo_er1_i(tdo_er1),
    .tdo_er2_i(1'b0)
);

gw_con_top  u_icon_top(
    .tck_i(gao_jtag_tck),
    .tdi_i(gao_jtag_tdi),
    .tdo_o(tdo_er1),
    .rst_i(gao_jtag_reset),
    .control0(control0[9:0]),
    .enable_i(enable_er1),
    .shift_dr_capture_dr_i(shift_dr_capture_dr),
    .update_dr_i(update_dr)
);

ao_top u_ao_top(
    .control(control0[9:0]),
    .data_i({\i[21] ,\i[20] ,\i[19] ,\i[18] ,\i[17] ,\i[16] ,\i[15] ,\i[14] ,\i[13] ,\i[12] ,\i[11] ,\i[10] ,\i[9] ,\i[8] ,\i[7] ,\i[6] ,\i[5] ,\i[4] ,\i[3] ,\i[2] ,\i[1] ,\i[0] }),
    .clk_i(clk_PSRAM)
);

endmodule
