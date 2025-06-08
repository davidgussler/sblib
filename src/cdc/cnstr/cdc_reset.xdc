################################################################################
# File : cdc_reset.xdc
# Auth : David Gussler
# Lang : Xilinx Design Constraints
# ==============================================================================
# Scoped constraint. Use: "read_xdc -ref cdc_reset cdc_reset.xdc"
################################################################################

set cdc_regs [get_cells {cdc_regs_reg[*]}]
set_false_path -to $cdc_regs
