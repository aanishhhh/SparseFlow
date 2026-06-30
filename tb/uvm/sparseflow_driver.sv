// =======================================================
// sparseflow_driver.sv
// SparseFlow - UVM driver
//
// Takes sparseflow_seq_item transactions one at a time from
// the sequencer and performs the actual AXI4-Lite handshake
// on the interface - the same logic as the axi_write/axi_read
// tasks from the Week 2 directed testbench, now reusable.
// =======================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_driver extends uvm_driver #(sparseflow_seq_item);

  `uvm_component_utils(sparseflow_driver)

  // ----------------------------------------------------------
  // Virtual interface handle
  // ----------------------------------------------------------
  // "virtual" here means a handle/reference to the interface,
  // not a literal copy of its signals. The driver doesn't own
  // the interface - it gets a reference to the same physical
  // interface instance the DUT is connected to, set during
  // the build_phase via the UVM config database.
  // ----------------------------------------------------------
  virtual sparseflow_if vif;

  function new(string name = "sparseflow_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ----------------------------------------------------------
  // build_phase: UVM calls this automatically before
  // simulation starts. We use it to fetch our virtual
  // interface handle from the config database - this is how
  // UVM components get access to the DUT without hardcoding
  // hierarchical paths.
  // ----------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sparseflow_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Virtual interface not set for driver - check config_db setup in test/env")
    end
  endfunction

  // ----------------------------------------------------------
  // run_phase: the main driver loop. Runs for the entire
  // simulation, continuously pulling items from the sequencer
  // and driving them onto the interface.
  // ----------------------------------------------------------
  task run_phase(uvm_phase phase);
    sparseflow_seq_item item;
    forever begin
      seq_item_port.get_next_item(item);
      drive_item(item);
      seq_item_port.item_done();
    end
  endtask

  // ----------------------------------------------------------
  // drive_item: the actual AXI4-Lite handshake logic.
  // Branches on is_write to perform either a write or a read.
  // ----------------------------------------------------------
  task drive_item(sparseflow_seq_item item);
    if (item.is_write) begin
      do_axi_write(item.addr, item.wdata);
    end else begin
      do_axi_read(item.addr, item.rdata);
    end
  endtask

  // ----------------------------------------------------------
  // do_axi_write: identical handshake to our Week 2 axi_write
  // task, now driving signals through vif. instead of bare
  // signal names.
  // ----------------------------------------------------------
  task do_axi_write(bit [7:0] addr, bit [31:0] data);
    @(posedge vif.clk);
    vif.s_axi_awaddr  <= addr;
    vif.s_axi_awvalid <= 1'b1;
    vif.s_axi_wdata   <= data;
    vif.s_axi_wvalid  <= 1'b1;
    vif.s_axi_bready  <= 1'b1;
    @(posedge vif.clk);
    vif.s_axi_awvalid <= 1'b0;
    vif.s_axi_wvalid  <= 1'b0;
    wait (vif.s_axi_bvalid == 1'b1);
    @(posedge vif.clk);
    vif.s_axi_bready  <= 1'b0;
  endtask

  // ----------------------------------------------------------
  // do_axi_read: identical handshake to our Week 2 axi_read
  // task. rdata is passed by reference (ref) so the caller's
  // item.rdata field gets updated directly.
  // ----------------------------------------------------------
  task do_axi_read(bit [7:0] addr, ref bit [31:0] rdata);
    @(posedge vif.clk);
    vif.s_axi_araddr  <= addr;
    vif.s_axi_arvalid <= 1'b1;
    vif.s_axi_rready  <= 1'b1;
    @(posedge vif.clk);
    vif.s_axi_arvalid <= 1'b0;
    wait (vif.s_axi_rvalid == 1'b1);
    rdata = vif.s_axi_rdata;
    @(posedge vif.clk);
    vif.s_axi_rready  <= 1'b0;
  endtask

endclass : sparseflow_driver
