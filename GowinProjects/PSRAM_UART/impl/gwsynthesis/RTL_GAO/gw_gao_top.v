module gw_gao(
    \address[22] ,
    \address[21] ,
    \address[20] ,
    \address[19] ,
    \address[18] ,
    \address[17] ,
    \address[16] ,
    \address[15] ,
    \address[14] ,
    \address[13] ,
    \address[12] ,
    \address[11] ,
    \address[10] ,
    \address[9] ,
    \address[8] ,
    \address[7] ,
    \address[6] ,
    \address[5] ,
    \address[4] ,
    \address[3] ,
    \address[2] ,
    \address[1] ,
    \address[0] ,
    \process[3] ,
    \process[2] ,
    \process[1] ,
    \process[0] ,
    \read[15] ,
    \read[14] ,
    \read[13] ,
    \read[12] ,
    \read[11] ,
    \read[10] ,
    \read[9] ,
    \read[8] ,
    \read[7] ,
    \read[6] ,
    \read[5] ,
    \read[4] ,
    \read[3] ,
    \read[2] ,
    \read[1] ,
    \read[0] ,
    \read_write[1] ,
    \read_write[0] ,
    error,
    \debug[15] ,
    \debug[14] ,
    \debug[13] ,
    \debug[12] ,
    \debug[11] ,
    \debug[10] ,
    \debug[9] ,
    \debug[8] ,
    \debug[7] ,
    \debug[6] ,
    \debug[5] ,
    \debug[4] ,
    \debug[3] ,
    \debug[2] ,
    \debug[1] ,
    \debug[0] ,
    \initialize/PSRAM_com/debug ,
    sys_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \address[22] ;
input \address[21] ;
input \address[20] ;
input \address[19] ;
input \address[18] ;
input \address[17] ;
input \address[16] ;
input \address[15] ;
input \address[14] ;
input \address[13] ;
input \address[12] ;
input \address[11] ;
input \address[10] ;
input \address[9] ;
input \address[8] ;
input \address[7] ;
input \address[6] ;
input \address[5] ;
input \address[4] ;
input \address[3] ;
input \address[2] ;
input \address[1] ;
input \address[0] ;
input \process[3] ;
input \process[2] ;
input \process[1] ;
input \process[0] ;
input \read[15] ;
input \read[14] ;
input \read[13] ;
input \read[12] ;
input \read[11] ;
input \read[10] ;
input \read[9] ;
input \read[8] ;
input \read[7] ;
input \read[6] ;
input \read[5] ;
input \read[4] ;
input \read[3] ;
input \read[2] ;
input \read[1] ;
input \read[0] ;
input \read_write[1] ;
input \read_write[0] ;
input error;
input \debug[15] ;
input \debug[14] ;
input \debug[13] ;
input \debug[12] ;
input \debug[11] ;
input \debug[10] ;
input \debug[9] ;
input \debug[8] ;
input \debug[7] ;
input \debug[6] ;
input \debug[5] ;
input \debug[4] ;
input \debug[3] ;
input \debug[2] ;
input \debug[1] ;
input \debug[0] ;
input \initialize/PSRAM_com/debug ;
input sys_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \address[22] ;
wire \address[21] ;
wire \address[20] ;
wire \address[19] ;
wire \address[18] ;
wire \address[17] ;
wire \address[16] ;
wire \address[15] ;
wire \address[14] ;
wire \address[13] ;
wire \address[12] ;
wire \address[11] ;
wire \address[10] ;
wire \address[9] ;
wire \address[8] ;
wire \address[7] ;
wire \address[6] ;
wire \address[5] ;
wire \address[4] ;
wire \address[3] ;
wire \address[2] ;
wire \address[1] ;
wire \address[0] ;
wire \process[3] ;
wire \process[2] ;
wire \process[1] ;
wire \process[0] ;
wire \read[15] ;
wire \read[14] ;
wire \read[13] ;
wire \read[12] ;
wire \read[11] ;
wire \read[10] ;
wire \read[9] ;
wire \read[8] ;
wire \read[7] ;
wire \read[6] ;
wire \read[5] ;
wire \read[4] ;
wire \read[3] ;
wire \read[2] ;
wire \read[1] ;
wire \read[0] ;
wire \read_write[1] ;
wire \read_write[0] ;
wire error;
wire \debug[15] ;
wire \debug[14] ;
wire \debug[13] ;
wire \debug[12] ;
wire \debug[11] ;
wire \debug[10] ;
wire \debug[9] ;
wire \debug[8] ;
wire \debug[7] ;
wire \debug[6] ;
wire \debug[5] ;
wire \debug[4] ;
wire \debug[3] ;
wire \debug[2] ;
wire \debug[1] ;
wire \debug[0] ;
wire \initialize/PSRAM_com/debug ;
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
    .data_i({\address[22] ,\address[21] ,\address[20] ,\address[19] ,\address[18] ,\address[17] ,\address[16] ,\address[15] ,\address[14] ,\address[13] ,\address[12] ,\address[11] ,\address[10] ,\address[9] ,\address[8] ,\address[7] ,\address[6] ,\address[5] ,\address[4] ,\address[3] ,\address[2] ,\address[1] ,\address[0] ,\process[3] ,\process[2] ,\process[1] ,\process[0] ,\read[15] ,\read[14] ,\read[13] ,\read[12] ,\read[11] ,\read[10] ,\read[9] ,\read[8] ,\read[7] ,\read[6] ,\read[5] ,\read[4] ,\read[3] ,\read[2] ,\read[1] ,\read[0] ,\read_write[1] ,\read_write[0] ,error,\debug[15] ,\debug[14] ,\debug[13] ,\debug[12] ,\debug[11] ,\debug[10] ,\debug[9] ,\debug[8] ,\debug[7] ,\debug[6] ,\debug[5] ,\debug[4] ,\debug[3] ,\debug[2] ,\debug[1] ,\debug[0] ,\initialize/PSRAM_com/debug }),
    .clk_i(sys_clk)
);

endmodule
