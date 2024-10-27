--##############################################################################
--# File     : cdc_bit.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! Simple bit synchronizer. This can be used to sync one bit or several
--! unrelated bits to a common clock. Includes the option to register the
--! input signal before syncing. Also includes the option to reset the ffs.
--# ============================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity cdc_bit is
  generic (
    --! True: Register the input; False: Dont register the input; If set to 
    --! false then src_clk is unused
    G_USE_SRC_CLK : boolean := false;
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive range 2 to 16 := 2;
    --! Number of unrelated bits to synchronize; Ie: the length of 'src_bits' 
    --! and 'dst_bits'
    G_WIDTH : positive := 1;
    --! Reset values for each bit; Only applied if the optional resets are used
    G_RST_VAL : std_logic_vector(G_WIDTH - 1 downto 0) := (others => '0')
  );
  port (
    --! Source clock; Only needed if 'G_USE_SRC_CLK' is true
    src_clk : in    std_logic := '0';
    --! Source bits reset; Optional
    src_srst : in    std_logic := '0';
    --! Source bits
    src_bit : in    std_logic_vector(G_WIDTH - 1 downto 0);
    --! Destination clock
    dst_clk : in    std_logic;
    --! Destination reset; Optional
    dst_srst : in    std_logic := '0';
    --! Destination bits
    dst_bit : out   std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity cdc_bit;

architecture rtl of cdc_bit is

  -- ---------------------------------------------------------------------------
  type sr_t is array (natural range 0 to G_SYNC_LEN - 1) of 
    std_logic_vector(G_WIDTH - 1 downto 0);

  -- ---------------------------------------------------------------------------
  signal sr                    : sr_t;
  signal unique_net_false_path : std_logic_vector(G_WIDTH - 1 downto 0);

  -- ---------------------------------------------------------------------------
  attribute async_reg                           : string;
  attribute shreg_extract                       : string;
  attribute dont_touch                          : string;
  attribute async_reg of sr                     : signal is "TRUE";
  attribute shreg_extract of sr                 : signal is "NO";
  attribute dont_touch of unique_net_false_path : signal is "TRUE";

begin

  -- ---------------------------------------------------------------------------
  g_src_clk : if G_USE_SRC_CLK generate

    p_src_clk : process (src_clk) is begin
      if rising_edge(src_clk) then
        if src_srst then
          unique_net_false_path <= G_RST_VAL;
        else
          unique_net_false_path <= src_bit;
        end if;
      end if;
    end process p_src_clk;

  else generate

    unique_net_false_path <= src_bit;

  end generate g_src_clk;

  -- ---------------------------------------------------------------------------
  prc_bit_sync : process (dst_clk) is begin
    if rising_edge(dst_clk) then
      if dst_srst then
        sr <= (others => G_RST_VAL);
      else
        sr(0) <= unique_net_false_path;
        for i in 1 to G_SYNC_LEN - 1 loop
          sr(i) <= sr(i - 1);
        end loop;
      end if;
    end if;
  end process prc_bit_sync;

  dst_bit <= sr(G_SYNC_LEN - 1);

end architecture rtl;
