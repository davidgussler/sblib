
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cdc_reset_tb is
end;

architecture bench of cdc_reset_tb is
  -- Clock period
  constant clk0_period : time := 5 ns;
  constant clk1_period : time := 2 ns;
  -- Generics
  -- Ports
  signal arst : std_logic := '1';
  signal clk0 : std_logic := '0';
  signal clk1 : std_logic := '0';
  signal srst0 : std_logic;
  signal srst1 : std_logic;
begin

  u_cdc_reset_0 : entity work.cdc_reset
  generic map (
    G_SYNC_LEN    => 8,
    G_NUM_ARST    => 3,
    G_NUM_SRST    => 2,
    G_ARST_LVL(0) => '0',
    G_ARST_LVL(1) => '1',
    G_ARST_LVL(2) => '1',
    G_SRST_LVL(0) => '1',
    G_SRST_LVL(1) => '1'
  )
  port map (
    i_arst(0) => '1',
    i_arst(1) => arst,
    i_arst(2) => '0',
    i_clk(0)  => clk0,
    i_clk(1)  => clk1,
    o_srst(0) => srst0,
    o_srst(1) => srst1
  );

  clk0 <= not clk0 after clk0_period / 2;
  clk1 <= not clk1 after clk1_period / 2;
  arst <= '1', '0' after 1 us; 

end;