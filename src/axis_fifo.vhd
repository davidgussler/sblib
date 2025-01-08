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

  type ram_t is array (natural range 0 to DEPTH-1) of 
    std_logic_vector(G_WIDTH-1 downto 0);

  signal ram         : ram_t; 
  signal wr_en       : std_logic;
  signal rd_en       : std_logic;
  signal rd_and_wr_en_ff       : std_logic;
  signal wr_ptr      : unsigned(G_DEPTH_P2 downto 0);
  signal rd_ptr      : unsigned(G_DEPTH_P2 downto 0);
  signal fill_lvl    : unsigned(G_DEPTH_P2 downto 0);
  signal fill_lvl_ff : unsigned(G_DEPTH_P2 downto 0);

begin

  ------------------------------------------------------------------------------
  sts_fill_lvl <= std_logic_vector(fill_lvl);
  s_ready <= not sts_full;
  --m_valid <= not sts_empty;
  fill_lvl <= wr_ptr - rd_ptr;
  sts_full <= '1' when fill_lvl = DEPTH else '0';
  sts_alm_full <= '1' when fill_lvl >= G_ALM_FULL_LVL else '0';
  sts_empty <= '1' when fill_lvl = 0 else '0';
  sts_alm_empty <= '1' when fill_lvl <= G_ALM_EMPTY_LVL else '0';
  wr_en <= s_valid and s_ready;
  rd_en <= m_valid and m_ready;


  -- prc_asdf : process (all) begin
  --   m_valid <= '1'; 

  --   if (fill_lvl = 0 or fill_lvl_ff = 0) or (fill_lvl = 1 and rd_and_wr_en_ff = '1') then 
  --     m_valid <= '0'; 
  --   end if; 

  -- end process;
  
  ------------------------------------------------------------------------------
  prc_ptr : process (clk) begin
    if rising_edge(clk) then

      --fill_lvl <= wr_ptr - rd_ptr;
      m_valid <= not sts_empty;
      rd_and_wr_en_ff <= wr_en and rd_en; 
      fill_lvl_ff <= fill_lvl; 

      if wr_en then
        wr_ptr <= wr_ptr + 1;
      end if;
      
      if rd_en then
        rd_ptr <= rd_ptr + 1;
      end if;

      if srst then
        m_valid <= '0';
        --fill_lvl <= (others => '0');
        rd_and_wr_en_ff <= '0'; 
        fill_lvl_ff <= (others => '0');
        wr_ptr <= (others => '0');
        rd_ptr <= (others => '0');
      end if;

    end if;
  end process;

  prc_ram : process (clk) begin
    if rising_edge(clk) then
      ram(to_integer(wr_ptr(G_DEPTH_P2-1 downto 0))) <= s_data;
      m_data <= ram(to_integer(rd_ptr(G_DEPTH_P2-1 downto 0)));
    end if;
  end process;
  --m_data <= ram(to_integer(rd_ptr(G_DEPTH_P2-1 downto 0)));

  
end architecture;
