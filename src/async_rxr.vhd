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

entity async_rxr is
  generic (
    --! Width of the `ce_div` input signal 
    G_DIV_WIDTH : natural := 8
  );
  port (
    --! 4x oversampling clock. This must be 4x the highest possible data rate of 
    --! rxd. For example if max rxd rate is 125Mbps, clk must be 500MHz.
    clk_4x     : in    std_logic; 
    clk_1x     : in    std_logic; 
    --! rxd data rate = clk freq / 4 / (ce_div+1). So for example, set this to 0
    --! for full speed, 1 for div by 2, set to 2 for div by 3. This may be
    --! updated at runtime. Synchronous to clk.
    ce_div  : in    std_logic_vector(G_DIV_WIDTH-1 downto 0);
    --! Async rx input. Chip input.
    rxd     : in    std_logic;
    --! Recovered data. Synchronous to clk_1x.
    m_data  : out   std_logic_vector(3 downto 0); 
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
    m_valid : out   std_logic_vector(3 downto 0)  
  );
end entity;


architecture rtl of async_rxr is

  -- ---------------------------------------------------------------------------
  signal ovsmp : std_logic_vector(3 downto 0);
  signal ovsmp_ff : std_logic_vector(3 downto 0);
  signal ovsmp_f2 : std_logic_vector(3 downto 0);
  signal edge : std_logic_vector(3 downto 0);

  signal state : integer range 0 to 3 := 0; 

  signal bitslip_fast : std_logic;
  signal bitslip_slow : std_logic;


  signal rxd_ff, rxd_f2, edge_detect, valid, valid_ff : std_logic; 
  signal ce : std_logic := '0'; 
  signal ce_cnt : unsigned(ce_div'range) := (others => '0');

begin

  -- -- ---------------------------------------------------------------------------
  -- -- Clock enable for slower rates
  -- prc_ce : process (clk) is begin
  --   if rising_edge(clk) then
  --     if unsigned(ce_div) = 0 then 
  --       ce_cnt <= (others => '0');
  --       ce <= '1';
  --     elsif unsigned(ce_div) <= ce_cnt then
  --       ce_cnt <= (others => '0');
  --       ce <= '1';
  --     else 
  --       ce_cnt <= ce_cnt + 1; 
  --       ce <= '0';
  --     end if; 
  --   end if;
  -- end process;

  -- ---------------------------------------------------------------------------
  prc_ovsmp : process (clk_4x) is begin
    if rising_edge(clk_4x) then
      ovsmp <= ovsmp(2 downto 0) & rxd;
    end if;
  end process;

  -- ---------------------------------------------------------------------------
  prc_ovsmp_ff : process (clk_1x) is begin
    if rising_edge(clk_1x) then

      ovsmp_ff <= ovsmp;
      ovsmp_f2 <= ovsmp_ff;
      edge <= ovsmp_ff xor (ovsmp_f2(0) & ovsmp_ff(3 downto 1));

      -- case state is
      --   when 0 =>
      --     if edge(3) then
      --       state <= 1;
      --     elsif edge(0) then
      --       state <= 2;
      --     end if;
        
      --   when 1 =>
      --     if edge(0) then 
      --       state <= 3;
      --     elsif edge(1) then 
      --       state <= 0;
      --     end if; 

      --   when 3 =>
      --     if edge(1) then 
      --       state <= 2;
      --     elsif edge(2) then 
      --       state <= 1;
      --     end if; 
        
      --   when 2 =>
      --     if edge(2) then 
      --       state <= 0;
      --     elsif edge(3) then 
      --       state <= 3;
      --     end if; 
      
      --   when others => null;
      -- end case;

      bitslip_fast <= '0';
      bitslip_slow <= '0';

      case state is
        when 0 =>
          if edge(3) then
            state <= 1;
          elsif edge(0) then
            state <= 3;
            bitslip_slow <= '1'; 
          end if;
        
        when 1 =>
          if edge(0) then 
            state <= 2;
          elsif edge(1) then 
            state <= 0;
          end if; 

        when 2 =>
          if edge(1) then 
            state <= 3;
          elsif edge(2) then 
            state <= 1;
          end if; 
        
        when 3 =>
          if edge(2) then 
            state <= 0;
            bitslip_fast <= '1'; 
          elsif edge(3) then 
            state <= 2;
          end if; 
      
        when others => null;
      end case;

      case state is
        when 0 => m_valid <= bitslip_fast & "001";
        when 1 => m_valid <= "0010"; 
        when 2 => m_valid <= "0100"; 
        when 3 => m_valid <= (not bitslip_slow) & "000";
        when others => null;
      end case;
      
      m_data <= ovsmp_ff; 

    end if;
  end process;

end architecture;
