
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

  constant NUM_XACTIONS : integer := 100;

  -- Clock period
  constant CLK_PERIOD_TX : time := 8*2 ns * (0.95); -- Transmitter is 5% too fast 
  constant CLK_PERIOD_RX : time := 2 ns;
  constant CLK_TO_Q : time := 0.1 ns;

  -- Ports
  signal clk_tx        : std_logic := '1';
  signal clk_rx        : std_logic := '1';
  signal srst          : std_logic := '1';
  signal rxd           : std_logic := '0';
  signal data : std_logic;
  signal valid : std_logic;

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
  clk_rx <= not clk_rx after CLK_PERIOD_RX / 2;

  ------------------------------------------------------------------------------
  dru_inst : entity work.async_rxvr
  generic map (
    G_DIV_WIDTH => 8
  )
  port map (
    clk => clk_rx,
    rxd => rxd,
    m_data => data,
    m_valid => valid
  );

  dut : entity work.async_rxvr
  generic map (
    G_DIV_WIDTH => G_DIV_WIDTH
  )
  port map (
    clk     => clk_rx,
    ce_div  => ce_div,
    rxd     => rxd,
    m_data  => data,
    m_valid => valid
  );



  ------------------------------------------------------------------------------
  PRBS_inst : entity work.PRBS
  port map (
    TxCLK => clk_tx,
    RXCLK => clk_rx,
    TxDATA => rxd,
    RESET => srst,
    DATA => (others=>'0'),
    DATA_VALID => (others=>'0'),
    ERROR => open
  );


end architecture;