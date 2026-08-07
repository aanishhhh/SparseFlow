export DESIGN_NAME = sparseflow_top
export PLATFORM    = nangate45

export VERILOG_FILES = $(DESIGN_DIR)/results/sparseflow_netlist.v
export SDC_FILE      = $(DESIGN_DIR)/pnr/constraint.sdc

export CORE_UTILIZATION = 40
export CORE_ASPECT_RATIO = 1
export CORE_MARGIN = 2

export PLACE_DENSITY = 0.60
export TNS_END_PERCENT = 100
