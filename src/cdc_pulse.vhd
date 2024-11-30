--##############################################################################
--# File     : cdc_pulse.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! Simple pulse synchronizer. This can be used to sync one or several
--! unrelated single-cycle pulses across clock domains. src_pulse can be
--! many src_clk cycles long, and dst_pulse will always be one dst_clk cycle 
--! long. 
--# ============================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity cdc_pulse is
  generic (
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive range 2 to 16 := 2;
    --! Number of unrelated pulses to synchronize
    G_WIDTH : positive := 1
  );
  port (
    src_clk   : in std_logic;
    src_pulse : in std_logic_vector(G_WIDTH - 1 downto 0);
    dst_clk   : in std_logic;
    dst_pulse : out std_logic_vector(G_WIDTH - 1 downto 0) := (others=>'0')
  );
end entity cdc_pulse;

architecture rtl of cdc_pulse is

  -- ---------------------------------------------------------------------------
  signal toggl         : std_logic_vector(src_pulse'range) := (others=>'0');
  signal src_pulse_ff  : std_logic_vector(src_pulse'range) := (others=>'0');
  signal toggl_sync    : std_logic_vector(src_pulse'range) := (others=>'0');
  signal toggl_sync_ff : std_logic_vector(src_pulse'range) := (others=>'0');

begin

  -- ---------------------------------------------------------------------------
  prc_toggle : process (src_clk) begin
    if rising_edge(src_clk) then

      src_pulse_ff <= src_pulse;

      for i in toggl'range loop
        if src_pulse(i) and not src_pulse_ff(i) then 
          toggl(i) <= not toggl(i);
        end if;
      end loop;

    end if; 
  end process;

  -- ---------------------------------------------------------------------------
  u_cdc_bit_0: entity work.cdc_bit
  generic map(
    G_USE_SRC_CLK => false,
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH => G_WIDTH
  )
  port map(
    src_bit => toggl,
    dst_clk => dst_clk,
    dst_bit => toggl_sync
  );

  -- ---------------------------------------------------------------------------
  prc_pulse : process (dst_clk) begin
    if rising_edge(dst_clk) then
      toggl_sync_ff <= toggl_sync;
      dst_pulse <= toggl_sync xor toggl_sync_ff; 
    end if; 
  end process;

end architecture;
