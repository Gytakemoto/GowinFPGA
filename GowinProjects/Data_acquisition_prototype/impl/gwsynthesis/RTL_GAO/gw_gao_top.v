module gw_gao(
    \address_acq[22] ,
    \address_acq[21] ,
    \address_acq[20] ,
    \address_acq[19] ,
    \address_acq[18] ,
    \address_acq[17] ,
    \address_acq[16] ,
    \address_acq[15] ,
    \address_acq[14] ,
    \address_acq[13] ,
    \address_acq[12] ,
    \address_acq[11] ,
    \address_acq[10] ,
    \address_acq[9] ,
    \address_acq[8] ,
    \address_acq[7] ,
    \address_acq[6] ,
    \address_acq[5] ,
    \address_acq[4] ,
    \address_acq[3] ,
    \address_acq[2] ,
    \address_acq[1] ,
    \address_acq[0] ,
    \i_pivot[21] ,
    \i_pivot[20] ,
    \i_pivot[19] ,
    \i_pivot[18] ,
    \i_pivot[17] ,
    \i_pivot[16] ,
    \i_pivot[15] ,
    \i_pivot[14] ,
    \i_pivot[13] ,
    \i_pivot[12] ,
    \i_pivot[11] ,
    \i_pivot[10] ,
    \i_pivot[9] ,
    \i_pivot[8] ,
    \i_pivot[7] ,
    \i_pivot[6] ,
    \i_pivot[5] ,
    \i_pivot[4] ,
    \i_pivot[3] ,
    \i_pivot[2] ,
    \i_pivot[1] ,
    \i_pivot[0] ,
    sys_clk,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \address_acq[22] ;
input \address_acq[21] ;
input \address_acq[20] ;
input \address_acq[19] ;
input \address_acq[18] ;
input \address_acq[17] ;
input \address_acq[16] ;
input \address_acq[15] ;
input \address_acq[14] ;
input \address_acq[13] ;
input \address_acq[12] ;
input \address_acq[11] ;
input \address_acq[10] ;
input \address_acq[9] ;
input \address_acq[8] ;
input \address_acq[7] ;
input \address_acq[6] ;
input \address_acq[5] ;
input \address_acq[4] ;
input \address_acq[3] ;
input \address_acq[2] ;
input \address_acq[1] ;
input \address_acq[0] ;
input \i_pivot[21] ;
input \i_pivot[20] ;
input \i_pivot[19] ;
input \i_pivot[18] ;
input \i_pivot[17] ;
input \i_pivot[16] ;
input \i_pivot[15] ;
input \i_pivot[14] ;
input \i_pivot[13] ;
input \i_pivot[12] ;
input \i_pivot[11] ;
input \i_pivot[10] ;
input \i_pivot[9] ;
input \i_pivot[8] ;
input \i_pivot[7] ;
input \i_pivot[6] ;
input \i_pivot[5] ;
input \i_pivot[4] ;
input \i_pivot[3] ;
input \i_pivot[2] ;
input \i_pivot[1] ;
input \i_pivot[0] ;
input sys_clk;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \address_acq[22] ;
wire \address_acq[21] ;
wire \address_acq[20] ;
wire \address_acq[19] ;
wire \address_acq[18] ;
wire \address_acq[17] ;
wire \address_acq[16] ;
wire \address_acq[15] ;
wire \address_acq[14] ;
wire \address_acq[13] ;
wire \address_acq[12] ;
wire \address_acq[11] ;
wire \address_acq[10] ;
wire \address_acq[9] ;
wire \address_acq[8] ;
wire \address_acq[7] ;
wire \address_acq[6] ;
wire \address_acq[5] ;
wire \address_acq[4] ;
wire \address_acq[3] ;
wire \address_acq[2] ;
wire \address_acq[1] ;
wire \address_acq[0] ;
wire \i_pivot[21] ;
wire \i_pivot[20] ;
wire \i_pivot[19] ;
wire \i_pivot[18] ;
wire \i_pivot[17] ;
wire \i_pivot[16] ;
wire \i_pivot[15] ;
wire \i_pivot[14] ;
wire \i_pivot[13] ;
wire \i_pivot[12] ;
wire \i_pivot[11] ;
wire \i_pivot[10] ;
wire \i_pivot[9] ;
wire \i_pivot[8] ;
wire \i_pivot[7] ;
wire \i_pivot[6] ;
wire \i_pivot[5] ;
wire \i_pivot[4] ;
wire \i_pivot[3] ;
wire \i_pivot[2] ;
wire \i_pivot[1] ;
wire \i_pivot[0] ;
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
    .data_i({\address_acq[22] ,\address_acq[21] ,\address_acq[20] ,\address_acq[19] ,\address_acq[18] ,\address_acq[17] ,\address_acq[16] ,\address_acq[15] ,\address_acq[14] ,\address_acq[13] ,\address_acq[12] ,\address_acq[11] ,\address_acq[10] ,\address_acq[9] ,\address_acq[8] ,\address_acq[7] ,\address_acq[6] ,\address_acq[5] ,\address_acq[4] ,\address_acq[3] ,\address_acq[2] ,\address_acq[1] ,\address_acq[0] ,\i_pivot[21] ,\i_pivot[20] ,\i_pivot[19] ,\i_pivot[18] ,\i_pivot[17] ,\i_pivot[16] ,\i_pivot[15] ,\i_pivot[14] ,\i_pivot[13] ,\i_pivot[12] ,\i_pivot[11] ,\i_pivot[10] ,\i_pivot[9] ,\i_pivot[8] ,\i_pivot[7] ,\i_pivot[6] ,\i_pivot[5] ,\i_pivot[4] ,\i_pivot[3] ,\i_pivot[2] ,\i_pivot[1] ,\i_pivot[0] }),
    .clk_i(sys_clk)
);

endmodule
