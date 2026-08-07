create_clock [get_ports clk] -name core_clk -period 5.0
set_input_delay  -clock core_clk 1.0 [all_inputs]
set_output_delay -clock core_clk 1.0 [all_outputs]
set_driving_cell -lib_cell BUF_X1 -pin Z [all_inputs]
set_load 10 [all_outputs]
