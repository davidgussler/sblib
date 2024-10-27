--##############################################################################
--# File     : ram_sdp.vhd
--# Author   : David Gussler - davidnguss@gmail.com
--# Language : VHDL '08
--# ============================================================================
--! Simple dual port ram
--# ============================================================================
--# Copyright (c) 2023-2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sdp is
  generic (
    G_DEPTH_P2 : integer := 4;
    G_WIDTH : integer := 32;
    G_REG_OUT : boolean := true 
  ); 
  port (
    i_clk  : in std_logic;
    i_rst  : in std_logic;
    
    i_a_wr  : in std_logic;
    i_a_adr : in std_logic_vector(G_DEPTH_P2-1 downto 0); 
    i_a_din : in std_logic_vector(G_WIDTH-1 downto 0); 

    i_b_rd   : in std_logic;
    i_b_adr  : in std_logic_vector(G_DEPTH_P2-1 downto 0); 
    o_b_dout : out std_logic_vector(G_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of ram_sdp is 

  -- ---------------------------------------------------------------------------
  constant DEPTH : integer := 2 ** G_DEPTH_P2;

  -- ---------------------------------------------------------------------------
  type ram_t is array (natural range 0 to DEPTH - 1) of
    std_logic_vector(G_WIDTH - 1 downto 0);
  
  -- ---------------------------------------------------------------------------
  signal ram : ram_t;
  signal b_dout : std_logic_vector(G_WIDTH-1 downto 0);

begin

  -- ---------------------------------------------------------------------------
  prc_ram : process (i_clk) begin
    if rising_edge(i_clk) then
      if i_a_wr then
        ram(to_integer(unsigned(i_a_adr))) <= i_a_din;
      end if;

      if i_b_rd then
        b_dout <= ram(to_integer(unsigned(i_b_adr)));
      end if;

    end if;
  end process;

  -- ---------------------------------------------------------------------------
  gen_reg_out : if G_REG_OUT generate    

    prc_reg_out : process (i_clk) begin
      if rising_edge(i_clk) then
        if i_rst then
          o_b_dout <= (others => '0');
        else
          o_b_dout <= b_dout;
        end if;
      end if;
    end process;

  else generate

    o_b_dout <= b_dout;

  end generate;

end architecture;
