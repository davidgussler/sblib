--#############################################################################
--# File     : reset_gen.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ===========================================================================
--! Reset generator. This generates a reset pulse on startup. Along with that,
--! it also synchronizes several arst sources to a clock and extends the reset 
--! by an extra G_PULSE_LEN cycles. cdc_reset is more general and may be used by
--! itself if startup and reset extension are not needed. cdc_reset also allows
--! you to sync reset sources to several different clocks, whereas this module
--! only allows one clock.
--# ===========================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--#############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_gen is
  generic (
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive range 2 to 16 := 2;
    --! Number of asynchronous reset inputs
    G_NUM_ARST : positive := 1; 
    --! Active logic level of the async reset inputs
    G_ARST_LVL : std_logic_vector(G_NUM_ARST-1 downto 0) := (others=>'1');
    -- Number of extra cycles to pulse the reset for
    G_PULSE_LEN : positive := 16
  );
  port (
    --! Source async resets
    arst : in std_logic_vector(G_NUM_ARST-1 downto 0) := (others =>'0');
    --! Clock for output sync reset
    clk  : in std_logic;
    --! Active high output sync reset
    srst : out std_logic;
    --! Active low output sync reset
    srst_n : out std_logic
  );
end entity;

architecture rtl of reset_gen is

  -- ---------------------------------------------------------------------------
  signal srst_pre : std_logic;
  signal startup_cnt : integer range 0 to 2 := 0;
  signal startup_pulse : std_logic := '1'; 
  signal pulse_cnt : integer range 0 to G_PULSE_LEN - 1 := 0;

begin

  -- ---------------------------------------------------------------------------
  prc_startup_pulse : process (clk) is begin
    if rising_edge(clk) then
      if startup_cnt = 2 then
        startup_pulse <= '0';
      else
        startup_cnt <= startup_cnt + 1;
      end if;
    end if;
  end process;

  -- ---------------------------------------------------------------------------
  u_cdc_reset : entity work.cdc_reset
  generic map (
    G_SYNC_LEN => G_SYNC_LEN,
    G_NUM_ARST => 1 + G_NUM_ARST,
    G_NUM_SRST => 1,
    G_ARST_LVL => '1' & G_ARST_LVL,
    G_SRST_LVL => "1"
  )
  port map (
    src_arst(G_NUM_ARST) => startup_pulse,
    src_arst(G_NUM_ARST-1 downto 0) => arst,
    dst_clk(0)  => clk,
    dst_srst(0) => srst_pre
  );

  -- ---------------------------------------------------------------------------
  prc_reset_extend : process (clk) is
  begin
    if rising_edge(clk) then
      if srst_pre then
        pulse_cnt <= 0;
        srst <= '1';
        srst_n <= '0';
      else
        if pulse_cnt = G_PULSE_LEN - 1 then
          srst <= '0';
          srst_n <= '1';
        else
          pulse_cnt <= pulse_cnt + 1;
        end if;
      end if;
    end if;
  end process;

end architecture;
