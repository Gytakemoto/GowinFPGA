module gw_gao(
    \adc_out[11] ,
    \adc_out[10] ,
    \adc_out[9] ,
    \adc_out[8] ,
    \adc_out[7] ,
    \adc_out[6] ,
    \adc_out[5] ,
    \adc_out[4] ,
    \adc_out[3] ,
    \adc_out[2] ,
    \adc_out[1] ,
    \adc_out[0] ,
    \adc_submodule/adc_data[11] ,
    \adc_submodule/adc_data[10] ,
    \adc_submodule/adc_data[9] ,
    \adc_submodule/adc_data[8] ,
    \adc_submodule/adc_data[7] ,
    \adc_submodule/adc_data[6] ,
    \adc_submodule/adc_data[5] ,
    \adc_submodule/adc_data[4] ,
    \adc_submodule/adc_data[3] ,
    \adc_submodule/adc_data[2] ,
    \adc_submodule/adc_data[1] ,
    \adc_submodule/adc_data[0] ,
    \adc_submodule/clock_counter[17] ,
    \adc_submodule/clock_counter[16] ,
    \adc_submodule/clock_counter[15] ,
    \adc_submodule/clock_counter[14] ,
    \adc_submodule/clock_counter[13] ,
    \adc_submodule/clock_counter[12] ,
    \adc_submodule/clock_counter[11] ,
    \adc_submodule/clock_counter[10] ,
    \adc_submodule/clock_counter[9] ,
    \adc_submodule/clock_counter[8] ,
    \adc_submodule/clock_counter[7] ,
    \adc_submodule/clock_counter[6] ,
    \adc_submodule/clock_counter[5] ,
    \adc_submodule/clock_counter[4] ,
    \adc_submodule/clock_counter[3] ,
    \adc_submodule/clock_counter[2] ,
    \adc_submodule/clock_counter[1] ,
    \adc_submodule/clock_counter[0] ,
    \adc_submodule/delay_counter[3] ,
    \adc_submodule/delay_counter[2] ,
    \adc_submodule/delay_counter[1] ,
    \adc_submodule/delay_counter[0] ,
    \adc_submodule/data_available ,
    clk_PSRAM,
    tms_pad_i,
    tck_pad_i,
    tdi_pad_i,
    tdo_pad_o
);

input \adc_out[11] ;
input \adc_out[10] ;
input \adc_out[9] ;
input \adc_out[8] ;
input \adc_out[7] ;
input \adc_out[6] ;
input \adc_out[5] ;
input \adc_out[4] ;
input \adc_out[3] ;
input \adc_out[2] ;
input \adc_out[1] ;
input \adc_out[0] ;
input \adc_submodule/adc_data[11] ;
input \adc_submodule/adc_data[10] ;
input \adc_submodule/adc_data[9] ;
input \adc_submodule/adc_data[8] ;
input \adc_submodule/adc_data[7] ;
input \adc_submodule/adc_data[6] ;
input \adc_submodule/adc_data[5] ;
input \adc_submodule/adc_data[4] ;
input \adc_submodule/adc_data[3] ;
input \adc_submodule/adc_data[2] ;
input \adc_submodule/adc_data[1] ;
input \adc_submodule/adc_data[0] ;
input \adc_submodule/clock_counter[17] ;
input \adc_submodule/clock_counter[16] ;
input \adc_submodule/clock_counter[15] ;
input \adc_submodule/clock_counter[14] ;
input \adc_submodule/clock_counter[13] ;
input \adc_submodule/clock_counter[12] ;
input \adc_submodule/clock_counter[11] ;
input \adc_submodule/clock_counter[10] ;
input \adc_submodule/clock_counter[9] ;
input \adc_submodule/clock_counter[8] ;
input \adc_submodule/clock_counter[7] ;
input \adc_submodule/clock_counter[6] ;
input \adc_submodule/clock_counter[5] ;
input \adc_submodule/clock_counter[4] ;
input \adc_submodule/clock_counter[3] ;
input \adc_submodule/clock_counter[2] ;
input \adc_submodule/clock_counter[1] ;
input \adc_submodule/clock_counter[0] ;
input \adc_submodule/delay_counter[3] ;
input \adc_submodule/delay_counter[2] ;
input \adc_submodule/delay_counter[1] ;
input \adc_submodule/delay_counter[0] ;
input \adc_submodule/data_available ;
input clk_PSRAM;
input tms_pad_i;
input tck_pad_i;
input tdi_pad_i;
output tdo_pad_o;

wire \adc_out[11] ;
wire \adc_out[10] ;
wire \adc_out[9] ;
wire \adc_out[8] ;
wire \adc_out[7] ;
wire \adc_out[6] ;
wire \adc_out[5] ;
wire \adc_out[4] ;
wire \adc_out[3] ;
wire \adc_out[2] ;
wire \adc_out[1] ;
wire \adc_out[0] ;
wire \adc_submodule/adc_data[11] ;
wire \adc_submodule/adc_data[10] ;
wire \adc_submodule/adc_data[9] ;
wire \adc_submodule/adc_data[8] ;
wire \adc_submodule/adc_data[7] ;
wire \adc_submodule/adc_data[6] ;
wire \adc_submodule/adc_data[5] ;
wire \adc_submodule/adc_data[4] ;
wire \adc_submodule/adc_data[3] ;
wire \adc_submodule/adc_data[2] ;
wire \adc_submodule/adc_data[1] ;
wire \adc_submodule/adc_data[0] ;
wire \adc_submodule/clock_counter[17] ;
wire \adc_submodule/clock_counter[16] ;
wire \adc_submodule/clock_counter[15] ;
wire \adc_submodule/clock_counter[14] ;
wire \adc_submodule/clock_counter[13] ;
wire \adc_submodule/clock_counter[12] ;
wire \adc_submodule/clock_counter[11] ;
wire \adc_submodule/clock_counter[10] ;
wire \adc_submodule/clock_counter[9] ;
wire \adc_submodule/clock_counter[8] ;
wire \adc_submodule/clock_counter[7] ;
wire \adc_submodule/clock_counter[6] ;
wire \adc_submodule/clock_counter[5] ;
wire \adc_submodule/clock_counter[4] ;
wire \adc_submodule/clock_counter[3] ;
wire \adc_submodule/clock_counter[2] ;
wire \adc_submodule/clock_counter[1] ;
wire \adc_submodule/clock_counter[0] ;
wire \adc_submodule/delay_counter[3] ;
wire \adc_submodule/delay_counter[2] ;
wire \adc_submodule/delay_counter[1] ;
wire \adc_submodule/delay_counter[0] ;
wire \adc_submodule/data_available ;
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
    .data_i({\adc_out[11] ,\adc_out[10] ,\adc_out[9] ,\adc_out[8] ,\adc_out[7] ,\adc_out[6] ,\adc_out[5] ,\adc_out[4] ,\adc_out[3] ,\adc_out[2] ,\adc_out[1] ,\adc_out[0] ,\adc_submodule/adc_data[11] ,\adc_submodule/adc_data[10] ,\adc_submodule/adc_data[9] ,\adc_submodule/adc_data[8] ,\adc_submodule/adc_data[7] ,\adc_submodule/adc_data[6] ,\adc_submodule/adc_data[5] ,\adc_submodule/adc_data[4] ,\adc_submodule/adc_data[3] ,\adc_submodule/adc_data[2] ,\adc_submodule/adc_data[1] ,\adc_submodule/adc_data[0] ,\adc_submodule/clock_counter[17] ,\adc_submodule/clock_counter[16] ,\adc_submodule/clock_counter[15] ,\adc_submodule/clock_counter[14] ,\adc_submodule/clock_counter[13] ,\adc_submodule/clock_counter[12] ,\adc_submodule/clock_counter[11] ,\adc_submodule/clock_counter[10] ,\adc_submodule/clock_counter[9] ,\adc_submodule/clock_counter[8] ,\adc_submodule/clock_counter[7] ,\adc_submodule/clock_counter[6] ,\adc_submodule/clock_counter[5] ,\adc_submodule/clock_counter[4] ,\adc_submodule/clock_counter[3] ,\adc_submodule/clock_counter[2] ,\adc_submodule/clock_counter[1] ,\adc_submodule/clock_counter[0] ,\adc_submodule/delay_counter[3] ,\adc_submodule/delay_counter[2] ,\adc_submodule/delay_counter[1] ,\adc_submodule/delay_counter[0] ,\adc_submodule/data_available }),
    .clk_i(clk_PSRAM)
);

endmodule
