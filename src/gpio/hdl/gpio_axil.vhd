--##############################################################################
--# File : gpio_axil.vhd
--# Auth : David Gussler
--# ============================================================================
--# Shrikebyte VHDL Library - https://github.com/shrikebyte/sblib
--# Copyright (C) Shrikebyte, LLC
--# Licensed under the Apache 2.0 license, see LICENSE for details.
--# ============================================================================
--# AXI Lite GPIO
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;
use work.bus_pkg.all;
use work.gpio_regs_pkg.all;
use work.gpio_register_record_pkg.all;

entity gpio_axil is
  generic (
    -- Use double-flop input synchronizer
    G_SYNC_I : boolean := false;
    -- Default output value
    G_RST_VAL_O : std_ulogic_vector(AXIL_DATA_RANGE) := (others => '0');
    -- Default tri-state value
    G_RST_VAL_T : std_ulogic_vector(AXIL_DATA_RANGE) := (others => '1')
  );
  port (
    clk  : in    std_logic;
    srst : in    std_logic;
    irq  : out   std_logic;
    --
    s_axil : view s_axil_view;
    --
    gpio_i : in    std_ulogic_vector(AXIL_DATA_RANGE) := (others => '0');
    gpio_o : out   std_ulogic_vector(AXIL_DATA_RANGE);
    gpio_t : out   std_ulogic_vector(AXIL_DATA_RANGE)
  );
end entity;

architecture rtl of gpio_axil is

  -- Override the hdl_registers default values for gpio_o and gpio_t with
  -- generics
  constant GPIO_REGISTERS_RESET : gpio_registers_t := (
    isr  => gpio_isr_init,
    ier  => gpio_ier_init,
    dout => (dout => unsigned(G_RST_VAL_O)),
    din  => gpio_din_init,
    tri  => (tri => unsigned(G_RST_VAL_T))
  );

  signal u : gpio_regs_up_t;
  signal d : gpio_regs_down_t;
  signal r : gpio_reg_was_read_t;
  signal w : gpio_reg_was_written_t;

  signal gpio_in : std_ulogic_vector(AXIL_DATA_RANGE);
  signal edge    : std_ulogic_vector(AXIL_DATA_RANGE);
  signal irq_sts : std_ulogic_vector(AXIL_DATA_RANGE);

begin

  -- ---------------------------------------------------------------------------
  u_reg_file : entity work.gpio_register_file_axi_lite
  generic map (
    DEFAULT_VALUES => gpio_registers_reset
  )
  port map (
    clk             => clk,
    reset           => srst,
    s_axil          => s_axil,
    regs_up         => u,
    regs_down       => d,
    reg_was_read    => r,
    reg_was_written => w
  );

  -- ---------------------------------------------------------------------------
  gen_sync : if G_SYNC_I generate

    u_cdc_bit : entity work.cdc_bit
    generic map (
      G_WIDTH       => AXIL_DATA_WIDTH,
      G_USE_SRC_REG => false,
      G_EXTRA_SYNC  => 0
    )
    port map (
      src_bit => gpio_i,
      dst_clk => clk,
      dst_bit => gpio_in
    );

  else generate

    gpio_in <= gpio_i;

  end generate;

  -- ---------------------------------------------------------------------------
  u_edge_detect : entity work.edge_detect
  generic map (
    G_WIDTH => AXIL_DATA_WIDTH
  )
  port map (
    clk  => clk,
    srst => srst,
    din  => gpio_in,
    both => edge
  );

  u_irq_reg : entity work.irq_reg
  generic map (
    G_WIDTH => AXIL_DATA_WIDTH
  )
  port map (
    clk  => clk,
    srst => srst,
    clr  => std_logic_vector(d.isr.isr),
    en   => std_logic_vector(d.ier.ier),
    set  => edge,
    sts  => irq_sts,
    irq  => irq
  );

  u.isr.isr <= unsigned(irq_sts);
  u.din.din <= unsigned(gpio_in);
  gpio_o    <= std_logic_vector(d.dout.dout);
  gpio_t    <= std_logic_vector(d.tri.tri);

end architecture;
