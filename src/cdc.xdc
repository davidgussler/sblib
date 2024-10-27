################################################################################
# File     : cdc.xdc
# Author   : David Gussler
# Language : Xilinx Design Constraints
# ==============================================================================
# Constraints get automatically applied to the synchronizer
# ==============================================================================
# Copyright (c) 2024, David Gussler. All rights reserved.
# You may use, distribute and modify this code under the
# terms of the BSD-2 license: https://opensource.org/license/bsd-2-clause
################################################################################

set_false_path -through [get_nets -hier -filter {NAME =~ *unique_net_false_path*}]
