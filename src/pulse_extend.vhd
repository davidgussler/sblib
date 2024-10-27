--##############################################################################
--# File     : pulse_extend.vhd
--# Author   : David Gussler - davidnguss@gmail.com
--# Language : VHDL '08
--# ============================================================================
--! Simple pulse extender
--# ============================================================================
--# Copyright (c) 2023-2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity pulse_extend is
  generic (
    --! Active logic level of the pulse
    G_ACT_LVL : std_logic := '1';
    --! Length of the output pulse in clockcycles
    G_PULSE_LEN : positive := 4
  );
  port (
    clk  : in    std_logic;
    srst : in    std_logic;
    din  : in    std_logic;
    dout : out   std_logic
  );
end entity pulse_extend;

architecture rtl of pulse_extend is

  -- ---------------------------------------------------------------------------
  signal cnt : integer range 0 to G_PULSE_LEN - 1;

begin

  -- ---------------------------------------------------------------------------
  process (clk) is begin
    if rising_edge(clk) then
      if srst then
        -- Counter resets the the expired state
        cnt  <= G_PULSE_LEN - 1;
        -- Dout resets the not active state
        dout <= not G_ACT_LVL;
      else
        -- If new pulse at the input, then start the output pulse and clear the
        -- pulse counter
        if din = G_ACT_LVL then
          cnt  <= 0;
          dout <= G_ACT_LVL;
        -- If pulse counter expired, then dont set the output pulse
        elsif cnt = G_PULSE_LEN - 1 then
          dout <= not G_ACT_LVL;
        -- Otherwise, if counter has not expired, then keep incrementing it and
        -- enable the output pulse
        else
          cnt  <= cnt + 1;
          dout <= G_ACT_LVL;
        end if;
      end if;
    end if;
  end process;

end architecture rtl;
