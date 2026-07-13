`ifndef SPARSEFLOW_IF_SV
`define SPARSEFLOW_IF_SV
// ============================================================
// sparseflow_if.sv
// SparseFlow - AXI4-Lite interface bundle for UVM
//
// FIX: clk/rst_n were declared as interface PORTS, which on
// some simulators (including Vivado XSim in this case) don't
// reliably trigger @(posedge vif.clk) from inside class-based
// code (driver/monitor). Changed to plain internal logic
// signals instead - the testbench top now drives vif.clk and
// vif.rst_n directly, same simple pattern as our Week 2
// directed testbench used successfully.
// ============================================================

import sparseflow_pkg::*;

interface sparseflow_if;

  logic clk;
  logic rst_n;

  logic [7:0]   s_axi_awaddr;
  logic         s_axi_awvalid;
  logic         s_axi_awready;
  logic [31:0]  s_axi_wdata;
  logic         s_axi_wvalid;
  logic         s_axi_wready;
  logic [1:0]   s_axi_bresp;
  logic         s_axi_bvalid;
  logic         s_axi_bready;
  logic [7:0]   s_axi_araddr;
  logic         s_axi_arvalid;
  logic         s_axi_arready;
  logic [31:0]  s_axi_rdata;
  logic         s_axi_rvalid;
  logic         s_axi_rready;

  logic         done_irq;
  logic         busy;

endinterface : sparseflow_if
`endif
