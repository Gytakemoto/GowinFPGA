module gw_gao(
    \proccess[3] ,
    \proccess[2] ,
    \proccess[1] ,
    \proccess[0] ,
    \erro_read[31] ,
    \erro_read[30] ,
    \erro_read[29] ,
    \erro_read[28] ,
    \erro_read[27] ,
    \erro_read[26] ,
    \erro_read[25] ,
    \erro_read[24] ,
    \erro_read[23] ,
    \erro_read[22] ,
    \erro_read[21] ,
    \erro_read[20] ,
    \erro_read[19] ,
    \erro_read[18] ,
    \erro_read[17] ,
    \erro_read[16] ,
    \erro_read[15] ,
    \erro_read[14] ,
    \erro_read[13] ,
    \erro_read[12] ,
    \erro_read[11] ,
    \erro_read[10] ,
    \erro_read[9] ,
    \erro_read[8] ,
    \erro_read[7] ,
    \erro_read[6] ,
    \erro_read[5] ,
    \erro_read[4] ,
    \erro_read[3] ,
    \erro_read[2] ,
    \erro_read[1] ,
    \erro_read[0] ,
    sys_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \proccess[3] ;
input \proccess[2] ;
input \proccess[1] ;
input \proccess[0] ;
input \erro_read[31] ;
input \erro_read[30] ;
input \erro_read[29] ;
input \erro_read[28] ;
input \erro_read[27] ;
input \erro_read[26] ;
input \erro_read[25] ;
input \erro_read[24] ;
input \erro_read[23] ;
input \erro_read[22] ;
input \erro_read[21] ;
input \erro_read[20] ;
input \erro_read[19] ;
input \erro_read[18] ;
input \erro_read[17] ;
input \erro_read[16] ;
input \erro_read[15] ;
input \erro_read[14] ;
input \erro_read[13] ;
input \erro_read[12] ;
input \erro_read[11] ;
input \erro_read[10] ;
input \erro_read[9] ;
input \erro_read[8] ;
input \erro_read[7] ;
input \erro_read[6] ;
input \erro_read[5] ;
input \erro_read[4] ;
input \erro_read[3] ;
input \erro_read[2] ;
input \erro_read[1] ;
input \erro_read[0] ;
input sys_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \proccess[3] ;
wire \proccess[2] ;
wire \proccess[1] ;
wire \proccess[0] ;
wire \erro_read[31] ;
wire \erro_read[30] ;
wire \erro_read[29] ;
wire \erro_read[28] ;
wire \erro_read[27] ;
wire \erro_read[26] ;
wire \erro_read[25] ;
wire \erro_read[24] ;
wire \erro_read[23] ;
wire \erro_read[22] ;
wire \erro_read[21] ;
wire \erro_read[20] ;
wire \erro_read[19] ;
wire \erro_read[18] ;
wire \erro_read[17] ;
wire \erro_read[16] ;
wire \erro_read[15] ;
wire \erro_read[14] ;
wire \erro_read[13] ;
wire \erro_read[12] ;
wire \erro_read[11] ;
wire \erro_read[10] ;
wire \erro_read[9] ;
wire \erro_read[8] ;
wire \erro_read[7] ;
wire \erro_read[6] ;
wire \erro_read[5] ;
wire \erro_read[4] ;
wire \erro_read[3] ;
wire \erro_read[2] ;
wire \erro_read[1] ;
wire \erro_read[0] ;
wire sys_clk;
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
    .data_i({\proccess[3] ,\proccess[2] ,\proccess[1] ,\proccess[0] ,\erro_read[31] ,\erro_read[30] ,\erro_read[29] ,\erro_read[28] ,\erro_read[27] ,\erro_read[26] ,\erro_read[25] ,\erro_read[24] ,\erro_read[23] ,\erro_read[22] ,\erro_read[21] ,\erro_read[20] ,\erro_read[19] ,\erro_read[18] ,\erro_read[17] ,\erro_read[16] ,\erro_read[15] ,\erro_read[14] ,\erro_read[13] ,\erro_read[12] ,\erro_read[11] ,\erro_read[10] ,\erro_read[9] ,\erro_read[8] ,\erro_read[7] ,\erro_read[6] ,\erro_read[5] ,\erro_read[4] ,\erro_read[3] ,\erro_read[2] ,\erro_read[1] ,\erro_read[0] }),
    .clk_i(sys_clk)
);

endmodule
