################################################################################
# File     : cdc_vector.xdc
# Author   : David Gussler
# Language : Xilinx Design Constraints
# ==============================================================================
# Scoped constraint. Use: "read_xdc -ref cdc_vector cdc_vector.xdc"
################################################################################

set src_clk [get_clocks -quiet -of_objects [get_ports "s_clk"]]
set dst_clk [get_clocks -quiet -of_objects [get_ports "m_clk"]]

set src_reg [get_cells {s_data_ff_reg[*]}]
set first_cdc_reg [get_cells {m_data_reg[*]}]

set period [expr {min([get_property PERIOD $src_clk], [get_property PERIOD $dst_clk])}]
set_max_delay -datapath_only -from $src_clk -to $first_cdc_reg $period
set_bus_skew -from $src_reg -to $first_cdc_reg $period
