################################################################################
# File     : cdc_vector.xdc
# Author   : David Gussler
# Language : Xilinx Design Constraints
# ==============================================================================
# Scoped constraint. Use: "read_xdc -ref cdc_vector cdc_vector.xdc"
# ==============================================================================
# Copyright (c) 2024, David Gussler. All rights reserved.
# You may use, distribute and modify this code under the
# terms of the BSD-2 license: https://opensource.org/license/bsd-2-clause
################################################################################

set src_clk [get_clocks -of_objects [get_cell unique_net_src_data*]]
set dst_clk [get_clocks -of_objects [get_cell unique_net_dst_data*]]

set period [expr min([get_property PERIOD $src_clk], [get_property PERIOD $dst_clk])]

set_max_delay -from $src_clk -to [get_cell unique_net_dst_data*] -datapath_only $period
set_bus_skew -from [get_cell unique_net_src_data*] -to [get_cell unique_net_dst_data*] $period
