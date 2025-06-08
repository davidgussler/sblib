--##############################################################################
--# File : gpio_axil.vhd
--# Auth : David Gussler
--# Lang : VHDL '08
--# ============================================================================
--! AXI Lite GPIO
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library axi_lite;
use axi_lite.axi_lite_pkg.all;
use work.util_pkg.all;
use work.conv_pkg.all;
use work.gpio_regs_pkg.all;
use work.gpio_register_record_pkg.all;

entity gpio_axil is
  generic (
    --! Channel mode options: "OUT", "IN", "INOUT", "DISABLE"
    G_CH_0_MODE : string := "OUT";
    --! Width in bits of the channel
    G_CH_0_WIDTH : positive range 1 to 32 := 32;
    --! Add double flip-flop synchronizer to input bits. Only applicable for
    --! "IN" and "INOUT" modes.
    G_CH_0_SYNC : boolean := false;
    -- Default output value. Only applicable for "OUT" and "INOUT" modes.
    G_CH_0_DFLT_O : std_logic_vector(G_CH_0_WIDTH - 1 downto 0) := (others => '0');
    -- Default tri-state value. Only applicable for "OUT" and "INOUT" modes.
    G_CH_0_DFLT_T : std_logic_vector(G_CH_0_WIDTH - 1 downto 0) := (others => '0');
    G_CH_1_MODE   : string                                      := "IN";
    G_CH_1_WIDTH  : positive range 1 to 32                      := 32;
    G_CH_1_SYNC   : boolean                                     := true;
    G_CH_1_DFLT_O : std_logic_vector(G_CH_1_WIDTH - 1 downto 0) := (others => '0');
    G_CH_1_DFLT_T : std_logic_vector(G_CH_1_WIDTH - 1 downto 0) := (others => '1');
    G_CH_2_MODE   : string                                      := "INOUT";
    G_CH_2_WIDTH  : positive range 1 to 32                      := 32;
    G_CH_2_SYNC   : boolean                                     := true;
    G_CH_2_DFLT_O : std_logic_vector(G_CH_2_WIDTH - 1 downto 0) := (others => '0');
    G_CH_2_DFLT_T : std_logic_vector(G_CH_2_WIDTH - 1 downto 0) := (others => '1')
  );
  port (
    clk  : in    std_logic;
    srst : in    std_logic;
    irq  : out   std_logic;
    --
    s_axil_req : in    axil_req_t;
    s_axil_rsp : out   axil_rsp_t;
    --
    gpio_0_i : in    std_logic_vector(G_CH_0_WIDTH - 1 downto 0) := (others => '0');
    gpio_0_o : out   std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
    gpio_0_t : out   std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
    --
    gpio_1_i : in    std_logic_vector(G_CH_1_WIDTH - 1 downto 0) := (others => '0');
    gpio_1_o : out   std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
    gpio_1_t : out   std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
    --
    gpio_2_i : in    std_logic_vector(G_CH_2_WIDTH - 1 downto 0) := (others => '0');
    gpio_2_o : out   std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
    gpio_2_t : out   std_logic_vector(G_CH_2_WIDTH - 1 downto 0)
  );
end entity;

architecture rtl of gpio_axil is

  signal axi_lite_m2s  : axi_lite_m2s_t;
  signal axi_lite_s2m  : axi_lite_s2m_t;
  signal i             : gpio_regs_up_t         := gpio_regs_up_init;
  signal o             : gpio_regs_down_t       := gpio_regs_down_init;
  signal r             : gpio_reg_was_read_t    := gpio_reg_was_read_init;
  signal w             : gpio_reg_was_written_t := gpio_reg_was_written_init;
  signal irq0          : std_logic;
  signal irq1          : std_logic;
  signal irq2          : std_logic;
  signal regi_0_din    : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal regi_0_dout   : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal rego_0_dout   : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal regw_0_dout   : std_logic;
  signal regi_0_tri    : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal rego_0_tri    : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal regw_0_tri    : std_logic;
  signal rego_0_inten  : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal regi_0_intsts : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal rego_0_intsts : std_logic_vector(G_CH_0_WIDTH - 1 downto 0);
  signal regi_1_din    : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal regi_1_dout   : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal rego_1_dout   : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal regw_1_dout   : std_logic;
  signal regi_1_tri    : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal rego_1_tri    : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal regw_1_tri    : std_logic;
  signal rego_1_inten  : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal regi_1_intsts : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal rego_1_intsts : std_logic_vector(G_CH_1_WIDTH - 1 downto 0);
  signal regi_2_din    : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal regi_2_dout   : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal rego_2_dout   : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal regw_2_dout   : std_logic;
  signal regi_2_tri    : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal rego_2_tri    : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal regw_2_tri    : std_logic;
  signal rego_2_inten  : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal regi_2_intsts : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);
  signal rego_2_intsts : std_logic_vector(G_CH_2_WIDTH - 1 downto 0);

begin

  -- ---------------------------------------------------------------------------
  u_gpio_reg_file : entity work.gpio_register_file_axi_lite
  port map (
    clk             => clk,
    reset           => srst,
    axi_lite_m2s    => axi_lite_m2s,
    axi_lite_s2m    => axi_lite_s2m,
    regs_up         => i,
    regs_down       => o,
    reg_was_read    => r,
    reg_was_written => w
  );

  axi_lite_m2s <= to_hdlm(s_axil_req);
  s_axil_rsp   <= to_hdlm(axi_lite_s2m);

  -- ---------------------------------------------------------------------------
  prc_irq_reduce : process (clk) is begin
    if rising_edge(clk) then
      irq <= irq0 or irq1 or irq2;

      if srst then
        irq <= '0';
      end if;
    end if;
  end process;

  -- ---------------------------------------------------------------------------
  u_gpio_chan_0 : entity work.gpio_chan
  generic map (
    G_CH_WIDTH  => G_CH_0_WIDTH,
    G_CH_MODE   => G_CH_0_MODE,
    G_CH_SYNC   => G_CH_0_SYNC,
    G_CH_DFLT_O => G_CH_0_DFLT_O,
    G_CH_DFLT_T => G_CH_0_DFLT_T
  )
  port map (
    clk         => clk,
    srst        => srst,
    irq         => irq0,
    regi_din    => regi_0_din,
    regi_dout   => regi_0_dout,
    rego_dout   => rego_0_dout,
    regw_dout   => regw_0_dout,
    regi_tri    => regi_0_tri,
    rego_tri    => rego_0_tri,
    regw_tri    => regw_0_tri,
    rego_inten  => rego_0_inten,
    regi_intsts => regi_0_intsts,
    rego_intsts => rego_0_intsts,
    gpio_i      => gpio_0_i,
    gpio_o      => gpio_0_o,
    gpio_t      => gpio_0_t
  );

  i.chan(0).din.din(G_CH_0_WIDTH - 1 downto 0)   <= unsigned(regi_0_din);
  i.chan(0).dout.dout(G_CH_0_WIDTH - 1 downto 0) <= unsigned(regi_0_dout);
  i.chan(0).tri.tri(G_CH_0_WIDTH - 1 downto 0)   <= unsigned(regi_0_tri);
  i.chan(0).isr.isr(G_CH_0_WIDTH - 1 downto 0)   <= unsigned(regi_0_intsts);

  rego_0_intsts <= std_logic_vector(o.chan(0).isr.isr(G_CH_0_WIDTH - 1 downto 0));
  rego_0_dout   <= std_logic_vector(o.chan(0).dout.dout(G_CH_0_WIDTH - 1 downto 0));
  regw_0_dout   <= w.chan(0).dout;
  rego_0_tri    <= std_logic_vector(o.chan(0).tri.tri(G_CH_0_WIDTH - 1 downto 0));
  regw_0_tri    <= w.chan(0).tri;
  rego_0_inten  <= std_logic_vector(o.chan(0).ier.ier(G_CH_0_WIDTH - 1 downto 0));

  -- ---------------------------------------------------------------------------
  u_gpio_chan_1 : entity work.gpio_chan
  generic map (
    G_CH_WIDTH  => G_CH_1_WIDTH,
    G_CH_MODE   => G_CH_1_MODE,
    G_CH_SYNC   => G_CH_1_SYNC,
    G_CH_DFLT_O => G_CH_1_DFLT_O,
    G_CH_DFLT_T => G_CH_1_DFLT_T
  )
  port map (
    clk         => clk,
    srst        => srst,
    irq         => irq1,
    regi_din    => regi_1_din,
    regi_dout   => regi_1_dout,
    rego_dout   => rego_1_dout,
    regw_dout   => regw_1_dout,
    regi_tri    => regi_1_tri,
    rego_tri    => rego_1_tri,
    regw_tri    => regw_1_tri,
    rego_inten  => rego_1_inten,
    regi_intsts => regi_1_intsts,
    rego_intsts => rego_1_intsts,
    gpio_i      => gpio_1_i,
    gpio_o      => gpio_1_o,
    gpio_t      => gpio_1_t
  );

  i.chan(1).din.din(G_CH_1_WIDTH - 1 downto 0)   <= unsigned(regi_1_din);
  i.chan(1).dout.dout(G_CH_1_WIDTH - 1 downto 0) <= unsigned(regi_1_dout);
  i.chan(1).tri.tri(G_CH_1_WIDTH - 1 downto 0)   <= unsigned(regi_1_tri);
  i.chan(1).isr.isr(G_CH_1_WIDTH - 1 downto 0)   <= unsigned(regi_1_intsts);

  rego_1_intsts <= std_logic_vector(o.chan(1).isr.isr(G_CH_1_WIDTH - 1 downto 0));
  rego_1_dout   <= std_logic_vector(o.chan(1).dout.dout(G_CH_1_WIDTH - 1 downto 0));
  regw_1_dout   <= w.chan(1).dout;
  rego_1_tri    <= std_logic_vector(o.chan(1).tri.tri(G_CH_1_WIDTH - 1 downto 0));
  regw_1_tri    <= w.chan(1).tri;
  rego_1_inten  <= std_logic_vector(o.chan(1).ier.ier(G_CH_1_WIDTH - 1 downto 0));

  -- ---------------------------------------------------------------------------
  u_gpio_chan_2 : entity work.gpio_chan
  generic map (
    G_CH_WIDTH  => G_CH_2_WIDTH,
    G_CH_MODE   => G_CH_2_MODE,
    G_CH_SYNC   => G_CH_2_SYNC,
    G_CH_DFLT_O => G_CH_2_DFLT_O,
    G_CH_DFLT_T => G_CH_2_DFLT_T
  )
  port map (
    clk         => clk,
    srst        => srst,
    irq         => irq2,
    regi_din    => regi_2_din,
    regi_dout   => regi_2_dout,
    rego_dout   => rego_2_dout,
    regw_dout   => regw_2_dout,
    regi_tri    => regi_2_tri,
    rego_tri    => rego_2_tri,
    regw_tri    => regw_2_tri,
    rego_inten  => rego_2_inten,
    regi_intsts => regi_2_intsts,
    rego_intsts => rego_2_intsts,
    gpio_i      => gpio_2_i,
    gpio_o      => gpio_2_o,
    gpio_t      => gpio_2_t
  );

  i.chan(2).din.din(G_CH_2_WIDTH - 1 downto 0)   <= unsigned(regi_2_din);
  i.chan(2).dout.dout(G_CH_2_WIDTH - 1 downto 0) <= unsigned(regi_2_dout);
  i.chan(2).tri.tri(G_CH_2_WIDTH - 1 downto 0)   <= unsigned(regi_2_tri);
  i.chan(2).isr.isr(G_CH_2_WIDTH - 1 downto 0)   <= unsigned(regi_2_intsts);

  rego_2_intsts <= std_logic_vector(o.chan(2).isr.isr(G_CH_2_WIDTH - 1 downto 0));
  rego_2_dout   <= std_logic_vector(o.chan(2).dout.dout(G_CH_2_WIDTH - 1 downto 0));
  regw_2_dout   <= w.chan(2).dout;
  rego_2_tri    <= std_logic_vector(o.chan(2).tri.tri(G_CH_2_WIDTH - 1 downto 0));
  regw_2_tri    <= w.chan(2).tri;
  rego_2_inten  <= std_logic_vector(o.chan(2).ier.ier(G_CH_2_WIDTH - 1 downto 0));

end architecture;
