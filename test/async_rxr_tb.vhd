
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity async_rxr_tb is
  generic (
    runner_cfg : string
  );
end;

architecture tb of async_rxr_tb is

  constant G_DIV_WIDTH : integer := 8; 

  -- Multiplier > 1: rxd is slower -> bit removed every once in a while
  -- Multiplier < 1: rxd is faster -> bit added every once in a while
  constant CLK_PERIOD_TX : time := 8 ns * (0.96);
  constant CLK_PERIOD_RX_1X : time := 8 ns;
  constant CLK_PERIOD_RX_4X : time := 2 ns;
  constant CLK_TO_Q : time := 0.1 ns;

  -- Ports
  signal clk_tx        : std_logic := '1';
  signal clk_rx_1x     : std_logic := '1';
  signal clk_rx_4x     : std_logic := '1';
  signal srst          : std_logic := '1';
  signal rxd           : std_logic := '0';
  signal data          : std_logic_vector(3 downto 0);
  signal valid         : std_logic_vector(3 downto 0);
  signal ce_div : std_logic_vector(G_DIV_WIDTH-1 downto 0);

begin

  ------------------------------------------------------------------------------
  prc_main : process

    -- Helper Procedures
    procedure prd_wait_clk (
      cnt : in positive
    ) is
    begin
      for i in 0 to cnt - 1 loop
        wait until rising_edge(clk_tx);
        wait for CLK_TO_Q;
      end loop;
    end procedure prd_wait_clk;

    procedure prd_rst (
      cnt : in positive
    ) is
    begin
      prd_wait_clk(1);
      srst <= '1';
      prd_wait_clk(cnt);
      srst <= '0';
    end procedure prd_rst;

  begin

    test_runner_setup(runner, runner_cfg);
    while test_suite loop

      prd_rst(16);

      if run("test_0") then

      wait for 100 * CLK_PERIOD_TX;
      
      -- elsif run("test_1") then
      --   info("test_1");
      --   wait for 100 * CLK_PERIOD_TX;
      end if;

      wait for 100 * CLK_PERIOD_TX;
    end loop;

    test_runner_cleanup(runner);
  end process;

  ------------------------------------------------------------------------------
  clk_tx <= not clk_tx after CLK_PERIOD_TX / 2;
  clk_rx_1x <= not clk_rx_1x after CLK_PERIOD_RX_1X / 2;
  clk_rx_4x <= not clk_rx_4x after CLK_PERIOD_RX_4X / 2;

  ------------------------------------------------------------------------------
  dut : entity work.async_rxr
  generic map (
    G_DIV_WIDTH => G_DIV_WIDTH
  )
  port map (
    clk_4x => clk_rx_4x,
    clk_1x => clk_rx_1x,
    ce_div => ce_div,
    rxd => rxd,
    m_data => data,
    m_valid => valid
  );



  ------------------------------------------------------------------------------
  PRBS_inst : entity work.PRBS
  port map (
    TxCLK => clk_tx,
    RXCLK => clk_rx_1x,
    TxDATA => rxd,
    RESET => srst,
    DATA => (others=>'0'),
    DATA_VALID => (others=>'0'),
    ERROR => open
  );


end architecture;