// ============================================================
// sparseflow_test.sv
// SparseFlow - top-level UVM test
//
// Creates the environment, then in run_phase builds and runs
// our base sequence on the agent's sequencer. This is the
// entry point UVM actually invokes when simulation starts.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

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

  // ----------------------------------------------------------
  // run_phase: raise an objection (tells UVM "don't end the
  // simulation yet, I'm still doing something important"),
  // run our sequence on the sequencer, then drop the
  // objection (tells UVM "I'm done, safe to finish now").
  //
  // Without raise/drop_objection, UVM's run_phase would
  // complete instantly since nothing else blocks it, and our
  // sequence would never actually get a chance to run.
  // ----------------------------------------------------------
  task run_phase(uvm_phase phase);
    sparseflow_base_seq seq;
    phase.raise_objection(this);

    seq = sparseflow_base_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);

    phase.drop_objection(this);
  endtask

endclass : sparseflow_test
