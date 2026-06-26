 
 
// ============================================================
// tb_sparseflow_top.sv
// SparseFlow - Minimal directed testbench
//
// PURPOSE: Just prove the design elaborates and runs without
// crashing. This is NOT the UVM environment (that's Week 3).
// This sets clk/rst_n, fires a basic start pulse, and lets
// the FSM walk through states so we can see waveforms.
//
// UPDATE: Added CTRL=0 acknowledgment at the end so we can
// verify the FSM correctly returns from ST_DONE to ST_IDLE,
// instead of leaving it parked in DONE forever.
// ============================================================

import sparseflow_pkg::*;

module tb_sparseflow_top;

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

  logic done_irq;
  logic busy;

  // ----------------------------------------------------------
  // Device under test
  // ----------------------------------------------------------
  sparseflow_top dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),
    .done_irq      (done_irq),
    .busy          (busy)
  );

  // ----------------------------------------------------------
  // Clock generation: 200 MHz -> 5 ns period -> 2.5 ns half
  // ----------------------------------------------------------
  initial clk = 0;
  always #2.5 clk = ~clk;

  // ----------------------------------------------------------
  // Simple AXI write task - mimics a host writing one register
  // ----------------------------------------------------------
  task axi_write(input logic [7:0] addr, input logic [31:0] data);
    begin
      @(posedge clk);
      s_axi_awaddr  <= addr;
      s_axi_awvalid <= 1'b1;
      s_axi_wdata   <= data;
      s_axi_wvalid  <= 1'b1;
      s_axi_bready  <= 1'b1;
      @(posedge clk);
      s_axi_awvalid <= 1'b0;
      s_axi_wvalid  <= 1'b0;
      wait (s_axi_bvalid == 1'b1);
      @(posedge clk);
      s_axi_bready  <= 1'b0;
    end
  endtask

  // ----------------------------------------------------------
  // Main stimulus
  // ----------------------------------------------------------
  initial begin
    rst_n         = 0;
    s_axi_awaddr  = '0;
    s_axi_awvalid = 0;
    s_axi_wdata   = '0;
    s_axi_wvalid  = 0;
    s_axi_bready  = 0;
    s_axi_araddr  = '0;
    s_axi_arvalid = 0;
    s_axi_rready  = 0;

    // Hold reset for a few cycles
    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    $display("T=%0t : Reset released, FSM should be in IDLE", $time);

    // Set matrix size to 1 row (smallest possible test)
    axi_write(REG_MATRIX_ROWS, 32'd1);
    axi_write(REG_MATRIX_COLS, 32'd64);

    // Set sparsity bitmap: alternate ones and zeros (50% sparsity)
    axi_write(REG_BITMAP_LO, 32'hAAAAAAAA);
    axi_write(REG_BITMAP_HI, 32'hAAAAAAAA);

    // Write CTRL[0]=1 to start
    axi_write(REG_CTRL, 32'h1);

    $display("T=%0t : Start pulse sent", $time);

    // Let the FSM run for a while and watch it progress
    repeat (50) @(posedge clk);

    $display("T=%0t : busy=%0d done_irq=%0d", $time, busy, done_irq);

    // ------------------------------------------------------
    // ACK the done status: host writes CTRL=0 to clear start.
    // Without this, the FSM stays parked in ST_DONE forever,
    // since the FSM only leaves ST_DONE when reg_ctrl[0]==0.
    // ------------------------------------------------------
    axi_write(REG_CTRL, 32'h0);
    $display("T=%0t : Host acked done (wrote CTRL=0)", $time);

    repeat (10) @(posedge clk);
    $display("T=%0t : busy=%0d done_irq=%0d (should both be 0 now)",
              $time, busy, done_irq);

    repeat (10) @(posedge clk);

    $display("T=%0t : Simulation finished", $time);
    $finish;
  end

endmodule : tb_sparseflow_top
