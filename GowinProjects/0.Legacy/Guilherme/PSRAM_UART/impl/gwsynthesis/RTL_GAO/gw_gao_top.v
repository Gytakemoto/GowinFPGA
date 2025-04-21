module gw_gao(
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
    \process[3] ,
    \process[2] ,
    \process[1] ,
    \process[0] ,
    \initialize/step[3] ,
    \initialize/step[2] ,
    \initialize/step[1] ,
    \initialize/step[0] ,
    sys_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

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
input \process[3] ;
input \process[2] ;
input \process[1] ;
input \process[0] ;
input \initialize/step[3] ;
input \initialize/step[2] ;
input \initialize/step[1] ;
input \initialize/step[0] ;
input sys_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

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
wire \process[3] ;
wire \process[2] ;
wire \process[1] ;
wire \process[0] ;
wire \initialize/step[3] ;
wire \initialize/step[2] ;
wire \initialize/step[1] ;
wire \initialize/step[0] ;
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
    .data_i({\read[15] ,\read[14] ,\read[13] ,\read[12] ,\read[11] ,\read[10] ,\read[9] ,\read[8] ,\read[7] ,\read[6] ,\read[5] ,\read[4] ,\read[3] ,\read[2] ,\read[1] ,\read[0] ,\process[3] ,\process[2] ,\process[1] ,\process[0] ,\initialize/step[3] ,\initialize/step[2] ,\initialize/step[1] ,\initialize/step[0] }),
    .clk_i(sys_clk)
);

endmodule
