// ============================================================
// sparseflow_monitor.sv
// SparseFlow - UVM monitor
//
// Passively watches the AXI4-Lite interface and reconstructs
// completed transactions, broadcasting each one via an
// analysis port. Never drives any signal - pure observation.
//
// The scoreboard subscribes to this port to get an independent
// record of what actually happened on the bus, which it then
// compares against expected behavior from a reference model.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_monitor extends uvm_monitor;

  `uvm_component_utils(sparseflow_monitor)

  virtual sparseflow_if vif;

  // ----------------------------------------------------------
  // Analysis port - broadcasts every observed transaction to
  // any subscribers (scoreboard, coverage collector, etc.)
  // The #(sparseflow_seq_item) parameterizes WHAT type of
  // object gets broadcast through this port.
  // ----------------------------------------------------------
  uvm_analysis_port #(sparseflow_seq_item) item_collected_port;

  function new(string name = "sparseflow_monitor", uvm_component parent = null);
    super.new(name, parent);
    item_collected_port = new("item_collected_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sparseflow_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not set for monitor - check config_db setup in test/env")
    end
  endfunction

  // ----------------------------------------------------------
  // run_phase: continuously watch the bus. We detect a
  // completed WRITE transaction when bvalid&bready handshake
  // completes, and a completed READ when rvalid&rready
  // handshake completes. Each detected transaction gets
  // packaged into a seq_item and broadcast.
  // ----------------------------------------------------------
  task run_phase(uvm_phase phase);
    sparseflow_seq_item item;

    forever begin
      @(posedge vif.clk);

      // Detect completed write: bvalid & bready high together
      // means the write response handshake just finished,
      // meaning the earlier awvalid/wvalid write actually
      // completed successfully.
      if (vif.s_axi_bvalid && vif.s_axi_bready) begin
        item = sparseflow_seq_item::type_id::create("mon_item");
        item.is_write = 1'b1;
        item.addr     = vif.s_axi_awaddr;
        item.wdata    = vif.s_axi_wdata;
        item_collected_port.write(item);
      end

      // Detect completed read: rvalid & rready high together
      // means the read data handshake just finished.
      if (vif.s_axi_rvalid && vif.s_axi_rready) begin
        item = sparseflow_seq_item::type_id::create("mon_item");
        item.is_write = 1'b0;
        item.addr     = vif.s_axi_araddr;
        item.rdata    = vif.s_axi_rdata;
        item_collected_port.write(item);
      end
    end
  endtask

endclass : sparseflow_monitor
