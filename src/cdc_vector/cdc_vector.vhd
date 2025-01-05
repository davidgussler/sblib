--#############################################################################
--# File     : cdc_vector.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ===========================================================================
--! Handshake vector synchronizer based on AXIS
--# ===========================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--#############################################################################

library ieee;
use ieee.std_logic_1164.all;

entity cdc_vector is
  generic (
    --! Number of synchronizer flip-flops
    G_SYNC_LEN : positive range 2 to 16 := 2
  );
  port (
    src_clk    : in  std_logic;
    src_valid  : in  std_logic;
    src_ready  : out std_logic;
    src_data   : in  std_logic_vector;
    --
    dst_clk    : in  std_logic;
    dst_valid  : out std_logic;
    dst_ready  : in  std_logic;
    dst_data   : out std_logic_vector
  );
end entity;

architecture rtl of cdc_vector is

  -- ---------------------------------------------------------------------------
  signal src_valid_ff        : std_logic;
  signal src_ready_ff        : std_logic;
  signal src_req_pulse       : std_logic;
  signal src_ack_pulse       : std_logic;
  signal dst_req_pulse       : std_logic;
  signal dst_ack_pulse       : std_logic;
  signal dont_touch_src_data : std_logic_vector;
  signal dont_touch_dst_data : std_logic_vector;

  -- ---------------------------------------------------------------------------
  attribute dont_touch                        : string;
  attribute dont_touch of dont_touch_src_data : signal is "TRUE";
  attribute dont_touch of dont_touch_dst_data : signal is "TRUE";

begin

  -- Registers to help determine if a new request is active
  process (src_clk) begin
    if rising_edge(src_clk) then
      src_valid_ff <= src_valid;
      src_ready_ff <= src_ready;
      dont_touch_src_data <= src_data; 
    end if;
  end process;

  -- New request if rising edge of valid or new valid after previous ready
  src_req_pulse <= (src_valid and not src_valid_ff) or (src_valid and src_ready_ff);

  -- CDC the request to the destination domain
  u_cdc_pulse_req : entity work.cdc_pulse
  generic map (
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH    => 1
  )
  port map (
    src_clk      => src_clk,
    src_pulse(0) => src_req_pulse,
    dst_clk      => src_clk,
    dst_pulse(0) => dst_req_pulse
  );

  -- Hold destination valid high until destination is ready to accept transation
  process (dst_clk) begin
    if rising_edge(dst_clk) then
      if dst_req_pulse then
        dst_valid <= '1';
        dont_touch_dst_data <= dont_touch_src_data;
      elsif dst_valid and dst_ready then
        dst_valid <= '0';
      end if;
    end if;
  end process;
  dst_data <= dont_touch_dst_data; 

  -- Ack when a valid transaction has completed
  dst_ack_pulse <= dst_valid and dst_ready;

  -- CDC the acknowledge to the source domain
  u_cdc_pulse_ack : entity work.cdc_pulse
  generic map (
    G_SYNC_LEN => G_SYNC_LEN,
    G_WIDTH    => 1
  )
  port map (
    src_clk      => dst_clk,
    src_pulse(0) => dst_ack_pulse,
    dst_clk      => src_clk,
    dst_pulse(0) => src_ack_pulse
  );
  src_ready <= src_ack_pulse;
  
end architecture;
