--##############################################################################
--# File     : cdc_pulse.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! Simple pulse synchronizer. This can be used to sync one or several
--! unrelated pulses accross clocks. Syncs a single-cycle pulse accross clock
--! domains.
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
    G_WIDTH : positive := 1;
    --! Active logic level of the pulse
    G_ACT_LVL : std_logic_vector(G_WIDTH - 1 downto 0) := (others=> '1')
  );
  port (
    src_clk : in std_logic;
    src_srst : in std_logic;
    src_pulse : in std_logic_vector(G_WIDTH - 1 downto 0);
    dst_clk : in std_logic;
    dst_srst : in std_logic;
    dst_pulse : out std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity cdc_pulse;

architecture rtl of cdc_pulse is

  -- ---------------------------------------------------------------------------
  constant RST_VAL : std_logic_vector(G_WIDTH - 1 downto 0) := not G_ACT_LVL;

  -- ---------------------------------------------------------------------------
  signal toggl    : std_logic_vector(G_WIDTH - 1 downto 0); 
  signal toggl_sync    : std_logic_vector(G_WIDTH - 1 downto 0); 
  signal toggl_sync_ff    : std_logic_vector(G_WIDTH - 1 downto 0); 

begin

  -- ---------------------------------------------------------------------------
  prc_toggle : process (src_clk) begin
    if rising_edge(src_clk) then
      if src_srst then
        toggl <= RST_VAL; 
      else
        for i in toggl'range loop
          if (src_pulse(i) = G_ACT_LVL(i)) then 
            toggl(i) <= not toggl(i);
          end if;
        end loop;
      end if;
    end if; 
  end process;

  -- ---------------------------------------------------------------------------
  u_cdc_bit_0: entity work.cdc_bit
  generic map(
    G_USE_SRC_CLK => false,
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH => G_WIDTH,
    G_RST_VAL => RST_VAL
  )
  port map(
    src_clk => src_clk,
    src_srst => src_srst,
    src_bit => toggl,
    dst_clk => dst_clk,
    dst_srst => dst_srst,
    dst_bit => toggl_sync
  );

  -- ---------------------------------------------------------------------------
  prc_pulse : process (dst_clk) begin
    if rising_edge(dst_clk) then
      if dst_srst then
        toggl_sync_ff <= RST_VAL; 
        dst_pulse <= RST_VAL; 
      else
        toggl_sync_ff <= toggl_sync; 
        dst_pulse <= toggl_sync xor toggl_sync_ff; 
      end if;
    end if; 
  end process;

end architecture;
