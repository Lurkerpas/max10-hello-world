# MAX10 Hello world
Hello world example for [Maximator FPGA](https://maximator-fpga.org/) with [Altera MAX10](https://www.altera.com/products/fpga/max-10) chip. This project is a hobby endeavour, not associated with Altera. 

Its purpose is to test and demonstrate the capability to program the device from CLI/Makefile, using Quartus as a backend, without launching its GUI.

# Structure

- rtl/ contains the HDL files
- tb/ contains the test bench for ghdl
- .qpf file provides top level metadata
- .qsf file provides device and pin assignments
- .sdf file configures the clock
- Makefile orchestrates the verification, compilation and programming process

# Prerequisites

```QUARTUS_BIN``` variable must point to existing Quartus installation.
Make and ghdl must be installed on the system.

Run:

```bash
make verify
```
to verify the design using GHDL,
```bash
make program
```
to upload the design to volatile memory, or
```bash
make flash
```
to flash it to persistent memory that survives power reset.