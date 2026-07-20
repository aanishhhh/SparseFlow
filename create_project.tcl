create_project sparseflow ./sparseflow -part xc7a35tcpg236-1
set_property target_language Verilog [current_project]

# Add RTL design sources
add_files -fileset sources_1 [glob ./rtl/*.sv]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sources_1] *.sv]

# Add UVM simulation sources
add_files -fileset sim_1 [glob ./tb/uvm/*.sv]
add_files -fileset sim_1 [glob ./tb/directed/*.sv]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets sim_1] *.sv]

# Set simulation top
set_property top tb_uvm_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Set UVM version
set_property -name {xsim.simulate.uvm_version} -value {1.2} -objects [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project created successfully"
