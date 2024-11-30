--##############################################################################
--# File     : fifo_sync.vhd
--# Author   : David Gussler - davidnguss@gmail.com
--# Language : VHDL '08
--# ============================================================================
--! Synchronous fifo
--# ============================================================================
--# Copyright (c) 2022-2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fifo_sync is
  generic (
    G_WIDTH     : positive := 32; 
    G_DEPTH_P2  : positive := 10;
    G_FALLTHRU  : boolean  := FALSE
  );
  port (
    -- System
    clk : in std_logic;
    srst : in std_logic := '0';

    -- Write Port
    s_valid : in  std_logic; 
    s_ready : out  std_logic; 
    s_data  : in  std_logic_vector(G_WIDTH-1 downto 0); 

    -- Read Port
    m_valid : in  std_logic; 
    m_ready : out  std_logic; 
    m_data  : in  std_logic_vector(G_WIDTH-1 downto 0); 

    -- Status
    full      : out  std_logic; 
    alm_full  : out  std_logic; 
    empty     : out  std_logic; 
    aml_empty : out  std_logic; 
    fill_cnt  : out std_logic_vector(G_DEPTH_P2-1 downto 0)
  );
end entity;

architecture rtl of fifo_sync is


begin

   -- Comb Assignments
   o_full      <= '1' when fifo_cnt = C_DEPTH-1  else '0'; 
   o_full_nxt  <= '1' when fifo_cnt >= C_DEPTH-2 else '0';
   o_empty     <= '1' when fifo_cnt = 0          else '0';
   o_empty_nxt <= '1' when fifo_cnt <= 1         else '0';
   o_fill_cnt  <= std_logic_vector(fifo_cnt); 

   -- Update count
   ap_fifo_count : process (all)
   begin
      if (wr_ptr < rd_ptr) then
         fifo_cnt <= wr_ptr - rd_ptr + C_DEPTH; 
      else 
         fifo_cnt <= wr_ptr - rd_ptr; 
      end if; 
   end process;


   -- Update pointers
   sp_pointers : process (i_clk)
   begin
      if rising_edge(i_clk) then
         if (i_rst) then 
            wr_ptr   <= (others=>'0');
            rd_ptr   <= (others=>'0');
         else 

            -- Write
            if (i_wr and not o_full) then 
               wr_ptr <= wr_ptr + 1;
            end if; 

            -- Read 
            if (i_rd and not o_empty) then 
               rd_ptr <= rd_ptr + 1;
            end if; 

         end if; 
      end if;
   end process;


   -- Writes
   sp_fifo_writes : process (i_clk)
   begin
      if rising_edge(i_clk) then
         if (i_wr and not o_full) then 
            ram(to_integer(wr_ptr)) <= i_dat; 
         end if; 
      end if;
   end process;

   -- Sync reads
   ig_no_fallthru : if (G_FALLTHRU = FALSE) generate
      sp_sync_reads : process (i_clk)
      begin
         if rising_edge(i_clk) then
            if (i_rst) then 
               o_dat <= (others=>'0');
            else 
               if (i_rd and not o_empty) then 
                  o_dat <= ram(to_integer(rd_ptr)); 
               end if; 
            end if; 
         end if;
      end process;
   end generate;

   -- Lookahead reads 
   ig_fallthru : if (G_FALLTHRU = TRUE) generate
      o_dat <= ram(to_integer(rd_ptr)); 
   end generate;

end architecture;
