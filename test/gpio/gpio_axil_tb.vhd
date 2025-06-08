--##############################################################################
--# File : gpio_axil_tb.vhd
--# Auth : David Gussler
--# Lang : VHDL '08
--# ============================================================================
--! GPIO module testbench
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
  context vunit_lib.vunit_context;
  context vunit_lib.vc_context;
use vunit_lib.axi_lite_master_pkg.all;
use work.util_pkg.all;
use work.gpio_regs_pkg.all;

entity gpio_axil_tb is
  generic (
    RUNNER_CFG : string
  );
end entity;

architecture tb of gpio_axil_tb is

  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  constant CLK_TO_Q   : time := 1 ns;
  -- Generics
  constant G_CH_0_WIDTH  : positive range 1 to 32                      := 8;
  constant G_CH_0_MODE   : string                                      := "OUT";
  constant G_CH_0_SYNC   : boolean                                     := false;
  constant G_CH_0_DFLT_O : std_logic_vector(G_CH_0_WIDTH - 1 downto 0) := x"AA";
  constant G_CH_0_DFLT_T : std_logic_vector(G_CH_0_WIDTH - 1 downto 0) := x"BB";
  constant G_CH_1_WIDTH  : positive range 1 to 32                      := 16;
  constant G_CH_1_MODE   : string                                      := "IN";
  constant G_CH_1_SYNC   : boolean                                     := true;
  constant G_CH_1_DFLT_O : std_logic_vector(G_CH_1_WIDTH - 1 downto 0) := x"CCDD";
  constant G_CH_1_DFLT_T : std_logic_vector(G_CH_1_WIDTH - 1 downto 0) := x"EEFF";
  constant G_CH_2_WIDTH  : positive range 1 to 32                      := 24;
  constant G_CH_2_MODE   : string                                      := "INOUT";
  constant G_CH_2_SYNC   : boolean                                     := true;
  constant G_CH_2_DFLT_O : std_logic_vector(G_CH_2_WIDTH - 1 downto 0) := x"112233";
  constant G_CH_2_DFLT_T : std_logic_vector(G_CH_2_WIDTH - 1 downto 0) := x"445566";
  -- Ports
  signal clk        : std_logic := '1';
  signal srst       : std_logic := '1';
  signal irq        : std_logic;
  signal s_axil_req : axil_req_t;
  signal s_axil_rsp : axil_rsp_t;
  signal gpio_0_i   : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal gpio_0_o   : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal gpio_0_t   : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal gpio_1_i   : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal gpio_1_o   : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal gpio_1_t   : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal gpio_2_i   : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal gpio_2_o   : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal gpio_2_t   : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);

  constant AXIM : bus_master_t := new_bus(
      data_length => AXIL_DATA_WIDTH, address_length => AXIL_ADDR_WIDTH
    );

  function fn_addr (
    idx : natural
  ) return std_logic_vector is begin
    return std_logic_vector(to_unsigned(idx * 4, 32));
  end function;

begin

  prc_main : process is

    procedure prd_cycle (
      cnt : in positive := 1
    ) is
    begin
      for i in 0 to cnt - 1 loop
        wait until rising_edge(clk);
        wait for CLK_TO_Q;
      end loop;
    end procedure;

    variable axil_data : std_logic_vector(31 downto 0) := (others => '0');

  begin

    test_runner_setup(runner, RUNNER_CFG);

    while test_suite loop

      prd_cycle;
      srst <= '1';
      prd_cycle(16);
      srst <= '0';

      if run("test_0") then
        info("test_0");

        gpio_0_i <= x"00";
        gpio_1_i <= x"0000";
        gpio_2_i <= x"000000";

        prd_cycle(4);

        -- ---------------------------------------------------------------------
        info("Test channel 0");
        info("Check ch0 defaults");
        axil_data := x"000000" & G_CH_0_DFLT_O;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 default out reg.");

        prd_cycle;
        check_equal(gpio_0_o, G_CH_0_DFLT_O,
                    "Check ch0 default out sig.");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 default tri reg.");

        prd_cycle;
        check_equal(gpio_0_t, axil_data(7 downto 0),
                    "Check ch0 default tri sig.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 default in reg.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 default irq en reg.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 irq sts reg.");

        info("Write to the ch0 interrupt enable register.");
        axil_data := x"11223344";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(0)), axil_data,
                       AXI_RSP_OKAY, x"F");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 irq en reg after writing to it.");

        info("Write to the ch0 data out register.");
        axil_data := x"11223344";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(0)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000044";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 out reg after writing to it.");

        prd_cycle;
        check_equal(gpio_0_o, axil_data(7 downto 0),
                    "Check ch0 out sig after writing to it.");

        check_equal(irq, '0',
                    "Ch0 verify interrupt is not latched.");

        info("Write to the ch0 tri-state register.");
        axil_data := x"44556677";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(0)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(0)), AXI_RSP_OKAY,
                       axil_data, "Check ch0 tri reg after writing to it.");

        prd_cycle;
        check_equal(gpio_0_t, axil_data(7 downto 0),
                    "Check ch0 tri sig after writing to it.");

        -- ---------------------------------------------------------------------
        info("Test channel 1");
        info("Check ch1 defaults");
        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 default out reg.");

        prd_cycle;
        check_equal(gpio_1_o, axil_data(15 downto 0),
                    "Check ch1 default out sig.");

        axil_data := x"0000FFFF";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 default tri reg.");

        prd_cycle;
        check_equal(gpio_1_t, axil_data(15 downto 0),
                    "Check ch1 default tri sig.");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 in reg.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 default irq en reg.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 irq sts reg.");

        prd_cycle;
        gpio_1_i <= x"FFFF";
        prd_cycle;

        axil_data := x"0000FFFF";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 input register after updating the input signal.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), AXI_RSP_OKAY,
                       axil_data, "Verify that interrupts were caught on ch1.");

        check_equal(irq, '0',
                    "Ch1 verify interrupt sig is not latched (interrupts disabled).");

        info("Clear ch1 interrupt register.");
        axil_data := x"0000FFFF";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), AXI_RSP_OKAY,
                       axil_data, "Verify that ch1 interrupts were cleared.");

        info("Enable interrupts.");
        axil_data := x"0000FFFF";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(1)), axil_data,
                       AXI_RSP_OKAY, x"F");

        info("Change the state of some of the ch1 GPIO inputs.");
        prd_cycle;
        gpio_1_i <= x"F0FE";
        prd_cycle;

        axil_data := x"0000" & gpio_1_i;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(1)), AXI_RSP_OKAY,
                       axil_data, "Check ch1 input register after updating the value of the input signal.");

        axil_data := x"0000" & not gpio_1_i;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), AXI_RSP_OKAY,
                       axil_data, "Verify that the expected interrupts were caught on ch1.");

        check_equal(irq, '1',
                    "Ch1 verify interrupt signal is latched (interrupts enabled).");

        info("Clear some (but not all) of the bits in the ch1 isr.");
        axil_data := x"0000FF00";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"000000" & not gpio_1_i(7 downto 0);
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), AXI_RSP_OKAY,
                       axil_data, "Verify that the expected interrupts were cleared on ch1 (1).");

        check_equal(irq, '1',
                    "Ch1 verify interrupt signal is still latched (not all interrupts cleared).");

        info("Clear the rest of the bits in the ch1 isr.");
        axil_data := x"000000FF";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(1)), AXI_RSP_OKAY,
                       axil_data, "Verify that the expected interrupts were cleared on ch1 (2).");

        check_equal(irq, '0',
                    "Ch1 verify interrupt signal has been cleared.");

        -- ---------------------------------------------------------------------
        info("Test channel 2");
        info("Check ch2 defaults");
        axil_data := x"00" & G_CH_2_DFLT_O;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 default out reg.");

        prd_cycle;
        check_equal(gpio_2_o, axil_data(23 downto 0),
                    "Check ch2 default out signal.");

        axil_data := x"00" & G_CH_2_DFLT_T;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 default tri reg.");

        prd_cycle;
        check_equal(gpio_2_t, axil_data(23 downto 0), "Check ch2 default tri signal.");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 in reg.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 default irq en reg.");

        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 irq sts reg.");

        info("Change the state of all the ch2 GPIO inputs.");
        prd_cycle;
        gpio_2_i <= x"FFFFFF";
        prd_cycle;

        axil_data := x"00FFFFFF";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 input register after updating the input signal value.");

        axil_data := x"00FFFFFF";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), AXI_RSP_OKAY,
                       axil_data, "Verify that interrupts were caught on ch2.");

        check_equal(irq, '0', "Ch2 verify interrupt signal not asserted.");

        info("Clear ch2 interrupt register.");
        axil_data := x"00FFFFFF";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), AXI_RSP_OKAY,
                       axil_data, "Verify that ch2 interrupts were cleared.");

        info("Enable ch2 interrupts.");
        axil_data := x"00FFFFFF";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_ier(2)), axil_data,
                       AXI_RSP_OKAY, x"F");

        info("Change the state of some of the ch2 GPIO inputs.");
        prd_cycle;
        gpio_2_i <= x"ABF0FE";
        prd_cycle;

        axil_data := x"00" & gpio_2_i;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_din(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 input register after updating value on wire.");

        axil_data := x"00" & not gpio_2_i;
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), AXI_RSP_OKAY,
                       axil_data, "Verify that the expected interrupts were caught on ch2.");

        check_equal(irq, '1', "Ch2 verify interrupt signal asserted.");

        info("Clear some (but not all) of the bits in the ch2 isr.");
        axil_data := x"00FFF000";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000" & not gpio_2_i(11 downto 0);
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), AXI_RSP_OKAY,
                       axil_data, "Verify that the expected interrupts were cleared on ch2 (1).");

        check_equal(irq, '1', "Ch2 verify interrupt signal still asserted.");

        info("Clear the rest of the bits in the ch2 isr.");
        axil_data := x"00000FFF";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00000000";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_isr(2)), AXI_RSP_OKAY,
                       axil_data, "Verify that the expected interrupts were cleared on ch2 (2).");

        check_equal(irq, '0', "Ch2 verify interrupt signal got de-asserted.");

        info("Write the output data on GPIO ch2.");
        axil_data := x"55667788";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(2)), axil_data,
                       AXI_RSP_OKAY, x"F");

        axil_data := x"00667788";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_dout(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 out reg after writing to it.");

        prd_cycle;
        check_equal(gpio_2_o, axil_data(23 downto 0),
                    "Check ch2 out signal after writing to it.");

        axil_data := x"44556677";
        write_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(2)), axil_data,
                       AXI_RSP_OKAY, x"0");

        axil_data := x"00556677";
        check_axi_lite(net, AXIM, fn_addr(gpio_chan_tri(2)), AXI_RSP_OKAY,
                       axil_data, "Check ch2 tri reg after writing to it.");

        prd_cycle;
        check_equal(gpio_2_t, axil_data(23 downto 0),
                    "Check ch2 tri signal after writing to it.");

      end if;

      test_runner_cleanup(runner);

    end loop;
  end process;

  -- ---------------------------------------------------------------------------
  clk <= not clk after CLK_PERIOD / 2;

  -- ---------------------------------------------------------------------------
  u_gpio_axil : entity work.gpio_axil
  generic map (
    G_CH_0_WIDTH  => G_CH_0_WIDTH,
    G_CH_0_MODE   => G_CH_0_MODE,
    G_CH_0_SYNC   => G_CH_0_SYNC,
    G_CH_0_DFLT_O => G_CH_0_DFLT_O,
    G_CH_0_DFLT_T => G_CH_0_DFLT_T,
    G_CH_1_WIDTH  => G_CH_1_WIDTH,
    G_CH_1_MODE   => G_CH_1_MODE,
    G_CH_1_SYNC   => G_CH_1_SYNC,
    G_CH_1_DFLT_O => G_CH_1_DFLT_O,
    G_CH_1_DFLT_T => G_CH_1_DFLT_T,
    G_CH_2_WIDTH  => G_CH_2_WIDTH,
    G_CH_2_MODE   => G_CH_2_MODE,
    G_CH_2_SYNC   => G_CH_2_SYNC,
    G_CH_2_DFLT_O => G_CH_2_DFLT_O,
    G_CH_2_DFLT_T => G_CH_2_DFLT_T
  )
  port map (
    clk        => clk,
    srst       => srst,
    irq        => irq,
    s_axil_req => s_axil_req,
    s_axil_rsp => s_axil_rsp,
    gpio_0_i   => gpio_0_i,
    gpio_0_o   => gpio_0_o,
    gpio_0_t   => gpio_0_t,
    gpio_1_i   => gpio_1_i,
    gpio_1_o   => gpio_1_o,
    gpio_1_t   => gpio_1_t,
    gpio_2_i   => gpio_2_i,
    gpio_2_o   => gpio_2_o,
    gpio_2_t   => gpio_2_t
  );

  -- ---------------------------------------------------------------------------
  u_axil_bfm : entity work.axil_bfm
  generic map (
    G_BUS_HANDLE => AXIM
  )
  port map (
    clk        => clk,
    m_axil_req => s_axil_req,
    m_axil_rsp => s_axil_rsp
  );

end architecture;
