// ============================================================
// tb_uvm_top.sv
// SparseFlow - UVM testbench top
//
// Unlike tb_sparseflow_top.sv (Week 2 directed testbench,
// which drives signals directly), this top is intentionally
// minimal: instantiate DUT + interface, register the virtual
// interface with config_db, call run_test(). All actual
// stimulus logic lives in the UVM classes, not here.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

module tb_uvm_top;

  logic clk;
  logic rst_n;

  initial clk = 0;
  always #2.5 clk = ~clk;

  // ----------------------------------------------------------
  // The interface instance - this is the single physical
  // bundle of wires that both the DUT and every UVM component
  // (driver, monitor) connect to.
  // ----------------------------------------------------------
  sparseflow_if vif(.clk(clk), .rst_n(rst_n));

  // ----------------------------------------------------------
  // DUT instantiation - connect each port to the matching
  // signal inside the interface instance.
  // ----------------------------------------------------------
  sparseflow_top dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axi_awaddr  (vif.s_axi_awaddr),
    .s_axi_awvalid (vif.s_axi_awvalid),
    .s_axi_awready (vif.s_axi_awready),
    .s_axi_wdata   (vif.s_axi_wdata),
    .s_axi_wvalid  (vif.s_axi_wvalid),
    .s_axi_wready  (vif.s_axi_wready),
    .s_axi_bresp   (vif.s_axi_bresp),
    .s_axi_bvalid  (vif.s_axi_bvalid),
    .s_axi_bready  (vif.s_axi_bready),
    .s_axi_araddr  (vif.s_axi_araddr),
    .s_axi_arvalid (vif.s_axi_arvalid),
    .s_axi_arready (vif.s_axi_arready),
    .s_axi_rdata   (vif.s_axi_rdata),
    .s_axi_rvalid  (vif.s_axi_rvalid),
    .s_axi_rready  (vif.s_axi_rready),
    .done_irq      (vif.done_irq),
    .busy          (vif.busy)
  );

  // ----------------------------------------------------------
  // Reset generation
  // ----------------------------------------------------------
  initial begin
    rst_n = 0;
    repeat (5) @(posedge clk);
    rst_n = 1;
  end

  // ----------------------------------------------------------
  // Register the virtual interface with config_db BEFORE
  // run_test() starts. Any component anywhere in the UVM
  // hierarchy that does uvm_config_db#(virtual sparseflow_if)
  // ::get(...) with a matching field name ("vif") will receive
  // this same handle - this is how our driver and monitor get
  // their vif without us manually wiring it through every
  // constructor.
  // ----------------------------------------------------------
  initial begin
    uvm_config_db#(virtual sparseflow_if)::set(null, "*", "vif", vif);
    run_test("sparseflow_test");
  end

endmodule : tb_uvm_top
