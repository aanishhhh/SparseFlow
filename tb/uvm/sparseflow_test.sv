// ============================================================
// sparseflow_test.sv
// SparseFlow - top-level UVM test
//
// FIX: this file references sparseflow_env and
// sparseflow_base_seq, but those classes live in separate
// files. Without packages, SystemVerilog classes in different
// files need explicit `include to see each other - just being
// compiled in the same simulation isn't enough.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "sparseflow_seq_item.sv"
`include "sparseflow_if.sv"
`include "sparseflow_driver.sv"
`include "sparseflow_monitor.sv"
`include "sparseflow_sequencer.sv"
`include "sparseflow_agent.sv"
`include "sparseflow_scoreboard.sv"
`include "sparseflow_env.sv"
`include "sparseflow_base_seq.sv"

class sparseflow_test extends uvm_test;

  `uvm_component_utils(sparseflow_test)

  sparseflow_env env;

  function new(string name = "sparseflow_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = sparseflow_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    sparseflow_base_seq seq;
    phase.raise_objection(this);

    seq = sparseflow_base_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    phase.drop_objection(this);
  endtask

endclass : sparseflow_test
