--##############################################################################
--# File     : types_pkg.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! Common VHDL types
--# ============================================================================
--# Copyright (c) 2023-2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;

package types_pkg is

  -- ---------------------------------------------------------------------------
  -- AXI Lite
  type axil_req_t is record
    awvalid : std_logic;
    awaddr  : std_logic_vector(31 downto 0);
    awprot  : std_logic_vector( 2 downto 0);
    wvalid  : std_logic;
    wdata   : std_logic_vector(31 downto 0);
    wstrb   : std_logic_vector( 3 downto 0);
    bready  : std_logic;
    arvalid : std_logic;
    araddr  : std_logic_vector(31 downto 0);
    arprot  : std_logic_vector( 2 downto 0);
    rready  : std_logic;
  end record;

  type axil_rsp_t is record
    awready : std_logic;
    wready  : std_logic;
    bvalid  : std_logic;
    bresp   : std_logic_vector( 1 downto 0);
    arready : std_logic;
    rvalid  : std_logic;
    rdata   : std_logic_vector(31 downto 0);
    rresp   : std_logic_vector( 1 downto 0);
  end record;

  type axil_req_arr_t is array (natural range <>) of axil_req_t;
  type axil_rsp_arr_t is array (natural range <>) of axil_rsp_t;

  constant AXI_RSP_OKAY   : std_logic_vector(1 downto 0) := b"00";
  constant AXI_RSP_EXOKAY : std_logic_vector(1 downto 0) := b"01";
  constant AXI_RSP_SLVERR : std_logic_vector(1 downto 0) := b"10";
  constant AXI_RSP_DECERR : std_logic_vector(1 downto 0) := b"11";

  -- ---------------------------------------------------------------------------
  -- Advanced Peripheral Bus
  type apb_req_t is record
    psel    : std_logic;
    penable : std_logic;
    pwrite  : std_logic;
    pprot   : std_logic_vector( 2 downto 0);
    paddr   : std_logic_vector(31 downto 0);
    pwdata  : std_logic_vector(31 downto 0);
    pstrb   : std_logic_vector( 3 downto 0);
  end record;

  type apb_rsp_t is record
    prdata  : std_logic_vector(31 downto 0);
    pready  : std_logic;
    pslverr : std_logic;
  end record;

  type apb_req_arr_t is array (natural range <>) of apb_req_t;
  type apb_rsp_arr_t is array (natural range <>) of apb_rsp_t;


  -- ---------------------------------------------------------------------------
  -- Register Bus
  -- This is a simple bus interface for basic components that don't need 
  -- most of the features offered by busses like axi / avalon, but 
  -- still require higher performance than can be offered by busses like apb.
  -- Read and write channels can operate independently.
  -- Slave is expected to always respond in a fixed number of cycles that is 
  -- known by the master.
  -- Full duplex communication at 1 transfer per cycle for maximum bandwidth.
  -- Recommended to use this for user logic and connect to an axil adaptor for 
  -- external pipelining and interconnect logic.
  type reg_req_t is record 
    ren   : std_logic;
    raddr : std_logic_vector(31 downto 0);
    wen   : std_logic;
    waddr : std_logic_vector(31 downto 0);
    wstrb : std_logic_vector( 3 downto 0);
    wdata : std_logic_vector(31 downto 0);
  end record;

  type reg_rsp_t is record 
    rdata : std_logic_vector(31 downto 0);
  end record;

  -- ---------------------------------------------------------------------------
  -- Array types
  type sl_arr_t is array (natural range <>) of std_logic;
  type slv_arr_t is array (natural range <>) of std_logic_vector;
  type int_arr_t is array (natural range <>) of integer;
  type bool_arr_t is array (natural range <>) of boolean;

end package;
