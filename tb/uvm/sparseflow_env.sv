`ifndef SPARSEFLOW_ENV_SV
`define SPARSEFLOW_ENV_SV
// ============================================================
// sparseflow_env.sv
// SparseFlow - UVM environment
//
// Top-level container: creates the agent and scoreboard, and
// wires the monitor's analysis port to the scoreboard's
// analysis import. This connection is what makes every
// transaction the monitor observes actually reach the
// scoreboard's write_mon() callback.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

class sparseflow_env extends uvm_env;

  `uvm_component_utils(sparseflow_env)

  sparseflow_agent      agent;
  sparseflow_scoreboard  scoreboard;

  function new(string name = "sparseflow_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = sparseflow_agent::type_id::create("agent", this);
    scoreboard = sparseflow_scoreboard::type_id::create("scoreboard", this);
  endfunction

  // ----------------------------------------------------------
  // connect_phase: wire monitor -> scoreboard. The monitor's
  // item_collected_port.connect(scoreboard.mon_imp) line is
  // what makes every monitor.write() call automatically
  // trigger scoreboard.write_mon() with the same item.
  // ----------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.item_collected_port.connect(scoreboard.mon_imp);
  endfunction

endclass : sparseflow_env
`endif
