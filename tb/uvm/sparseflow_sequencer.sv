`ifndef SPARSEFLOW_SEQUENCER_SV
`define SPARSEFLOW_SEQUENCER_SV
// ============================================================
// sparseflow_sequencer.sv
// SparseFlow - UVM sequencer
//
// Manages the flow of seq_items from sequences to the driver.
// uvm_sequencer's built-in behavior is sufficient here - we
// just parameterize it with our transaction type. No custom
// logic needed for this project's scope.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

class sparseflow_sequencer extends uvm_sequencer #(sparseflow_seq_item);

  `uvm_component_utils(sparseflow_sequencer)

  function new(string name = "sparseflow_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : sparseflow_sequencer
`endif
