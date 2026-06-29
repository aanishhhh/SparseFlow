
// ============================================================
// tb_sparseflow_top.sv
// SparseFlow - Minimal directed testbench
//
// FIX: module was incorrectly named "sparseflow_top" instead
// of "tb_sparseflow_top", causing a naming collision with the
// real DUT (rtl/sparseflow_top.sv). Vivado had two modules
// both called sparseflow_top in the simulation fileset, which
// broke elaboration and resulted in all signals showing Z/X
// with no actual stimulus ever applied.
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
  // Device under test - this instantiates the REAL DUT module
  // named sparseflow_top, defined in rtl/sparseflow_top.sv
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

  initial clk = 0;
  always #2.5 clk = ~clk;

  // ----------------------------------------------------------
  // DEBUG: continuously monitor the exact cycle ib_rd_en is
  // high, printing every relevant signal AT THAT MOMENT, not
  // after the fact. This catches the real values during the
  // one cycle that actually matters.
  // ----------------------------------------------------------
  always @(posedge clk) begin
    if (dut.ib_rd_en) begin
      $display("T=%0t [LIVE] ib_rd_en=1 | bitmap=%h | mac_en=%h | a0=%0d a1=%0d a2=%0d a3=%0d",
                $time, dut.current_bitmap, dut.mac_en,
                dut.mac_data[0], dut.mac_data[1],
                dut.mac_data[2], dut.mac_data[3]);
    end
    if (dut.ib_rd_en_d1) begin
      $display("T=%0t [LIVE] ib_rd_en_d1=1 | acc0=%0d acc1=%0d acc2=%0d acc3=%0d | row_result=%0d",
                $time, dut.mac_acc_out[0], dut.mac_acc_out[1],
                dut.mac_acc_out[2], dut.mac_acc_out[3], dut.row_result);
    end
  end


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

  task axi_read(input logic [7:0] addr, output logic [31:0] data);
    begin
      @(posedge clk);
      s_axi_araddr  <= addr;
      s_axi_arvalid <= 1'b1;
      s_axi_rready  <= 1'b1;
      @(posedge clk);
      s_axi_arvalid <= 1'b0;
      wait (s_axi_rvalid == 1'b1);
      data = s_axi_rdata;
      @(posedge clk);
      s_axi_rready  <= 1'b0;
    end
  endtask

  logic [31:0] read_val;
  logic [INPUT_ENTRY_WIDTH-1:0] forced_row;

  // ----------------------------------------------------------
  // Hand-calculated expected result:
  //   MAC 0: a=5,  clk_en=1 (bitmap bit0=1) -> contributes 5
  //   MAC 1: a=10, clk_en=1 (bitmap bit1=1) -> contributes 10
  //   MAC 2: a=8,  clk_en=1 (bitmap bit2=1) -> contributes 8
  //   MAC 3: a=12, clk_en=1 (bitmap bit3=1) -> contributes 12
  //   MACs 4-63: clk_en=0 (bitmap bits=0)   -> contribute 0
  //   TOTAL EXPECTED = 5+10+8+12 = 35
  // ----------------------------------------------------------
  localparam int EXPECTED_RESULT = 35;

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

    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    $display("T=%0t : Reset released, FSM should be in IDLE", $time);

    forced_row = '0;
    forced_row[15:0]   = 16'd5;
    forced_row[31:16]  = 16'd10;
    forced_row[47:32]  = 16'd8;
    forced_row[63:48]  = 16'd12;
    forced_row[INPUT_ENTRY_WIDTH-1 : DATA_WIDTH*NUM_MACS] = 64'h0000000F;

    force dut.u_input_buffer.rd_data = forced_row;
    $display("T=%0t : Forced row applied (held through LOAD/COMPUTE)", $time);

    axi_write(REG_MATRIX_ROWS, 32'd1);
    axi_write(REG_MATRIX_COLS, 32'd64);
    axi_write(REG_BITMAP_LO, 32'h0000000F);
    axi_write(REG_BITMAP_HI, 32'h00000000);

    axi_write(REG_CTRL, 32'h1);
    $display("T=%0t : Start pulse sent", $time);

    wait (busy == 1'b1 && done_irq == 1'b1);
    $display("T=%0t : busy=%0d done_irq=%0d (DONE reached)",
              $time, busy, done_irq);

    // ------------------------------------------------------
    // DEBUG: print internal signals directly via hierarchical
    // reference, bypassing all GUI/scope issues entirely.
    // ------------------------------------------------------
    $display("DEBUG current_bitmap = %h", dut.current_bitmap);
    $display("DEBUG mac_en         = %h", dut.mac_en);
    $display("DEBUG mac_data[0]    = %0d", dut.mac_data[0]);
    $display("DEBUG mac_data[1]    = %0d", dut.mac_data[1]);
    $display("DEBUG mac_data[2]    = %0d", dut.mac_data[2]);
    $display("DEBUG mac_data[3]    = %0d", dut.mac_data[3]);
    $display("DEBUG mac_acc_out[0] = %0d", dut.mac_acc_out[0]);
    $display("DEBUG mac_acc_out[1] = %0d", dut.mac_acc_out[1]);
    $display("DEBUG mac_acc_out[2] = %0d", dut.mac_acc_out[2]);
    $display("DEBUG mac_acc_out[3] = %0d", dut.mac_acc_out[3]);
    $display("DEBUG row_result     = %0d", dut.row_result);
    $display("DEBUG ib_rd_en       = %0d", dut.ib_rd_en);
    $display("DEBUG ib_rd_en_d1    = %0d", dut.ib_rd_en_d1);
    $display("DEBUG ob_wr_en       = %0d", dut.ob_wr_en);

    release dut.u_input_buffer.rd_data;

    axi_read(REG_RESULT, read_val);
    $display("T=%0t : reg_result = %0d  (expected = %0d)",
              $time, read_val, EXPECTED_RESULT);

    if (read_val == EXPECTED_RESULT) begin
      $display("PASS: Computed result matches hand-calculated expectation");
    end else begin
      $display("FAIL: Mismatch! Got %0d, expected %0d",
                read_val, EXPECTED_RESULT);
    end

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
