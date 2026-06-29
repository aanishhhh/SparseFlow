// ============================================================
// sparseflow_if.sv
// SparseFlow - AXI4-Lite interface bundle for UVM
//
// PURPOSE: Bundles all 16 AXI4-Lite signals into one handle.
// Instead of the driver, monitor, and DUT each needing 16
// separate port connections, they all just connect to "the
// interface" and access signals as if.signal_name.
//
// This also lets us add clocking blocks later if we need
// precise timing control, without touching every module that
// uses the interface.
// ============================================================

import sparseflow_pkg::*;

interface sparseflow_if (input logic clk, input logic rst_n);

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
