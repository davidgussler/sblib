--##############################################################################
--# File     : pulse_startup.vhd
--# Author   : David Gussler - davidnguss@gmail.com
--# Language : VHDL '08
--# ============================================================================
--! Startup pulse generator. This is only synthesizable in an FPGA. Can be fed
--! into the input of cdc_reset.vhd to generate several synchronous reset pulses
--! at fpga startup. 
--# ============================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity pulse_startup is
  generic (
    --! Active logic level of the pulse
    G_ACT_LVL : std_logic := '1';
    --! Length of the output pulse in clockcycles
    G_PULSE_LEN : positive := 4
  );
  port (
    clk   : in    std_logic;
    pulse : out   std_logic := G_ACT_LVL
  );
end entity pulse_startup;

architecture rtl of pulse_startup is

  -- ---------------------------------------------------------------------------
  signal cnt : integer range 0 to G_PULSE_LEN-1 := 0;

begin

  -- ---------------------------------------------------------------------------
  prc_pulse : process (clk) is begin
    if rising_edge(clk) then
      if cnt = G_PULSE_LEN-1 then
        pulse <= not G_ACT_LVL;
      else
        cnt  <= cnt + 1;
        pulse <= G_ACT_LVL;
      end if;
    end if;
  end process;

end architecture rtl;
