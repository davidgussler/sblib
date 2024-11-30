--##############################################################################
--# File     : ram_gen.vhd
--# Author   : David Gussler - davidnguss@gmail.com
--# Language : VHDL '08
--# ============================================================================
--! Vendor agnostic bram generator. Can be used as a tdpr, sdpr, spr, rom, etc.
--! Just leave unused ports disconnected.
--# ============================================================================
--# Copyright (c) 2023-2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types_pkg.all;

entity ram_gen is 
  generic (
    --! Number of "bytes" per addressable ram element; Each "byte" can be exclusivly 
    --! written; Set to 1 if indivudial bytes within each memory word do not 
    --! need to be exclusively written.
    --! Typically this generic is set in conjunction with G_BYTE_WIDTH when byte write
    --! granularity is required. For example: a RAM with 32 bit words and byte
    --! writes would set G_BYTES_PER_ROW=4 and G_BYTE_WIDTH=8. If byte writes are not
    --! required for the same 32 bit RAM, then G_BYTES_PER_ROW=1 and G_BYTE_WIDTH=32
    G_BYTES_PER_ROW : integer range 1 to 64 := 4;

    --! Bit width of each "byte." "Byte" is in quotations because it does not 
    --! necessirially mean 8 bits in this context (but this would typically be
    --! set to 8 if interfacing with a microprocessor).
    G_BYTE_WIDTH : integer range 1 to 64 := 8;

    --! Log base 2 of the memory depth; ie: total size of the memory in bits =
    --! (2**G_ADDR_WIDTH) * (G_BYTES_PER_ROW * G_BYTE_WIDTH)
    G_ADDR_WIDTH : positive := 10;
    
    --! Ram synthesis attribute; Will suggest the style of memory to the synthesizer
    --! but if other generics are set in a way that is incompatible with the 
    --! suggested memory type, then the synthsizer will make the final style 
    --! decision.
    --! If this generic is left blank or if an unknown string is passed in,  
    --! then the synthesizer will decide what to do. 
    --! See Xilinx UG901 - Vivado Synthesis for more information on dedicated BRAMs
    --! Options: "auto", "block", "ultra", "distributed", "registers"
    G_RAM_STYLE : string  := "auto";

    --! Data to initialize the ram with at FPGA startup
    G_RAM_INIT : slv_arr_t(0 to (2**G_ADDR_WIDTH)-1)(G_BYTES_PER_ROW*G_BYTE_WIDTH-1 downto 0)
        := (others=>(others=>'0'));

    --! Read latency
    G_RD_LATENCY  : positive := 1;

    --! Ram mode - True for read first and False for write first
    G_READ_FIRST : boolean := true
  );
  port (
    a_clk  : in std_logic := '0';
    a_en   : in std_logic := '1';
    a_wen  : in std_logic_vector(G_BYTES_PER_ROW-1 downto 0) := (others=>'0');
    a_addr : in std_logic_vector(G_ADDR_WIDTH-1 downto 0) := (others=>'0');
    a_wdat : in std_logic_vector(G_BYTES_PER_ROW*G_BYTE_WIDTH-1 downto 0) := (others=>'0');
    a_rdat : out std_logic_vector(G_BYTES_PER_ROW*G_BYTE_WIDTH-1 downto 0);
    b_clk  : in std_logic := '0';
    b_en   : in std_logic := '1';
    b_wen  : in std_logic_vector(G_BYTES_PER_ROW-1 downto 0) := (others=>'0');
    b_addr : in std_logic_vector(G_ADDR_WIDTH-1 downto 0) := (others=>'0');
    b_wdat : in std_logic_vector(G_BYTES_PER_ROW*G_BYTE_WIDTH-1 downto 0) := (others=>'0');
    b_rdat : out std_logic_vector(G_BYTES_PER_ROW*G_BYTE_WIDTH-1 downto 0)
  );
end entity;

architecture rtl of ram_gen is 

  -- ---------------------------------------------------------------------------
  constant DATA_WIDTH : integer := G_BYTES_PER_ROW * G_BYTE_WIDTH;
  
  -- ---------------------------------------------------------------------------
  signal a_idx : natural range 0 to 2**G_ADDR_WIDTH-1; 
  signal b_idx : natural range 0 to 2**G_ADDR_WIDTH-1;
  signal a_pipe : slv_arr_t(0 to G_RD_LATENCY-1)(DATA_WIDTH-1 downto 0);
  signal b_pipe : slv_arr_t(0 to G_RD_LATENCY-1)(DATA_WIDTH-1 downto 0);
  
  -- ---------------------------------------------------------------------------
  -- Using an unprotected shared vairable is NOT compliant with VHDL 08, BUT
  -- this is still how Xilinx recommends implementing a DPRAM... Sigh...
  -- You will get a synthesis warning but it can be ignored.
  shared variable ram : slv_arr_t(0 to 2**G_ADDR_WIDTH-1)(DATA_WIDTH-1 downto 0) 
      := G_RAM_INIT;

  -- ---------------------------------------------------------------------------
  attribute ram_style : string;
  attribute ram_style of ram : variable is G_RAM_STYLE;

begin

  -- ---------------------------------------------------------------------------
  prc_porta : process (a_clk) begin
    if rising_edge(a_clk) then 

      if a_en then

        if G_READ_FIRST then
          a_pipe(0) <= ram(a_idx);
        end if;

        for i in 0 to G_BYTES_PER_ROW-1 loop
          if a_wen(i) then 
            ram(a_idx)(i*G_BYTE_WIDTH+G_BYTE_WIDTH-1 downto i*G_BYTE_WIDTH) := 
                a_wdat(i*G_BYTE_WIDTH+G_BYTE_WIDTH-1 downto i*G_BYTE_WIDTH); 
          end if;
        end loop;

        if G_READ_FIRST = false then
          a_pipe(0) <= ram(a_idx);
        end if;

        a_pipe(1 to G_RD_LATENCY-1) <= a_pipe(0 to G_RD_LATENCY-2); 

      end if; 
    end if;
  end process;

  a_idx <= to_integer(unsigned(a_addr));
  a_rdat <= a_pipe(G_RD_LATENCY-1);


  -- ---------------------------------------------------------------------------
  prc_portb : process (b_clk) begin
    if rising_edge(b_clk) then 

      if b_en then 

        if G_READ_FIRST then
          b_pipe(0) <= ram(b_idx);
        end if;

        for i in 0 to G_BYTES_PER_ROW-1 loop
          if b_wen(i) then 
            ram(b_idx)(i*G_BYTE_WIDTH+G_BYTE_WIDTH-1 downto i*G_BYTE_WIDTH) := 
                b_wdat(i*G_BYTE_WIDTH+G_BYTE_WIDTH-1 downto i*G_BYTE_WIDTH); 
          end if;
        end loop;

        if G_READ_FIRST = false then
          b_pipe(0) <= ram(b_idx);
        end if;

        b_pipe(1 to G_RD_LATENCY-1) <= b_pipe(0 to G_RD_LATENCY-2); 

      end if; 
    end if;
  end process;

  b_idx <= to_integer(unsigned(b_addr));
  b_rdat <= b_pipe(G_RD_LATENCY-1);

end architecture;
