--##############################################################################
--# File     : axis_fifo.vhd
--# Author   : David Gussler - davidnguss@gmail.com
--# Language : VHDL '08
--# ============================================================================
--! Synchronous axis fifo
--# ============================================================================
--# Copyright (c) 2022-2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_fifo is
  generic (
    G_WIDTH         : positive := 32;
    G_DEPTH_P2      : positive := 10;
    G_ALM_EMPTY_LVL : natural  := 4;
    G_ALM_FULL_LVL  : natural  := 1020
  );
  port (
    -- System
    clk  : in std_logic;
    srst : in std_logic;

    -- Slave Write Port
    s_valid : in std_logic;
    s_ready : out std_logic;
    s_data  : in std_logic_vector(G_WIDTH - 1 downto 0);

    -- Master Read Port
    m_valid : out std_logic;
    m_ready : in std_logic;
    m_data  : out std_logic_vector(G_WIDTH - 1 downto 0);

    -- Status Port
    sts_full      : out std_logic;
    sts_alm_full  : out std_logic;
    sts_empty     : out std_logic;
    sts_alm_empty : out std_logic;
    sts_fill_lvl  : out std_logic_vector(G_DEPTH_P2 downto 0)
  );
end entity;

architecture rtl of axis_fifo is

  constant DEPTH : positive := 2 ** G_DEPTH_P2;

  signal wr_en       : std_logic;
  signal rd_en       : std_logic;
  signal wr_ptr      : unsigned(G_DEPTH_P2 downto 0);
  signal rd_ptr      : unsigned(G_DEPTH_P2 downto 0);
  signal fill_lvl    : unsigned(G_DEPTH_P2 downto 0);

  type ram_t is array (natural range 0 to DEPTH) of 
    std_logic_vector(G_WIDTH-1 downto 0);

  signal ram : ram_t; 

begin

  ------------------------------------------------------------------------------
  sts_fill_lvl <= std_logic_vector(fill_lvl);
  s_ready <= not sts_full;
  m_valid <= not sts_empty;
  fill_lvl <= wr_ptr - rd_ptr;
  sts_full <= '1' when fill_lvl = DEPTH else '0';
  sts_alm_full <= '1' when fill_lvl >= G_ALM_FULL_LVL else '0';
  sts_empty <= '1' when fill_lvl = 0 else '0';
  sts_alm_empty <= '1' when fill_lvl <= G_ALM_EMPTY_LVL else '0';
  wr_en <= s_valid and s_ready;
  rd_en <= m_valid and m_ready;
  
  ------------------------------------------------------------------------------
  prc_clked : process (clk) begin
    if rising_edge(clk) then

      if wr_en then
        wr_ptr <= wr_ptr + 1;
      end if;
      
      if rd_en then
        rd_ptr <= rd_ptr + 1;
      end if;

      ram(to_integer(wr_ptr(G_DEPTH_P2-1 downto 0))) <= s_data;
      m_data <= ram(to_integer(rd_ptr(G_DEPTH_P2-1 downto 0)));

      if srst then
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
      end if;

    end if;
  end process;

end architecture;
