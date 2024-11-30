################################################################################
# File     : cdc_reset.xdc
# Author   : David Gussler
# Language : Xilinx Design Constraints
# ==============================================================================
# Scoped constraint. Use: "read_xdc -ref cdc_reset cdc_reset.xdc"
# ==============================================================================
# Copyright (c) 2024, David Gussler. All rights reserved.
# You may use, distribute and modify this code under the
# terms of the BSD-2 license: https://opensource.org/license/bsd-2-clause
################################################################################

set_false_path -to [get_cells unique_net_false_path*]
