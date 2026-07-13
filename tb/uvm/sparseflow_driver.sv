 // =======================================================
// sparseflow_driver.sv
// SparseFlow - UVM driver
//
// Takes sparseflow_seq_item transactions one at a time from
// the sequencer and performs the actual AXI4-Lite handshake
// on the interface - the same logic as the axi_write/axi_read
// tasks from the Week 2 directed testbench, now reusable.
// =======================================================

`ifndef SPARSEFLOW_DRIVER_SV
`define SPARSEFLOW_DRIVER_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_driver extends uvm_driver #(sparseflow_seq_item);

  `uvm_component_utils(sparseflow_driver)
  virtual sparseflow_if vif;

  function new(string name = "sparseflow_driver",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual sparseflow_if)::get(
        this, "", "vif", vif))
      `uvm_fatal("NOVIF", "No virtual interface")
    $display("T=%0t [DRIVER] build_phase done", $time);
  endfunction

  task run_phase(uvm_phase phase);
    sparseflow_seq_item item;
    $display("T=%0t [DRIVER] run_phase started", $time);
    forever begin
      seq_item_port.get_next_item(item);
      $display("T=%0t [DRIVER] driving addr=%h write=%0d",
               $time, item.addr, item.is_write);
      drive_item(item);
      seq_item_port.item_done();
    end
  endtask

  task drive_item(sparseflow_seq_item item);
    if (item.is_write)
      do_axi_write(item.addr, item.wdata);
    else
      do_axi_read(item.addr, item.rdata);
  endtask

  task do_axi_write(bit [7:0] addr, bit [31:0] data);
    @(posedge vif.clk);
    // Using blocking assignments (=) not non-blocking (<=)
    // inside class-based tasks - NBA region updates from
    // virtual interface signals are unreliable in XSim
    vif.s_axi_awaddr  = addr;
    vif.s_axi_awvalid = 1'b1;
    vif.s_axi_wdata   = data;
    vif.s_axi_wvalid  = 1'b1;
    vif.s_axi_bready  = 1'b1;
    @(posedge vif.clk);
    vif.s_axi_awvalid = 1'b0;
    vif.s_axi_wvalid  = 1'b0;
    wait (vif.s_axi_bvalid === 1'b1);
    @(posedge vif.clk);
    vif.s_axi_bready  = 1'b0;
    $display("T=%0t [DRIVER] write done addr=%h", $time, addr);
  endtask

  task do_axi_read(bit [7:0] addr, ref bit [31:0] rdata);
    @(posedge vif.clk);
    vif.s_axi_araddr  = addr;
    vif.s_axi_arvalid = 1'b1;
    vif.s_axi_rready  = 1'b1;
    @(posedge vif.clk);
    vif.s_axi_arvalid = 1'b0;
    wait (vif.s_axi_rvalid === 1'b1);
    rdata = vif.s_axi_rdata;
    @(posedge vif.clk);
    vif.s_axi_rready  = 1'b0;
    $display("T=%0t [DRIVER] read done addr=%h data=%h",
             $time, addr, rdata);
  endtask

endclass : sparseflow_driver
`endif
