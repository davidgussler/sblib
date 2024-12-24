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
    G_WIDTH : positive := 1
  );
  port (
    --! Source clock; Only needed if 'G_USE_SRC_CLK' is true
    src_clk : in    std_logic := '0';
    --! Source bits
    src_bit : in    std_logic_vector(G_WIDTH - 1 downto 0);
    --! Destination clock
    dst_clk : in    std_logic;
    --! Destination bits
    dst_bit : out   std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity cdc_bit;

architecture rtl of cdc_bit is

  -- ---------------------------------------------------------------------------
  type cdc_regs_t is array (natural range 0 to G_SYNC_LEN - 2) of 
    std_logic_vector(G_WIDTH - 1 downto 0);

  -- ---------------------------------------------------------------------------
  signal cdc_regs0 : std_logic_vector(G_WIDTH - 1 downto 0);
  signal cdc_regs           : cdc_regs_t;
  signal dont_touch_src_bit : std_logic_vector(G_WIDTH - 1 downto 0);

  -- ---------------------------------------------------------------------------
  attribute async_reg                : string;
  attribute async_reg of sr          : signal is "TRUE";
  attribute shreg_extract            : string;
  attribute shreg_extract of sr      : signal is "NO";
  attribute dont_touch               : string;
  attribute dont_touch of dont_touch_src_bit : signal is "TRUE";

begin

  -- ---------------------------------------------------------------------------
  gen_src_clk : if G_USE_SRC_CLK generate

    p_src_clk : process (src_clk) is begin
      if rising_edge(src_clk) then
        dont_touch_src_bit <= src_bit;
      end if;
    end process p_src_clk;

  else generate

    dont_touch_src_bit <= src_bit;

  end generate;

  -- ---------------------------------------------------------------------------
  prc_bit_sync : process (dst_clk) is begin
    if rising_edge(dst_clk) then
      cdc_regs0 <= dont_touch_src_bit;
      cdc_regs(0) <= cdc_regs0;
      
      for i in 1 to cdc_regs'high loop
        cdc_regs(i) <= cdc_regs(i - 1);
      end loop;

    end if;
  end process;

  dst_bit <= cdc_regs(cdc_regs'high);

end architecture;
