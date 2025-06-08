--##############################################################################
--# File : cdc_pulse.vhd
--# Auth : David Gussler
--# Lang : VHDL '08
--# ============================================================================
--! Simple pulse synchronizer. This can be used to sync one or several
--! unrelated single-cycle pulses across clock domains. src_pulse can be
--! many src_clk cycles long, and dst_pulse will always be one dst_clk cycle
--! long.
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity cdc_pulse is
  generic (
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive := 2;
    --! Number of unrelated pulses to synchronize
    G_WIDTH : positive := 1;
    --! Protect against pulse overloading at the input. If the user sends pulses
    --! infrequently or if the src clock is over 2x slower than the output clock
    --! then this can be set to false.
    G_PROT_OVLD : boolean := true
  );
  port (
    src_clk   : in    std_logic;
    src_pulse : in    std_logic_vector(G_WIDTH - 1 downto 0);
    dst_clk   : in    std_logic;
    dst_pulse : out   std_logic_vector(G_WIDTH - 1 downto 0) := (others=> '0')
  );
end entity;

architecture rtl of cdc_pulse is

  -- ---------------------------------------------------------------------------
  signal src_toggl    : std_logic_vector(src_pulse'range) := (others=> '0');
  signal src_pulse_ff : std_logic_vector(src_pulse'range) := (others=> '0');
  signal dst_toggl    : std_logic_vector(src_pulse'range) := (others=> '0');
  signal dst_toggl_ff : std_logic_vector(src_pulse'range) := (others=> '0');

begin

  -- ---------------------------------------------------------------------------
  gen_prot_overload : if G_PROT_OVLD generate
    signal src_toggl_feedback    : std_logic_vector(src_pulse'range) := (others=> '0');
    signal src_toggl_feedback_ff : std_logic_vector(src_pulse'range) := (others=> '0');
    signal src_locked            : std_logic_vector(src_pulse'range) := (others=> '0');
  begin

    -- Create a toggle when src pulse is detected
    -- -------------------------------------------------------------------------
    prc_src_toggle : process (src_clk) is begin
      if rising_edge(src_clk) then
        src_pulse_ff          <= src_pulse;
        src_toggl_feedback_ff <= src_toggl_feedback;

        for i in src_pulse'range loop
          if src_toggl_feedback(i) xor src_toggl_feedback_ff(i) then
            src_locked(i) <= '0';
          end if;

          if src_pulse(i) and not src_pulse_ff(i) and not src_locked(i) then
            src_toggl(i)  <= not src_toggl(i);
            src_locked(i) <= '1';
          end if;
        end loop;

      end if;
    end process;

    -- CDC the dst toggle back to the src domain. This is used as feedback to
    -- avoid the pulse overload condition.
    -- -------------------------------------------------------------------------
    u_cdc_bit_1 : entity work.cdc_bit
    generic map (
      G_USE_SRC_CLK => false,
      G_SYNC_LEN    => G_SYNC_LEN,
      G_WIDTH       => G_WIDTH
    )
    port map (
      src_bit => dst_toggl,
      dst_clk => src_clk,
      dst_bit => src_toggl_feedback
    );

  -- ---------------------------------------------------------------------------
  else generate
  begin

    -- Create a toggle when src pulse is detected
    -- -------------------------------------------------------------------------
    prc_src_toggle : process (src_clk) is begin
      if rising_edge(src_clk) then
        src_pulse_ff <= src_pulse;

        for i in src_pulse'range loop
          if src_pulse(i) and not src_pulse_ff(i) then
            src_toggl(i) <= not src_toggl(i);
          end if;
        end loop;

      end if;
    end process;

  end generate;

  -- CDC the toggle to the dst domain
  -- ---------------------------------------------------------------------------
  u_cdc_bit_0 : entity work.cdc_bit
  generic map (
    G_USE_SRC_CLK => false,
    G_SYNC_LEN    => G_SYNC_LEN,
    G_WIDTH       => G_WIDTH
  )
  port map (
    src_bit => src_toggl,
    dst_clk => dst_clk,
    dst_bit => dst_toggl
  );

  -- Create a dst pulse when toggle is detected
  -- ---------------------------------------------------------------------------
  prc_dst_pulse : process (dst_clk) is begin
    if rising_edge(dst_clk) then
      dst_toggl_ff <= dst_toggl;
    end if;
  end process;

  dst_pulse <= dst_toggl xor dst_toggl_ff;

end architecture;
