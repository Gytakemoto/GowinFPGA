module gw_gao(
    \memory/clk ,
    \memory/mem_sio[3] ,
    \memory/mem_sio[2] ,
    \memory/mem_sio[1] ,
    \memory/mem_sio[0] ,
    \memory/mem_ce_n ,
    mem_ready,
    \step[3] ,
    \step[2] ,
    \step[1] ,
    \step[0] ,
    read_strb,
    write_strb,
    \memory/mem_driver/ready ,
    \memory/mem_driver/data_write[15] ,
    \memory/mem_driver/data_write[14] ,
    \memory/mem_driver/data_write[13] ,
    \memory/mem_driver/data_write[12] ,
    \memory/mem_driver/data_write[11] ,
    \memory/mem_driver/data_write[10] ,
    \memory/mem_driver/data_write[9] ,
    \memory/mem_driver/data_write[8] ,
    \memory/mem_driver/data_write[7] ,
    \memory/mem_driver/data_write[6] ,
    \memory/mem_driver/data_write[5] ,
    \memory/mem_driver/data_write[4] ,
    \memory/mem_driver/data_write[3] ,
    \memory/mem_driver/data_write[2] ,
    \memory/mem_driver/data_write[1] ,
    \memory/mem_driver/data_write[0] ,
    \memory/mem_driver/counter[4] ,
    \memory/mem_driver/counter[3] ,
    \memory/mem_driver/counter[2] ,
    \memory/mem_driver/counter[1] ,
    \memory/mem_driver/counter[0] ,
    \memory/mem_driver/data_out[15] ,
    \memory/mem_driver/data_out[14] ,
    \memory/mem_driver/data_out[13] ,
    \memory/mem_driver/data_out[12] ,
    \memory/mem_driver/data_out[11] ,
    \memory/mem_driver/data_out[10] ,
    \memory/mem_driver/data_out[9] ,
    \memory/mem_driver/data_out[8] ,
    \memory/mem_driver/data_out[7] ,
    \memory/mem_driver/data_out[6] ,
    \memory/mem_driver/data_out[5] ,
    \memory/mem_driver/data_out[4] ,
    \memory/mem_driver/data_out[3] ,
    \memory/mem_driver/data_out[2] ,
    \memory/mem_driver/data_out[1] ,
    \memory/mem_driver/data_out[0] ,
    \memory/initializing ,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \memory/clk ;
input \memory/mem_sio[3] ;
input \memory/mem_sio[2] ;
input \memory/mem_sio[1] ;
input \memory/mem_sio[0] ;
input \memory/mem_ce_n ;
input mem_ready;
input \step[3] ;
input \step[2] ;
input \step[1] ;
input \step[0] ;
input read_strb;
input write_strb;
input \memory/mem_driver/ready ;
input \memory/mem_driver/data_write[15] ;
input \memory/mem_driver/data_write[14] ;
input \memory/mem_driver/data_write[13] ;
input \memory/mem_driver/data_write[12] ;
input \memory/mem_driver/data_write[11] ;
input \memory/mem_driver/data_write[10] ;
input \memory/mem_driver/data_write[9] ;
input \memory/mem_driver/data_write[8] ;
input \memory/mem_driver/data_write[7] ;
input \memory/mem_driver/data_write[6] ;
input \memory/mem_driver/data_write[5] ;
input \memory/mem_driver/data_write[4] ;
input \memory/mem_driver/data_write[3] ;
input \memory/mem_driver/data_write[2] ;
input \memory/mem_driver/data_write[1] ;
input \memory/mem_driver/data_write[0] ;
input \memory/mem_driver/counter[4] ;
input \memory/mem_driver/counter[3] ;
input \memory/mem_driver/counter[2] ;
input \memory/mem_driver/counter[1] ;
input \memory/mem_driver/counter[0] ;
input \memory/mem_driver/data_out[15] ;
input \memory/mem_driver/data_out[14] ;
input \memory/mem_driver/data_out[13] ;
input \memory/mem_driver/data_out[12] ;
input \memory/mem_driver/data_out[11] ;
input \memory/mem_driver/data_out[10] ;
input \memory/mem_driver/data_out[9] ;
input \memory/mem_driver/data_out[8] ;
input \memory/mem_driver/data_out[7] ;
input \memory/mem_driver/data_out[6] ;
input \memory/mem_driver/data_out[5] ;
input \memory/mem_driver/data_out[4] ;
input \memory/mem_driver/data_out[3] ;
input \memory/mem_driver/data_out[2] ;
input \memory/mem_driver/data_out[1] ;
input \memory/mem_driver/data_out[0] ;
input \memory/initializing ;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \memory/clk ;
wire \memory/mem_sio[3] ;
wire \memory/mem_sio[2] ;
wire \memory/mem_sio[1] ;
wire \memory/mem_sio[0] ;
wire \memory/mem_ce_n ;
wire mem_ready;
wire \step[3] ;
wire \step[2] ;
wire \step[1] ;
wire \step[0] ;
wire read_strb;
wire write_strb;
wire \memory/mem_driver/ready ;
wire \memory/mem_driver/data_write[15] ;
wire \memory/mem_driver/data_write[14] ;
wire \memory/mem_driver/data_write[13] ;
wire \memory/mem_driver/data_write[12] ;
wire \memory/mem_driver/data_write[11] ;
wire \memory/mem_driver/data_write[10] ;
wire \memory/mem_driver/data_write[9] ;
wire \memory/mem_driver/data_write[8] ;
wire \memory/mem_driver/data_write[7] ;
wire \memory/mem_driver/data_write[6] ;
wire \memory/mem_driver/data_write[5] ;
wire \memory/mem_driver/data_write[4] ;
wire \memory/mem_driver/data_write[3] ;
wire \memory/mem_driver/data_write[2] ;
wire \memory/mem_driver/data_write[1] ;
wire \memory/mem_driver/data_write[0] ;
wire \memory/mem_driver/counter[4] ;
wire \memory/mem_driver/counter[3] ;
wire \memory/mem_driver/counter[2] ;
wire \memory/mem_driver/counter[1] ;
wire \memory/mem_driver/counter[0] ;
wire \memory/mem_driver/data_out[15] ;
wire \memory/mem_driver/data_out[14] ;
wire \memory/mem_driver/data_out[13] ;
wire \memory/mem_driver/data_out[12] ;
wire \memory/mem_driver/data_out[11] ;
wire \memory/mem_driver/data_out[10] ;
wire \memory/mem_driver/data_out[9] ;
wire \memory/mem_driver/data_out[8] ;
wire \memory/mem_driver/data_out[7] ;
wire \memory/mem_driver/data_out[6] ;
wire \memory/mem_driver/data_out[5] ;
wire \memory/mem_driver/data_out[4] ;
wire \memory/mem_driver/data_out[3] ;
wire \memory/mem_driver/data_out[2] ;
wire \memory/mem_driver/data_out[1] ;
wire \memory/mem_driver/data_out[0] ;
wire \memory/initializing ;
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

ao_top_0  u_la0_top(
    .control(control0[9:0]),
    .trig0_i(\memory/initializing ),
    .data_i({\memory/clk ,\memory/mem_sio[3] ,\memory/mem_sio[2] ,\memory/mem_sio[1] ,\memory/mem_sio[0] ,\memory/mem_ce_n ,mem_ready,\step[3] ,\step[2] ,\step[1] ,\step[0] ,read_strb,write_strb,\memory/mem_driver/ready ,\memory/mem_driver/data_write[15] ,\memory/mem_driver/data_write[14] ,\memory/mem_driver/data_write[13] ,\memory/mem_driver/data_write[12] ,\memory/mem_driver/data_write[11] ,\memory/mem_driver/data_write[10] ,\memory/mem_driver/data_write[9] ,\memory/mem_driver/data_write[8] ,\memory/mem_driver/data_write[7] ,\memory/mem_driver/data_write[6] ,\memory/mem_driver/data_write[5] ,\memory/mem_driver/data_write[4] ,\memory/mem_driver/data_write[3] ,\memory/mem_driver/data_write[2] ,\memory/mem_driver/data_write[1] ,\memory/mem_driver/data_write[0] ,\memory/mem_driver/counter[4] ,\memory/mem_driver/counter[3] ,\memory/mem_driver/counter[2] ,\memory/mem_driver/counter[1] ,\memory/mem_driver/counter[0] ,\memory/mem_driver/data_out[15] ,\memory/mem_driver/data_out[14] ,\memory/mem_driver/data_out[13] ,\memory/mem_driver/data_out[12] ,\memory/mem_driver/data_out[11] ,\memory/mem_driver/data_out[10] ,\memory/mem_driver/data_out[9] ,\memory/mem_driver/data_out[8] ,\memory/mem_driver/data_out[7] ,\memory/mem_driver/data_out[6] ,\memory/mem_driver/data_out[5] ,\memory/mem_driver/data_out[4] ,\memory/mem_driver/data_out[3] ,\memory/mem_driver/data_out[2] ,\memory/mem_driver/data_out[1] ,\memory/mem_driver/data_out[0] }),
    .clk_i(\memory/clk )
);

endmodule
