--##############################################################################
--# File     : axis_pipe.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! AXI stream pipeline register. Also known as a skid buffer.
--# ============================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

-- TODO: add generic option to define the number of cycles of latency that the
-- sbb interface takes to repond for reads.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_pipe is
  generic (
    --! Mode options:
    --! * PASSTHRU
    --! * SLAVE
    --! * MASTER
    --! * FULL
    G_MODE : string := "FULL"
  );
  port(
    clk     : in  std_logic;
    srst    : in  std_logic;
    --
    s_valid : in  std_logic;
    s_ready : out std_logic;
    s_data  : in  std_logic_vector;
    --
    m_valid : out std_logic;
    m_ready : in  std_logic;
    m_data  : out std_logic_vector
  );
end;

architecture rtl of axis_pipe is

begin

  -- ---------------------------------------------------------------------------
  gen_axis_pipe : if G_MODE = "PASSTHRU" generate
  begin

    m_valid <= s_valid;
    s_ready <= m_ready;
    m_data <= s_data;

  -- ---------------------------------------------------------------------------
  -- Registers the slave interface's output ready signal
  elsif G_MODE = "SLAVE" generate

    signal data_buff : std_logic_vector(s_data'range); 

  begin 

    prc_slave : process (clk)
    begin
      if rising_edge(clk) then

        if s_ready then 
          data_buff <= s_data;
        end if; 

        if m_valid then 
          s_ready <= m_ready; 
        end if; 

        if srst then
          s_ready <= '1';
        end if;
      end if;
    end process;

    m_valid <= s_valid or not s_ready;
    m_data <= s_data when s_ready else data_buff; 

  -- ---------------------------------------------------------------------------
  -- Registers the master interface's output valid and data signals
  elsif G_MODE = "MASTER" generate
  begin
    prc_master : process (clk)
    begin
      if rising_edge(clk) then

        if s_ready then 
          m_valid <= s_valid;
          m_data <= s_data;
        end if; 

        if srst then
          m_valid <= '0';
        end if;
      end if;
    end process;

    s_ready <= m_ready or not m_valid;

  -- ---------------------------------------------------------------------------
  -- Registers both the slave interface's ready signal along with the master
  -- interface's data and valid signals. All this does is combine the previous 
  -- two modes. This could have been done by creating a new module that 
  -- instantiates this module twice, one with master mode and the other with 
  -- slave mode, but it was cleaner to just keep everything in one module, even
  -- if it means that we have to repeat some logic here.
  elsif G_MODE = "FULL" generate

    signal data_buff : std_logic_vector(s_data'range); 
    signal valid_int : std_logic;
    signal ready_int : std_logic;
    signal data_int  : std_logic_vector(s_data'range);

  begin

    prc_slave : process (clk) begin
      if rising_edge(clk) then

        if s_ready then 
          data_buff <= s_data;
        end if; 

        if valid_int then 
          s_ready <= ready_int; 
        end if; 

        if srst then
          s_ready <= '1';
        end if;
      end if;
    end process;

    valid_int <= s_valid or not s_ready;
    data_int <= s_data when s_ready else data_buff; 


    prc_master : process (clk) begin
      if rising_edge(clk) then

        if ready_int then 
          m_valid <= valid_int;
          m_data <= data_int;
        end if; 

        if srst then
          m_valid <= '0';
        end if;
      end if;
    end process;

    ready_int <= m_ready or not m_valid;

  -- ---------------------------------------------------------------------------
  -- Unknown mode - error
  else generate
  begin 

    assert false
    report "ERROR: axis_pipe G_MODE = < PASSTHRU | SLAVE | MASTER | FULL >"
    severity error;

  end generate;

end architecture;
