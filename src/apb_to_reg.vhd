--##############################################################################
--# File     : apb_to_reg.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! APB to register bus bridge
--# ============================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

-- TODO: add generic option to define the number of cycles of latency that the
-- sbb interface takes to repond for reads.

library ieee;
use ieee.std_logic_1164.all;
use work.types_pkg.all;

entity apb_to_reg is
  port (
    clk   : in std_logic;
    srst  : in std_logic;
    --
    s_apb_req : in  apb_req_t;
    s_apb_rsp : out apb_rsp_t;
    --
    m_reg_req : out reg_req_t;
    m_reg_rsp : in  reg_rsp_t
  );
end entity;

architecture rtl of apb_to_reg is

begin

end architecture;