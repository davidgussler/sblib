--#############################################################################
--# File     : cdc_reset.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ===========================================================================
--! Reset synchronizer. If any one of the async reset inputs match the reset 
--! level, then all of the synchronous resets are asserted. It is common to 
--! have several async reset sources, such as an external cca reset, an 
--! mmcm_locked signal, and a software register reset. This module ORs all of 
--! these sources together and asserts all of the reset outputs when one of
--! the async sources is asserted. There is an option to have several sync 
--! reset outputs because it is common to need both an active high and active
--! low reset. It is also common for reset signals to have a high fanout, 
--! so having multiple reset signals driven by multiple flip-flops can decrease
--! the fanout. There also may be different sync resets for multiple clock
--! domains.
--# ===========================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--#############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cdc_reset is
  generic (
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive range 2 to 16 := 2;
    --! Number of asynchronous reset inputs
    G_NUM_ARST : positive := 1; 
    --! Number of synchronous reset outputs
    G_NUM_SRST : positive := 1; 
    --! Active logic level of the async inputs
    G_ARST_LVL : std_logic_vector(G_NUM_ARST-1 downto 0) := (others=>'1');
    --! Active logic level of the sync outputs
    G_SRST_LVL : std_logic_vector(G_NUM_SRST-1 downto 0) := (others=>'1')
  );
  port (
    --! Source async resets
    src_arst : in std_logic_vector(G_NUM_ARST-1 downto 0);
    --! Clocks for output sync resets
    dst_clk  : in std_logic_vector(G_NUM_SRST-1 downto 0);
    --! Output sync resets
    dst_srst : out std_logic_vector(G_NUM_SRST-1 downto 0) 
  );
end entity;

architecture rtl of cdc_reset is

  -- ---------------------------------------------------------------------------
  type sr_t is array (natural range 0 to G_NUM_SRST-1) of 
    std_logic_vector(G_SYNC_LEN-1 downto 0);
  
  -- ---------------------------------------------------------------------------
  signal sr                    : sr_t;
  signal unique_net_false_path : std_logic;

  -- ---------------------------------------------------------------------------
  attribute async_reg                           : string;
  attribute async_reg of sr                     : signal is "TRUE";
  attribute shreg_extract                       : string;
  attribute shreg_extract of sr                 : signal is "NO";
  attribute dont_touch                          : string;
  attribute dont_touch of unique_net_false_path : signal is "TRUE";

  -- ---------------------------------------------------------------------------
  -- Returns '1' if any of the async reset bits are asserted, otherwise '0'
  function fn_arst (
    arst_slv : std_logic_vector;
    arst_lvl : std_logic_vector
  )
    return std_logic
  is
    variable tmp : std_logic_vector(arst_slv'length-1 downto 0) := (others=>'0');
  begin
    for i in 0 to arst_slv'length-1 loop
      tmp(i) := '1' when arst_slv(i) = arst_lvl(i) else '0'; 
    end loop;
    return or tmp;
  end function;

begin

  unique_net_false_path <= fn_arst(src_arst, G_ARST_LVL);

  -- ---------------------------------------------------------------------------
  gen_arst : for idx in 0 to G_NUM_SRST-1 generate

    prc_rst_sync : process (dst_clk(idx), unique_net_false_path) begin
      if unique_net_false_path then
        for sr_bit in 0 to G_SYNC_LEN-1 loop
          sr(idx)(sr_bit) <= G_SRST_LVL(idx);
        end loop;
      elsif rising_edge(dst_clk(idx)) then
        sr(idx)(0) <= not G_SRST_LVL(idx); 
        for sr_bit in 1 to G_SYNC_LEN-1 loop
          sr(idx)(sr_bit) <= sr(idx)(sr_bit-1);
        end loop;
      end if;
    end process;

    dst_srst(idx) <= sr(idx)(G_SYNC_LEN-1);
  
  end generate;

end architecture;
