`include "uvm_macros.svh"
import uvm_pkg::*;

class sparseflow_env extends uvm_env;

  `uvm_component_utils(sparseflow_env)

  sparseflow_agent      agent;
  sparseflow_scoreboard scoreboard;
  sparseflow_coverage   coverage;

  function new(string name = "sparseflow_env",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent      = sparseflow_agent::type_id::create("agent", this);
    scoreboard = sparseflow_scoreboard::type_id::create("scoreboard", this);
    coverage   = sparseflow_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.item_collected_port.connect(scoreboard.mon_imp);
    agent.monitor.item_collected_port.connect(coverage.analysis_export);
  endfunction

endclass : sparseflow_env
