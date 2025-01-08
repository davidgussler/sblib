--##############################################################################
--# File     : multirate_async_rxvr.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! Multirate async 4x oversampling receiver. 
--! Module is deeply pipelined so that it will work at the highest possible 
--! fpga clk frequency. It achieves 500MHz on an Artix US+.  
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity async_rxvr is
  generic (
    --! Width of the `ce_div` input signal 
    G_DIV_WIDTH : natural := 8
  );
  port (
    --! 4x oversampling clock. This must be 4x the highest possible data rate of 
    --! rxd. For example if max rxd rate is 125Mbps, clk must be 500MHz.
    clk     : in    std_logic; 
    --! rxd data rate = clk freq / 4 / (ce_div+1). So for example, set this to 0
    --! for full speed, 1 for div by 2, set to 2 for div by 3. This may be
    --! updated at runtime. Synchronous to clk.
    ce_div  : in    std_logic_vector(G_DIV_WIDTH-1 downto 0);
    --! Async rx input. Chip input.
    rxd     : in    std_logic;
    --! Recovered data. Synchronous to clk.
    m_data  : out   std_logic; 
    --! Recovered data valid. Synchronous to clk. In the nominal case, where 
    --! the recovered rxd clock is perfectly synchronous with fpga clk, this will
    --! pulse once every 4 * (ce_div+1) cycles. If rxd is slightly slower than 
    --! fpga clk, then this will sometimes pulse once every 5 * (ce_div+1)
    --! cycles. If rxd is slightly faster than fpga clk, this this will sometimes
    --! pulse once every 3 * (ce_div+1).
    --! This means, that in the worst-case, the output bandwidth of this module 
    --! will be slightly higher than the rxd input bandwidth, so if m_data is 
    --! CDC'ed outside of this module to a slower domain, the destination clock 
    --! should be slightly faster than 1/4 the speed of this module's clock. 
    m_valid : out   std_logic  
  );
end entity;


architecture rtl of async_rxvr is

  -- ---------------------------------------------------------------------------
  signal vld : std_logic_vector(3 downto 0) := "0000";
  signal rxd_ff, rxd_f2, edge_detect, valid, valid_ff : std_logic; 
  signal ce : std_logic := '0'; 
  signal ce_cnt : unsigned(ce_div'range) := (others => '0');

begin

  -- ---------------------------------------------------------------------------
  -- Sync input signal
  u_cdc_bit : entity work.cdc_bit
  generic map (
    G_USE_SRC_CLK => false,
    G_SYNC_LEN    => 2,
    G_WIDTH       => 1
  )
  port map (
    src_bit(0) => rxd,
    dst_clk => clk,
    dst_bit(0) => rxd_ff
  );

  -- ---------------------------------------------------------------------------
  -- Clock enable for slower rates
  prc_ce : process (clk) is begin
    if rising_edge(clk) then
      if unsigned(ce_div) = 0 then 
        ce_cnt <= (others => '0');
        ce <= '1';
      elsif unsigned(ce_div) <= ce_cnt then
        ce_cnt <= (others => '0');
        ce <= '1';
      else 
        ce_cnt <= ce_cnt + 1; 
        ce <= '0';
      end if; 
    end if;
  end process;

  -- ---------------------------------------------------------------------------
  -- Pulse valid at the center of the eye. Continually shift the phase as
  -- needed.
  prc_bitslip_adjust : process (clk) is begin
    if rising_edge(clk) then
      if ce then

        -- Detect edges of the incoming rxd. Used the adjust the phase.
        rxd_f2 <= rxd_ff; 
        edge_detect <= rxd_f2 xor rxd_ff;
        valid <= vld(0) and not edge_detect; 

        -- Pulse valid once every 4 cycles since we're oversampling by x4.
        -- Resync valid on every edge of rxd. rxd must have a sufficient number
        -- of transitions for this receiver to work properly.
        if edge_detect then 
          vld <= "0001";
        else
          vld <= vld(2 downto 0) & vld(3);
        end if; 
      end if; 

      -- Only pulse valid on rising edge of valid (to make it work for multirate)
      valid_ff <= valid;
      m_valid <= valid and not valid_ff;
      m_data <= rxd_f2; 

    end if;
  end process;

end architecture;
