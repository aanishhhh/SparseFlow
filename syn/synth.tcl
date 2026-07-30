# SparseFlow - Yosys synthesis script
# Target: Nangate 45nm FreePDK

yosys -import

# Read RTL
read_verilog -sv rtl/sparseflow_pkg.sv
read_verilog -sv rtl/sparse_mac.sv
read_verilog -sv rtl/sparsity_ctrl.sv
read_verilog -sv rtl/input_buffer.sv
read_verilog -sv rtl/output_buffer.sv
read_verilog -sv rtl/sparseflow_top.sv

# Synthesize
synth -top sparseflow_top -flatten

# Technology mapping
dfflibmap -liberty /home/aanish/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib
abc -liberty /home/aanish/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib

# Reports
stat -liberty /home/aanish/OpenROAD-flow-scripts/flow/platforms/nangate45/lib/NangateOpenCellLibrary_typical.lib

# Write netlist
write_verilog syn/sparseflow_netlist.v
