module gw_gao(
    \message[15] ,
    \message[14] ,
    \message[13] ,
    \message[12] ,
    \message[11] ,
    \message[10] ,
    \message[9] ,
    \message[8] ,
    \message[7] ,
    \message[6] ,
    \message[5] ,
    \message[4] ,
    \message[3] ,
    \message[2] ,
    \message[1] ,
    \message[0] ,
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
    \initialize/PSRAM_com/debug_r ,
    \initialize/message[15] ,
    \initialize/message[14] ,
    \initialize/message[13] ,
    \initialize/message[12] ,
    \initialize/message[11] ,
    \initialize/message[10] ,
    \initialize/message[9] ,
    \initialize/message[8] ,
    \initialize/message[7] ,
    \initialize/message[6] ,
    \initialize/message[5] ,
    \initialize/message[4] ,
    \initialize/message[3] ,
    \initialize/message[2] ,
    \initialize/message[1] ,
    \initialize/message[0] ,
    sys_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \message[15] ;
input \message[14] ;
input \message[13] ;
input \message[12] ;
input \message[11] ;
input \message[10] ;
input \message[9] ;
input \message[8] ;
input \message[7] ;
input \message[6] ;
input \message[5] ;
input \message[4] ;
input \message[3] ;
input \message[2] ;
input \message[1] ;
input \message[0] ;
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
input \initialize/PSRAM_com/debug_r ;
input \initialize/message[15] ;
input \initialize/message[14] ;
input \initialize/message[13] ;
input \initialize/message[12] ;
input \initialize/message[11] ;
input \initialize/message[10] ;
input \initialize/message[9] ;
input \initialize/message[8] ;
input \initialize/message[7] ;
input \initialize/message[6] ;
input \initialize/message[5] ;
input \initialize/message[4] ;
input \initialize/message[3] ;
input \initialize/message[2] ;
input \initialize/message[1] ;
input \initialize/message[0] ;
input sys_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \message[15] ;
wire \message[14] ;
wire \message[13] ;
wire \message[12] ;
wire \message[11] ;
wire \message[10] ;
wire \message[9] ;
wire \message[8] ;
wire \message[7] ;
wire \message[6] ;
wire \message[5] ;
wire \message[4] ;
wire \message[3] ;
wire \message[2] ;
wire \message[1] ;
wire \message[0] ;
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
wire \initialize/PSRAM_com/debug_r ;
wire \initialize/message[15] ;
wire \initialize/message[14] ;
wire \initialize/message[13] ;
wire \initialize/message[12] ;
wire \initialize/message[11] ;
wire \initialize/message[10] ;
wire \initialize/message[9] ;
wire \initialize/message[8] ;
wire \initialize/message[7] ;
wire \initialize/message[6] ;
wire \initialize/message[5] ;
wire \initialize/message[4] ;
wire \initialize/message[3] ;
wire \initialize/message[2] ;
wire \initialize/message[1] ;
wire \initialize/message[0] ;
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
    .data_i({\message[15] ,\message[14] ,\message[13] ,\message[12] ,\message[11] ,\message[10] ,\message[9] ,\message[8] ,\message[7] ,\message[6] ,\message[5] ,\message[4] ,\message[3] ,\message[2] ,\message[1] ,\message[0] ,\read[15] ,\read[14] ,\read[13] ,\read[12] ,\read[11] ,\read[10] ,\read[9] ,\read[8] ,\read[7] ,\read[6] ,\read[5] ,\read[4] ,\read[3] ,\read[2] ,\read[1] ,\read[0] ,\initialize/PSRAM_com/debug_r ,\initialize/message[15] ,\initialize/message[14] ,\initialize/message[13] ,\initialize/message[12] ,\initialize/message[11] ,\initialize/message[10] ,\initialize/message[9] ,\initialize/message[8] ,\initialize/message[7] ,\initialize/message[6] ,\initialize/message[5] ,\initialize/message[4] ,\initialize/message[3] ,\initialize/message[2] ,\initialize/message[1] ,\initialize/message[0] }),
    .clk_i(sys_clk)
);

endmodule
