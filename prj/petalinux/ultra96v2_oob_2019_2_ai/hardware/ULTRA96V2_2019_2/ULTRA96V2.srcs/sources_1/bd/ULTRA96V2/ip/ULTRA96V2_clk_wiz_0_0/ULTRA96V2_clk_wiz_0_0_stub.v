// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Fri Jan 31 12:24:48 2020
// Host        : ubuv1804 running 64-bit Ubuntu 18.04 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/training/git/avnet/hdl/Projects/ultra96v2_oob/ULTRA96V2_2019_2/ULTRA96V2.srcs/sources_1/bd/ULTRA96V2/ip/ULTRA96V2_clk_wiz_0_0/ULTRA96V2_clk_wiz_0_0_stub.v
// Design      : ULTRA96V2_clk_wiz_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu3eg-sbva484-1-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module ULTRA96V2_clk_wiz_0_0(clk_out1, clk_out2, clk_out3, clk_out4, clk_out5, 
  clk_out6, clk_out7, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7,resetn,locked,clk_in1" */;
  output clk_out1;
  output clk_out2;
  output clk_out3;
  output clk_out4;
  output clk_out5;
  output clk_out6;
  output clk_out7;
  input resetn;
  output locked;
  input clk_in1;
endmodule
