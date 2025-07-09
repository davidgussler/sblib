--#############################################################################
--# File : cdc_vector.vhd
--# Auth : David Gussler
--# Lang : VHDL '08
--# ===========================================================================
--! Handshake vector synchronizer based on AXIS
--#############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity cdc_vector is
  generic (
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive := 2;
    -- Data width
    G_WIDTH : positive := 8
  );
  port (
    -- Slave port
    s_clk   : in    std_logic;
    s_valid : in    std_logic;
    s_ready : out   std_logic := '0';
    s_data  : in    std_logic_vector(G_WIDTH - 1 downto 0);
    -- Master port
    m_clk   : in    std_logic;
    m_valid : out   std_logic := '0';
    m_ready : in    std_logic;
    m_data  : out   std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity;

architecture rtl of cdc_vector is

  -- ---------------------------------------------------------------------------
  signal s_valid_ff    : std_logic;
  signal s_ready_ff    : std_logic;
  signal s_data_ff     : std_logic_vector(G_WIDTH - 1 downto 0);
  signal src_req_pulse : std_logic;
  signal src_ack_pulse : std_logic;
  signal dst_req_pulse : std_logic;
  signal dst_ack_pulse : std_logic;

begin

  -- Registers to help determine if a new request is active
  prc_new_request : process (s_clk) is begin
    if rising_edge(s_clk) then
      s_valid_ff <= s_valid;
      s_ready_ff <= s_ready;
      s_data_ff  <= s_data;
    end if;
  end process;

  -- New request if rising edge of valid or new valid after previous ready
  src_req_pulse <= (s_valid and not s_valid_ff) or (s_valid and s_ready_ff);

  -- CDC the request to the destination domain
  u_cdc_pulse_req : entity work.cdc_pulse
  generic map (
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH    => 1
  )
  port map (
    src_clk      => s_clk,
    src_pulse(0) => src_req_pulse,
    dst_clk      => m_clk,
    dst_pulse(0) => dst_req_pulse
  );

  -- Hold destination valid high until destination is ready to accept
  -- transaction
  prc_hold_valid : process (m_clk) is begin
    if rising_edge(m_clk) then
      if dst_req_pulse then
        m_valid <= '1';
        m_data  <= s_data_ff;
      elsif dst_ack_pulse then
        m_valid <= '0';
      end if;
    end if;
  end process;

  -- Ack when a valid transaction has completed
  dst_ack_pulse <= m_valid and m_ready;

  -- CDC the acknowledge back to the source domain
  u_cdc_pulse_ack : entity work.cdc_pulse
  generic map (
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH    => 1
  )
  port map (
    src_clk      => m_clk,
    src_pulse(0) => dst_ack_pulse,
    dst_clk      => s_clk,
    dst_pulse(0) => src_ack_pulse
  );

  -- Source can advance to the next transaction once the ack has been cdc'd
  -- from the dest back to the source.
  s_ready <= src_ack_pulse;

end architecture;
