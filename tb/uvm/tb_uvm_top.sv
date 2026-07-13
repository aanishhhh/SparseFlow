`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

module tb_uvm_top;

  logic clk;
  logic rst_n;
  logic [7:0]  s_axi_awaddr;
  logic        s_axi_awvalid;
  logic        s_axi_awready;
  logic [31:0] s_axi_wdata;
  logic        s_axi_wvalid;
  logic        s_axi_wready;
  logic [1:0]  s_axi_bresp;
  logic        s_axi_bvalid;
  logic        s_axi_bready;
  logic [7:0]  s_axi_araddr;
  logic        s_axi_arvalid;
  logic        s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic        s_axi_rvalid;
  logic        s_axi_rready;
  logic        done_irq;
  logic        busy;

  sparseflow_top dut (
    .clk(clk), .rst_n(rst_n),
    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),
    .done_irq(done_irq),
    .busy(busy)
  );

  initial clk = 0;
  always #2.5 clk = ~clk;

  initial begin
    rst_n         = 0;
    s_axi_awaddr  = 0;
    s_axi_awvalid = 0;
    s_axi_wdata   = 0;
    s_axi_wvalid  = 0;
    s_axi_bready  = 0;
    s_axi_araddr  = 0;
    s_axi_arvalid = 0;
    s_axi_rready  = 0;
    repeat(5) @(posedge clk);
    rst_n = 1;
  end

  sparseflow_if vif();
  assign vif.clk          = clk;
  assign vif.rst_n        = rst_n;
  assign vif.s_axi_awready = s_axi_awready;
  assign vif.s_axi_wready  = s_axi_wready;
  assign vif.s_axi_bresp   = s_axi_bresp;
  assign vif.s_axi_bvalid  = s_axi_bvalid;
  assign vif.s_axi_arready = s_axi_arready;
  assign vif.s_axi_rdata   = s_axi_rdata;
  assign vif.s_axi_rvalid  = s_axi_rvalid;
  assign vif.done_irq      = done_irq;
  assign vif.busy          = busy;

  assign s_axi_awaddr  = vif.s_axi_awaddr;
  assign s_axi_awvalid = vif.s_axi_awvalid;
  assign s_axi_wdata   = vif.s_axi_wdata;
  assign s_axi_wvalid  = vif.s_axi_wvalid;
  assign s_axi_bready  = vif.s_axi_bready;
  assign s_axi_araddr  = vif.s_axi_araddr;
  assign s_axi_arvalid = vif.s_axi_arvalid;
  assign s_axi_rready  = vif.s_axi_rready;

  initial begin
    uvm_config_db#(virtual sparseflow_if)::set(
      null, "*", "vif", vif);
    run_test("sparseflow_test");
  end

endmodule
