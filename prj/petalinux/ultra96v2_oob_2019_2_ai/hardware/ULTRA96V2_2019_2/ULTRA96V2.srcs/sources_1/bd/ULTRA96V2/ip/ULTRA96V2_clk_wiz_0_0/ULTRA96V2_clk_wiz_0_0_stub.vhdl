-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
-- Date        : Fri Jan 31 12:24:48 2020
-- Host        : ubuv1804 running 64-bit Ubuntu 18.04 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/training/git/avnet/hdl/Projects/ultra96v2_oob/ULTRA96V2_2019_2/ULTRA96V2.srcs/sources_1/bd/ULTRA96V2/ip/ULTRA96V2_clk_wiz_0_0/ULTRA96V2_clk_wiz_0_0_stub.vhdl
-- Design      : ULTRA96V2_clk_wiz_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu3eg-sbva484-1-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ULTRA96V2_clk_wiz_0_0 is
  Port ( 
    clk_out1 : out STD_LOGIC;
    clk_out2 : out STD_LOGIC;
    clk_out3 : out STD_LOGIC;
    clk_out4 : out STD_LOGIC;
    clk_out5 : out STD_LOGIC;
    clk_out6 : out STD_LOGIC;
    clk_out7 : out STD_LOGIC;
    resetn : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end ULTRA96V2_clk_wiz_0_0;

architecture stub of ULTRA96V2_clk_wiz_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,clk_out2,clk_out3,clk_out4,clk_out5,clk_out6,clk_out7,resetn,locked,clk_in1";
begin
end;
