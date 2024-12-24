--##############################################################################
--# File     : axil_to_reg.vhd
--# Author   : David Gussler
--# Language : VHDL '08
--# ============================================================================
--! AXI lite to register bus bridge
--# ============================================================================
--# Copyright (c) 2024, David Gussler. All rights reserved.
--# You may use, distribute and modify this code under the
--# terms of the MIT license: https://choosealicense.com/licenses/mit/
--##############################################################################

-- TODO: add generic option to define the number of cycles of latency that the
-- sbb interface takes to repond for reads.

library ieee;
use ieee.std_logic_1164.all;
use work.type_pkg.all;

entity axil_to_reg is
  port (
    clk   : in std_logic;
    srst  : in std_logic;
    --
    s_axil_req : in  axil_req_t;
    s_axil_rsp : out axil_rsp_t;
    --
    m_reg_req : out reg_req_t;
    m_reg_rsp : in  reg_rsp_t
  );
end entity;

architecture rtl of axil_to_reg is

  signal awvalid : std_logic;
  signal awaddr  : std_logic_vector(31 downto 0);
  signal wvalid  : std_logic;
  signal wdata   : std_logic_vector(31 downto 0);
  signal wstrb   : std_logic_vector( 3 downto 0);
  signal arvalid : std_logic;
  signal araddr  : std_logic_vector(31 downto 0);
  signal awready : std_logic;
  signal wready  : std_logic;
  signal arready : std_logic;

  signal wdata_strb_concat : std_logic_vector(35 downto 0);

  signal wen : std_logic;
  signal ren : std_logic;

begin

  -- ===========================================================================
  -- Writes 
  -- ===========================================================================

  -- Write address skid buffer
  u_axis_pipe_aw : entity work.axis_pipe
  generic map (
    G_MODE => "SLAVE"
  )
  port map (
    clk     => clk,
    srst    => srst,
    s_valid => s_axil_req.awvalid,
    s_ready => s_axil_rsp.awready,
    s_data  => s_axil_req.awaddr,
    m_valid => awvalid,
    m_ready => awready,
    m_data  => awaddr
  );

  -- Write data skid buffer
  u_axis_pipe_w : entity work.axis_pipe
  generic map (
    G_MODE => "SLAVE"
  )
  port map (
    clk     => clk,
    srst    => srst,
    s_valid => s_axil_req.wvalid,
    s_ready => s_axil_rsp.wready,
    s_data  => s_axil_req.wstrb & s_axil_req.wdata,
    m_valid => wvalid,
    m_ready => wready,
    m_data  => wdata_strb_concat
  );
  wstrb <= wdata_strb_concat(35 downto 32);
  wdata <= wdata_strb_concat(31 downto 0);

  -- Enable an outgoing write request when the incoming write address and write
  -- data are valid and when the last write response is not stalled.
  wen <= 
    awvalid and wvalid and not (s_axil_rsp.bvalid and not s_axil_req.bready);
  
  -- wready and awready are tied to wen. This makes the write transaction go 
  -- thru. Although this looks like we are combinatorially setting the ready 
  -- outputs, since we send the readys thru an axis pipeline module first, the 
  -- paths get broken up there. The axis pipeline modules handle the axi 
  -- buffering to ensure that no transactions are dropped. 
  wready  <= wen;
  awready <= wen; 

  -- Set write response to valid the cycle after the write request 
  -- since our simple bus always responds in one cycle. If another write is 
  -- not happening and the master has set bready high, then we can now lower 
  -- bvalid to end the write response transaction.
  prc_bvalid : process (clk) begin
    if rising_edge(clk) then
      if srst then
        s_axil_rsp.bvalid <= '0'; 
      else
        if wen then
          s_axil_rsp.bvalid <= '1';
        elsif s_axil_req.bready then
          s_axil_rsp.bvalid <= '0'; 
        end if;
      end if; 
    end if;
  end process;

  -- Always respond with OKAY. Our simple bus does not support slave errors.
  s_axil_rsp.bresp <= AXI_RSP_OKAY;

  -- Set sbb write request outputs
  m_reg_req.wen   <= wen; 
  m_reg_req.waddr <= awaddr;
  m_reg_req.wdata <= wdata;
  m_reg_req.wstrb <= wstrb;


  -- ===========================================================================
  -- Reads
  -- ===========================================================================

  -- Read address skid buffer
  u_axis_pipe_ar : entity work.axis_pipe
  generic map (
    G_MODE => "SLAVE"
  )
  port map (
    clk     => clk,
    srst    => srst,
    s_valid => s_axil_req.arvalid,
    s_ready => s_axil_rsp.arready,
    s_data  => s_axil_req.araddr,
    m_valid => arvalid,
    m_ready => arready,
    m_data  => araddr
  );

  -- Enable an outgoing read request when the incoming read address
  -- is valid and when the last read response is not stalled. Reads are a bit
  -- simpler than writes because we only have to wait for one of the incoming 
  -- channels to become valid (ar) instead of wiiting for two of them (aw & w).
  ren <= arvalid and not (s_axil_rsp.rvalid and not s_axil_req.rready);

  -- arready becomes enabled at the same time as ren to complete the data 
  -- transfer
  arready <= ren; 

  -- Set read response to valid the cycle after the read request 
  -- since our simple bus always responds with the read data in one cycle.
  -- If another read is not happening and the master has set rready high, 
  -- then we can now lower rvalid to end the read response transaction.
  prc_rvalid : process (clk) begin
    if rising_edge(clk) then
      if srst then
        s_axil_rsp.rvalid <= '0'; 
      else
        if ren then
          s_axil_rsp.rvalid <= '1';
        elsif s_axil_req.rready then
          s_axil_rsp.rvalid <= '0'; 
        end if;
      end if;
    end if;
  end process;

  -- Always respond with OKAY. Our simple bus does not support slave errors.
  -- Also respond with the read data
  s_axil_rsp.rresp <= AXI_RSP_OKAY;
  s_axil_rsp.rdata <= m_reg_rsp.rdata;

  -- Set regb read request outputs
  m_reg_req.ren   <= ren; 
  m_reg_req.raddr <= araddr;

end architecture;
