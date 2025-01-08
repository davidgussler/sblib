from pathlib import Path
from vunit import VUnit

vu = VUnit.from_argv()
vu.add_vhdl_builtins()
vu.add_osvvm()
vu.add_verification_components()

SCRIPT_DIR = Path(__file__).parent
ROOT_DIR = SCRIPT_DIR.parent

src = vu.add_library("src")
src.add_source_files(ROOT_DIR / "src" / "async_rxr.vhd")
src.add_source_files(ROOT_DIR / "test" / "prbs.vhd")
src.add_source_files(ROOT_DIR / "test" / "async_rxr_tb.vhd")

src.set_compile_option("modelsim.vcom_flags", ["+acc",  "-O0"])

vu.main()

print("All done... Great success!")
