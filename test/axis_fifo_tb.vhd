
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity axis_fifo_tb is
  generic (
    runner_cfg : string
  );
end;

architecture bench of axis_fifo_tb is

  constant NUM_XACTIONS : integer := 100;

  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  constant CLK_TO_Q : time := 1 ns; 
  -- Generics
  constant G_WIDTH         : positive := 32;
  constant G_DEPTH_P2      : positive := 10;
  constant G_ALM_EMPTY_LVL : natural  := 4;
  constant G_ALM_FULL_LVL  : natural  := 1020;
  -- Ports
  signal clk           : std_logic := '1';
  signal srst          : std_logic := '1';
  signal srst_n        : std_logic := '0';
  signal s_valid       : std_logic;
  signal s_ready       : std_logic;
  signal s_data        : std_logic_vector(G_WIDTH - 1 downto 0);
  signal m_valid       : std_logic;
  signal m_ready       : std_logic;
  signal m_data        : std_logic_vector(G_WIDTH - 1 downto 0);
  signal sts_full      : std_logic;
  signal sts_alm_full  : std_logic;
  signal sts_empty     : std_logic;
  signal sts_alm_empty : std_logic;
  signal sts_fill_lvl  : std_logic_vector(G_DEPTH_P2 downto 0);

  constant M_AXIS_BFM : axi_stream_master_t := new_axi_stream_master (
    data_length => G_WIDTH--,
    --stall_config => new_stall_config(0.2, 1, 10)
  );

  constant S_AXIS_BFM : axi_stream_slave_t := new_axi_stream_slave (
    data_length => G_WIDTH--,
    --stall_config => new_stall_config(0.2, 1, 10)
  );

begin

  ------------------------------------------------------------------------------
  prc_main : process

    -- Helper Procedures
    procedure prd_wait_clk (
      cnt : in positive
    ) is
    begin
      for i in 0 to cnt - 1 loop
        wait until rising_edge(clk);
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

        info("Transmitting stream to DUT...");
        wait until rising_edge(clk);
        for xact_num in 1 to NUM_XACTIONS loop
          push_axi_stream( 
            net, M_AXIS_BFM, std_logic_vector(to_unsigned(xact_num, G_WIDTH))
          );
        end loop;
        wait until rising_edge(clk);
        info("Stream sent!");

        info("Checking stream from DUT...");
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        for xact_num in 1 to NUM_XACTIONS loop
          check_axi_stream( 
            net, S_AXIS_BFM, std_logic_vector(to_unsigned(xact_num, G_WIDTH))
          );
        end loop;
        wait until rising_edge(clk);
        info("Stream checked!");


      elsif run("test_1") then
        info("test_1");
        wait for 100 * CLK_PERIOD;
      end if;
    end loop;

    test_runner_cleanup(runner);
  end process;

  ------------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD / 2;
  srst_n <= not srst;

  ------------------------------------------------------------------------------
  u_dut : entity work.axis_fifo
  generic map(
    G_WIDTH         => G_WIDTH,
    G_DEPTH_P2      => G_DEPTH_P2,
    G_ALM_EMPTY_LVL => G_ALM_EMPTY_LVL,
    G_ALM_FULL_LVL  => G_ALM_FULL_LVL
  )
  port map(
    clk           => clk,
    srst          => srst,
    s_valid       => s_valid,
    s_ready       => s_ready,
    s_data        => s_data,
    m_valid       => m_valid,
    m_ready       => m_ready,
    m_data        => m_data,
    sts_full      => sts_full,
    sts_alm_full  => sts_alm_full,
    sts_empty     => sts_empty,
    sts_alm_empty => sts_alm_empty,
    sts_fill_lvl  => sts_fill_lvl
  );

  ------------------------------------------------------------------------------
  u_axis_m_bfm : entity vunit_lib.axi_stream_master
  generic map (
    master => M_AXIS_BFM
  )
  port map (
    aclk         => clk,    
    areset_n     => srst_n,   
    tvalid       => s_valid,
    tready       => s_ready,
    tdata        => s_data 
  );

  ------------------------------------------------------------------------------
  axi_stream_slave_inst : entity vunit_lib.axi_stream_slave
  generic map (
    slave => S_AXIS_BFM
  )
  port map (
    aclk => clk,
    areset_n => srst_n,
    tvalid => m_valid,
    tready => m_ready,
    tdata => m_data
  );

end;