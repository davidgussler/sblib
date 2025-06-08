################################################################################
# File     : cdc_bit.tcl
# Author   : David Gussler
# Language : Xilinx Design Constraints
# ==============================================================================
# Scoped constraint. Use: "read_xdc -ref cdc_bit cdc_bit.tcl"
################################################################################

set src_reg [get_cells -quiet {src_reg_reg[*]}]
set first_cdc_reg [get_cells {cdc_regs_reg[0][*]}]

set src_clk [get_clocks -quiet -of_objects $src_reg]
set dst_clk [get_clocks -of_objects $first_cdc_reg]

if {$src_clk != "" && $dst_clk != ""} {

  set period [expr {min([get_property PERIOD $src_clk], [get_property PERIOD $dst_clk])}]
  set_max_delay -datapath_only -from $src_reg -to $first_cdc_reg $period
  set_bus_skew -from $src_reg -to $first_cdc_reg $period

} else {

  set_false_path -setup -hold -to $first_cdc_reg

}
