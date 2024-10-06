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
    \data_out[15] ,
    \data_out[14] ,
    \data_out[13] ,
    \data_out[12] ,
    \data_out[11] ,
    \data_out[10] ,
    \data_out[9] ,
    \data_out[8] ,
    \data_out[7] ,
    \data_out[6] ,
    \data_out[5] ,
    \data_out[4] ,
    \data_out[3] ,
    \data_out[2] ,
    \data_out[1] ,
    \data_out[0] ,
    debug,
    \initialize/PSRAM_com/debug ,
    \read_write[1] ,
    \read_write[0] ,
    \UART1/debug ,
    \process[3] ,
    \process[2] ,
    \process[1] ,
    \process[0] ,
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
input \data_out[15] ;
input \data_out[14] ;
input \data_out[13] ;
input \data_out[12] ;
input \data_out[11] ;
input \data_out[10] ;
input \data_out[9] ;
input \data_out[8] ;
input \data_out[7] ;
input \data_out[6] ;
input \data_out[5] ;
input \data_out[4] ;
input \data_out[3] ;
input \data_out[2] ;
input \data_out[1] ;
input \data_out[0] ;
input debug;
input \initialize/PSRAM_com/debug ;
input \read_write[1] ;
input \read_write[0] ;
input \UART1/debug ;
input \process[3] ;
input \process[2] ;
input \process[1] ;
input \process[0] ;
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
wire \data_out[15] ;
wire \data_out[14] ;
wire \data_out[13] ;
wire \data_out[12] ;
wire \data_out[11] ;
wire \data_out[10] ;
wire \data_out[9] ;
wire \data_out[8] ;
wire \data_out[7] ;
wire \data_out[6] ;
wire \data_out[5] ;
wire \data_out[4] ;
wire \data_out[3] ;
wire \data_out[2] ;
wire \data_out[1] ;
wire \data_out[0] ;
wire debug;
wire \initialize/PSRAM_com/debug ;
wire \read_write[1] ;
wire \read_write[0] ;
wire \UART1/debug ;
wire \process[3] ;
wire \process[2] ;
wire \process[1] ;
wire \process[0] ;
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
    .data_i({\address[22] ,\address[21] ,\address[20] ,\address[19] ,\address[18] ,\address[17] ,\address[16] ,\address[15] ,\address[14] ,\address[13] ,\address[12] ,\address[11] ,\address[10] ,\address[9] ,\address[8] ,\address[7] ,\address[6] ,\address[5] ,\address[4] ,\address[3] ,\address[2] ,\address[1] ,\address[0] ,\data_out[15] ,\data_out[14] ,\data_out[13] ,\data_out[12] ,\data_out[11] ,\data_out[10] ,\data_out[9] ,\data_out[8] ,\data_out[7] ,\data_out[6] ,\data_out[5] ,\data_out[4] ,\data_out[3] ,\data_out[2] ,\data_out[1] ,\data_out[0] ,debug,\initialize/PSRAM_com/debug ,\read_write[1] ,\read_write[0] ,\UART1/debug ,\process[3] ,\process[2] ,\process[1] ,\process[0] }),
    .clk_i(sys_clk)
);

endmodule
