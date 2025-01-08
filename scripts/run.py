################################################################################
# Script to run simulations with questasim via VUnit
#
# Requires:
#   pip install vunit
#   questasim
#
# Useage: "python run.py" or "python run.py -h" for more options
# 
################################################################################

from pathlib import Path
from vunit import VUnit
import os

VU = VUnit.from_argv()
VU.add_vhdl_builtins()
VU.add_osvvm()
VU.add_verification_components()

SCRIPT_DIR = Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent
VIVADO_DIR = Path(os.environ['XILINX_VIVADO'])
UNISIM_DIR = Path(VIVADO_DIR / "data" / "vhdl" / "src" / "unisims")

# Libraries

src = VU.add_library("src")
unisim = VU.add_library("unisim")

unisim.add_source_files(UNISIM_DIR / "unisim_VPKG.vhd")
unisim.add_source_files(UNISIM_DIR / "unisim_retarget_VCOMP.vhd")
unisim.add_source_files(UNISIM_DIR / "primitive/*.vhd")
unisim.add_source_files(UNISIM_DIR / "retarget/*.vhd")

# Import files
# src.add_source_files(ROOT_DIR / "src" / "type_pkg.vhd")
#src.add_source_files(ROOT_DIR / "src" / "axis_pipe.vhd")
# src.add_source_files(ROOT_DIR / "src" / "axis_fifo.vhd")
# src.add_source_files(ROOT_DIR / "test" / "axis_fifo_tb.vhd")
# src.add_source_files(ROOT_DIR / "src" / "cdc_bit.vhd")
# src.add_source_files(ROOT_DIR / "src" / "cdc_pulse.vhd")
# src.add_source_files(ROOT_DIR / "test" / "cdc_pulse_tb.vhd")

src.add_source_files(ROOT_DIR / "src" / "cdc_bit" / "*.vhd")
src.add_source_files(ROOT_DIR / "src" / "dru" / "*.vhd")
src.add_source_files(ROOT_DIR / "test" / "prbs.vhd")
src.add_source_files(ROOT_DIR / "test" / "dru_tb.vhd")

# Questa flags
src.set_compile_option("modelsim.vcom_flags", ["+acc",  "-O0"])

VU.main()

print("All done... Great success!")
