// ============================================================
// sparsity_ctrl.sv
// SparseFlow — Sparsity Control Unit
//
// THE NOVEL BLOCK. Takes the raw 64-bit sparsity bitmap and:
//   1. Registers it cleanly to drive mac_en[63:0]
//      (one clock-enable signal per MAC cell)
//   2. Counts how many MACs are being skipped this cycle
//      (feeds the PERF_SKIPPED performance counter)
//
// This is the hardware mechanism that turns "70% sparsity"
// into "70% fewer MACs switching" -> real power savings.
// ============================================================

import sparseflow_pkg::*;

module sparsity_ctrl (
  input  logic                        clk,
  input  logic                        rst_n,

  // Raw bitmap coming from the input buffer / host registers.
  // bit[i] = 1 -> MAC i has a non-zero operand, must compute
  // bit[i] = 0 -> MAC i operand is zero, skip it (gate clock)
  input  logic [BITMAP_WIDTH-1:0]     bitmap,

  // row_valid = 1 means "bitmap holds real data this cycle"
  // We only update mac_en when a new valid row is presented.
  input  logic                        row_valid,

  // Registered, glitch-free clock-enable for each of the
  // 64 MAC cells. This wire goes directly to each
  // sparse_mac instance's clk_en input.
  output logic [NUM_MACS-1:0]         mac_en,

  // How many MACs were skipped (zero bits) in the CURRENT
  // mac_en output. Range: 0 to 64, so needs 7 bits.
  output logic [SKIP_CNT_WIDTH-1:0]   skip_count
);

  // ----------------------------------------------------------
  // Registering the bitmap into mac_en
  // ----------------------------------------------------------
  // Why register instead of direct combinational wiring?
  //
  // If bitmap changed mid-cycle due to upstream timing skew,
  // a directly-wired clk_en could glitch — meaning a MAC cell
  // might see clk_en flicker high-low-high within one cycle.
  // Glitches on a clock-enable line are a classic source of
  // real silicon bugs (false triggering, metastability risk).
  //
  // By registering here, mac_en only ever changes cleanly on
  // the clock edge, synchronized with every other register in
  // the design. This is standard practice for any enable signal
  // that fans out to many destinations (here: 64 MAC cells).
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mac_en <= '0;   // reset: all MACs disabled, safe default
    end else if (row_valid) begin
      mac_en <= bitmap;  // new row arrived, update enables
    end
    // else: row_valid=0 -> mac_en holds previous value
    // (this matters during LOAD/WRITEBACK FSM states when
    //  no new row is being fed to the MAC array)
  end

  // ----------------------------------------------------------
  // Skip counter — population count of ZERO bits
  // ----------------------------------------------------------
  // We count how many bits in mac_en are 0 (skipped MACs).
  //
  // This is a "population count" (popcount) operation, just
  // counting zeros instead of ones. We write it as a simple
  // for-loop inside always_comb. This is NOT a literal 64-input
  // loop in hardware — the synthesis tool (Yosys, Week 6) will
  // automatically convert this into an efficient binary adder
  // tree (think: a tournament bracket of small adders).
  //
  // Why combinational (always_comb) instead of registered?
  // skip_count describes mac_en, which is already a registered
  // signal. Computing the count combinationally from the
  // already-stable mac_en avoids one extra cycle of latency —
  // the host can read PERF_SKIPPED in the same cycle mac_en
  // is valid.
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