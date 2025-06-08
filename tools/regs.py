import sys
import os
from pathlib import Path

from hdl_registers.parser.toml import from_toml
from hdl_registers.generator.vhdl.axi_lite.wrapper import VhdlAxiLiteWrapperGenerator
from hdl_registers.generator.vhdl.record_package import VhdlRecordPackageGenerator
from hdl_registers.generator.vhdl.register_package import VhdlRegisterPackageGenerator
from hdl_registers.generator.vhdl.simulation.check_package import VhdlSimulationCheckPackageGenerator
from hdl_registers.generator.vhdl.simulation.read_write_package import VhdlSimulationReadWritePackageGenerator
from hdl_registers.generator.vhdl.simulation.wait_until_package import VhdlSimulationWaitUntilPackageGenerator
from hdl_registers.generator.c.header import CHeaderGenerator
from hdl_registers.generator.cpp.header import CppHeaderGenerator
from hdl_registers.generator.cpp.implementation import CppImplementationGenerator
from hdl_registers.generator.cpp.interface import CppInterfaceGenerator
from hdl_registers.generator.html.constant_table import HtmlConstantTableGenerator
from hdl_registers.generator.html.page import HtmlPageGenerator
from hdl_registers.generator.html.register_table import HtmlRegisterTableGenerator
from hdl_registers.generator.python.accessor import PythonAccessorGenerator
from hdl_registers.generator.python.pickle import PythonPickleGenerator


THIS_DIR = Path(__file__).parent


def main(toml_files: list[Path]):
    """
    Create register artifacts from a toml file
    """

    for toml_file in toml_files:
        name = toml_file.stem
        output_dir = Path(THIS_DIR.parent / "build" / "regs_out" / name)
        hdl_output_dir = Path(output_dir / "hdl")

        register_list = from_toml(name=name, toml_file=toml_file)

        # VHDL
        VhdlRegisterPackageGenerator(register_list=register_list, output_folder=hdl_output_dir).create_if_needed()
        VhdlRecordPackageGenerator(register_list=register_list, output_folder=hdl_output_dir).create_if_needed()
        VhdlAxiLiteWrapperGenerator(register_list=register_list, output_folder=hdl_output_dir).create_if_needed()
        # VhdlSimulationReadWritePackageGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()
        # VhdlSimulationCheckPackageGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()
        # VhdlSimulationWaitUntilPackageGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()

        # C Header
        CHeaderGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()

        # C++
        # CppInterfaceGenerator(register_list=register_list, output_folder=output_dir / "include").create_if_needed()
        # CppHeaderGenerator( register_list=register_list, output_folder=output_dir / "include").create_if_needed()
        # CppImplementationGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()

        # HTML
        HtmlPageGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()
        # HtmlRegisterTableGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()
        # HtmlConstantTableGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()

        # Python
        # PythonPickleGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()
        # PythonAccessorGenerator(register_list=register_list, output_folder=output_dir).create_if_needed()


if __name__ == "__main__":
    main(toml_files=[Path(s) for s in sys.argv[1:] if os.path.exists(s)])
