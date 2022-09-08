# Contents:
### `src`
All hand-written source files used to implement the desired logic behavior, to then be packaged into a custom IP via the AXI4 peripheral and finally inserted into an HDL wrapper for synthesis & implementation.
### `gen`
The 3 output files needed to actually realize the VHDL design on hardware——directly deriving from the final bitstream generation process, they're what has to be actually flashed onto the physical FPGA.
