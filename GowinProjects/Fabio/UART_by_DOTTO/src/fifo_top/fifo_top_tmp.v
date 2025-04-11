//Copyright (C)2014-2022 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.8.06-1
//Part Number: GW1NZ-LV1QN48C6/I5
//Device: GW1NZ-1
//Created Time: Tue Aug 16 10:27:26 2022

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	fifo_top your_instance_name(
		.Data(Data_i), //input [23:0] Data
		.Reset(Reset_i), //input Reset
		.WrClk(WrClk_i), //input WrClk
		.RdClk(RdClk_i), //input RdClk
		.WrEn(WrEn_i), //input WrEn
		.RdEn(RdEn_i), //input RdEn
		.Q(Q_o), //output [23:0] Q
		.Empty(Empty_o), //output Empty
		.Full(Full_o) //output Full
	);

//--------Copy end-------------------
