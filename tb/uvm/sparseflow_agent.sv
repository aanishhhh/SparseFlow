`ifndef SPARSEFLOW_AGENT_SV
`define SPARSEFLOW_AGENT_SV
// ============================================================
// sparseflow_agent.sv
// SparseFlow - UVM agent
//
// Bundles one sequencer + one driver + one monitor together,
// since these three components form a complete set for
// interacting with one interface (our AXI4-Lite bus).
//
// The agent's job in build_phase is to CREATE all three.
// Its job in connect_phase is to WIRE the driver's
// seq_item_port to the sequencer's seq_item_export - this
// single connection is what lets get_next_item/item_done
// actually pull items through from sequence -> sequencer ->
// driver.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

class sparseflow_agent extends uvm_agent;

  `uvm_component_utils(sparseflow_agent)

  sparseflow_sequencer sequencer;
  sparseflow_driver     driver;
  sparseflow_monitor    monitor;

  function new(string name = "sparseflow_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ----------------------------------------------------------
  // build_phase: create all three sub-components. We use the
  // factory (::type_id::create) for each, consistent with the
  // pattern used in sparseflow_monitor.sv.
  // ----------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = sparseflow_sequencer::type_id::create("sequencer", this);
    driver    = sparseflow_driver::type_id::create("driver", this);
    monitor   = sparseflow_monitor::type_id::create("monitor", this);
  endfunction

  // ----------------------------------------------------------
  // connect_phase: wire the driver to the sequencer. This is
  // the one connection that makes the driver's
  // seq_item_port.get_next_item() calls actually able to pull
  // items that sequences pushed into the sequencer.
  // ----------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction

endclass : sparseflow_agent
`endif
