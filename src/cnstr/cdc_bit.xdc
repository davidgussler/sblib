################################################################################
# File     : cdc_bit.xdc
# Author   : David Gussler
# Language : Xilinx Design Constraints
# ==============================================================================
# Scoped constraint. Use: "read_xdc -ref cdc_bit cdc_bit.xdc"
# ==============================================================================
# Copyright (c) 2024, David Gussler. All rights reserved.
# You may use, distribute and modify this code under the
# terms of the BSD-2 license: https://opensource.org/license/bsd-2-clause
################################################################################

set src_clk [get_clocks -quiet -of_objects [get_ports "src_clk"]]
set dst_clk [get_clocks -quiet -of_objects [get_ports "dst_clk"]]

if {$src_clk != "" && $dst_clk != ""} {

  set period [expr {min([get_property PERIOD $src_clk], [get_property PERIOD $dst_clk])}]
  set_max_delay -datapath_only -from $src_clk -to [get_cell cdc_regs0*] $period
  set_bus_skew -from [get_cell dont_touch_src_bit*] -to [get_cell cdc_regs0*] $period

} else {

  set_false_path -setup -hold -to [get_cell dont_touch_src_bit*]

}
