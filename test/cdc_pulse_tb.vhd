
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.type_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.vc_context;

entity cdc_pulse_tb is
  generic (
    RUNNER_CFG : string
  );
end entity;

architecture tb of cdc_pulse_tb is

  -- Clock period
  constant SRC_CLK_PERIOD : time := 3 ns;
  constant DST_CLK_PERIOD : time := 16 ns;
  constant CLK_TO_Q   : time := 0.1 ns;
  -- Generics
  constant G_SYNC_LEN     : positive   := 2;
  constant G_WIDTH        : positive   := 1;
  constant G_PROT_OVLD    : boolean    := true; 
  -- Ports
  signal src_clk   : std_logic := '1';
  signal dst_clk   : std_logic := '1';
  signal src_pulse : std_logic_vector(G_WIDTH-1 downto 0) := (others => '0');
  signal dst_pulse : std_logic_vector(G_WIDTH-1 downto 0) := (others => '0');

begin

  proc_main : process is

    -- Helper Procedures
    procedure prd_wait_clk (
      cnt : in positive := 1
    ) is
    begin
      for i in 0 to cnt - 1 loop
        wait until rising_edge(src_clk);
        wait for CLK_TO_Q;
      end loop;
    end procedure prd_wait_clk;

  begin

    test_runner_setup(runner, runner_cfg);

    while test_suite loop

      prd_wait_clk(16);

      if run("test_0") then
        info("Running test_0 - Single cycle pulse");
        prd_wait_clk;
        src_pulse <= "1";
        prd_wait_clk;
        src_pulse <= "0";

      elsif run("test_1") then
        info("Running test_1 - Two back to back pulses");

        prd_wait_clk;
        src_pulse <= "1";
        prd_wait_clk;
        src_pulse <= "0";
        prd_wait_clk;
        src_pulse <= "1";
        prd_wait_clk;
        src_pulse <= "0";

      elsif run("test_2") then
        info("Running test_2 - One 4-cycle wide pulse");

        prd_wait_clk;
        src_pulse <= "1";
        prd_wait_clk(4);
        src_pulse <= "0";

      end if;

      src_pulse <= "0";
      prd_wait_clk(16);

    end loop;

    test_runner_cleanup(runner);

  end process proc_main;

  -- Watchdog
  test_runner_watchdog(runner, 100 us);

  -- ---------------------------------------------------------------------------
  src_clk <= not src_clk after SRC_CLK_PERIOD / 2;
  dst_clk <= not dst_clk after DST_CLK_PERIOD / 2;

  -- ---------------------------------------------------------------------------
  u_dut : entity work.cdc_pulse
  generic map (
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH => G_WIDTH,
    G_PROT_OVLD => G_PROT_OVLD
  )
  port map (
    src_clk => src_clk,
    src_pulse => src_pulse,
    dst_clk => dst_clk,
    dst_pulse => dst_pulse
  );

end architecture tb;
