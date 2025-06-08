--##############################################################################
--# File : axil_arbiter.vhd
--# Auth : David Gussler
--# Lang : VHDL '08
--# ============================================================================
--! AXI Lite N:1 arbiter
--! TODO: INCOMPLETE
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use work.util_pkg.all;

entity axil_arbiter is
  generic (
    G_NUM_MASTERS : positive
  );
  port (
    clk        : in    std_logic;
    srst       : in    std_logic;
    s_axil_req : in    axil_req_arr_t(0 to G_NUM_MASTERS - 1);
    s_axil_rsp : out   axil_rsp_arr_t(0 to G_NUM_MASTERS - 1);
    m_axil_req : out   axil_req_t;
    m_axil_rsp : in    axil_rsp_t
  );
end entity;

architecture rtl of axil_arbiter is

begin

end architecture;
