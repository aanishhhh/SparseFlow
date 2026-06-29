// ============================================================
// sparsity_ctrl.sv
// SparseFlow - Sparsity Control Unit
//
// FIX: mac_en was registered (1-cycle delayed from bitmap),
// but valid/data signals reach sparse_mac COMBINATIONALLY in
// the same cycle. This 1-cycle misalignment meant mac_en was
// always stale-zero on the one cycle valid=1, so every MAC
// was clock-gated off and results were always 0.
//
// Made mac_en combinational so it aligns with valid/data in
// the same cycle. bitmap itself comes from input_buffer's
// registered rd_data, so there is no glitch risk - bitmap
// only changes once per row, synchronized to the same clock
// edge as everything else upstream.
// ============================================================

import sparseflow_pkg::*;

module sparsity_ctrl (
  input  logic                        clk,
  input  logic                        rst_n,
  input  logic [BITMAP_WIDTH-1:0]     bitmap,
  input  logic                        row_valid,
  output logic [NUM_MACS-1:0]         mac_en,
  output logic [SKIP_CNT_WIDTH-1:0]   skip_count
);

  // ----------------------------------------------------------
  // mac_en is now COMBINATIONAL, directly following bitmap
  // whenever row_valid is high. This aligns with how `valid`
  // (ib_rd_en) reaches sparse_mac in the same cycle - both
  // see the same row's data and bitmap together, same cycle.
  //
  // When row_valid=0, mac_en holds at all-zero (safe default,
  // no MAC accidentally enabled when there's no real row).
  // ----------------------------------------------------------
  always_comb begin
    if (row_valid) begin
      mac_en = bitmap;
    end else begin
      mac_en = '0;
    end
  end

  // ----------------------------------------------------------
  // Skip counter - population count of ZERO bits in mac_en.
  // Still combinational, now correctly reflects the SAME
  // cycle's mac_en rather than a stale previous value.
  // ----------------------------------------------------------
  always_comb begin
    automatic int zero_count;
    zero_count = 0;
    for (int i = 0; i < NUM_MACS; i++) begin
      if (mac_en[i] == 1'b0) begin
        zero_count++;
      end
    end
    skip_count = zero_count[SKIP_CNT_WIDTH-1:0];
  end

endmodule : sparsity_ctrl
