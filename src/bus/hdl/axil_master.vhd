--##############################################################################
--# File : axil_master.vhd
--# Auth : David Gussler
--# Lang : VHDL '08
--# ============================================================================
--! TODO: Incomplete
--! This is indented to be a generic axi-lite master state machine
--! that runs a hard-coded sequence of read and write commands after reset.
--! Intended to configure an FPGA at startup / reset without the need for
--! software init scripts or a soft-processor.
--##############################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util_pkg.all;

library ieee;
use ieee.std_logic_1164.all;

entity axil_master is
  generic (
    G_START_DELAY_CLKS : positive := 10000;
    G_COMMANDS         : positive -- TODO: Create a custom type for this.
  );
  port (
    clk        : in    std_logic;
    srst       : in    std_logic;
    m_axil_req : out   axil_req_t;
    m_axil_rsp : in    axil_rsp_t
  );
end entity;

architecture rtl of axil_master is

begin

end architecture;
