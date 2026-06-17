// ============================================================
// sparse_mac.sv
// SparseFlow — Single MAC cell with sparsity-aware clock gating
//
// This is the fundamental compute unit. 64 instances of this
// module form the 8x8 MAC array. Each one independently
// decides whether to compute or stay idle based on clk_en,
// which comes from the sparsity control unit.
// ============================================================

import sparseflow_pkg::*;

module sparse_mac (
  input  logic                      clk,
  input  logic                      rst_n,

  // clk_en = 1 means "this operand is non-zero, do the work"
  // clk_en = 0 means "this operand is zero, skip everything"
  // This is driven by sparsity_ctrl.sv based on the bitmap
  input  logic                      clk_en,

  // valid = 1 means a and b actually contain real data this
  // cycle. We separate this from clk_en because clk_en is
  // about sparsity (zero-skip), while valid is about whether
  // the upstream pipeline has real data flowing at all.
  input  logic                      valid,

  input  logic [DATA_WIDTH-1:0]     a,
  input  logic [DATA_WIDTH-1:0]     b,
  input  logic [ACCUM_WIDTH-1:0]    acc_in,

  output logic [ACCUM_WIDTH-1:0]    acc_out
);

  // ----------------------------------------------------------
  // Internal wire for the raw multiply result
  // ----------------------------------------------------------
  // a and b are each 16 bits. Multiplying two 16-bit numbers
  // can produce up to a 32-bit result (16+16=32 bits needed
  // in the worst case). We declare this as signed because
  // weights and activations in DNNs can be negative.
  // ----------------------------------------------------------
  logic signed [DATA_WIDTH-1:0]        a_signed;
  logic signed [DATA_WIDTH-1:0]        b_signed;
  logic signed [(2*DATA_WIDTH)-1:0]    mult_result;
  logic signed [ACCUM_WIDTH-1:0]       sum_result;
  logic signed [ACCUM_WIDTH-1:0]       acc_in_signed;

  assign a_signed      = a;
  assign b_signed       = b;
  assign acc_in_signed  = acc_in;

  // mult_result is 32 bits wide (16+16), exactly fits 2*DATA_WIDTH
  assign mult_result = a_signed * b_signed;

  // ----------------------------------------------------------
  // Sum before saturation check
  // ----------------------------------------------------------
  // We extend mult_result and acc_in to a wider internal sum
  // so we can DETECT overflow before clamping. If we just did
  // a 32-bit + 32-bit add directly into a 32-bit register, an
  // overflow would silently wrap around with no way to catch it.
  // ----------------------------------------------------------
  logic signed [ACCUM_WIDTH:0] wide_sum;  // 33 bits, one extra
  assign wide_sum = {acc_in_signed[ACCUM_WIDTH-1], acc_in_signed} +
                     {mult_result[(2*DATA_WIDTH)-1], mult_result};

  // ----------------------------------------------------------
  // Saturation logic
  // ----------------------------------------------------------
  // Max positive value a signed 32-bit number can hold:
  //   32'h7FFFFFFF  (2,147,483,647)
  // Max negative value:
  //   32'h80000000  (-2,147,483,648)
  //
  // If wide_sum exceeds these bounds, we clamp instead of
  // wrapping. This is what makes our accumulator provably
  // safe — we will prove "never overflows silently" in Week 5
  // formal verification.
  // ----------------------------------------------------------
  localparam logic signed [ACCUM_WIDTH-1:0] MAX_POS = 32'h7FFFFFFF;
  localparam logic signed [ACCUM_WIDTH-1:0] MAX_NEG = 32'h80000000;

  always_comb begin
    if (wide_sum > {1'b0, MAX_POS}) begin
      sum_result = MAX_POS;          // clamp to max positive
    end else if (wide_sum < {1'b1, MAX_NEG}) begin
      sum_result = MAX_NEG;          // clamp to max negative
    end else begin
      sum_result = wide_sum[ACCUM_WIDTH-1:0];  // no overflow, pass through
    end
  end

  // ----------------------------------------------------------
  // The actual register — this is where clock gating happens
  // ----------------------------------------------------------
  // This is the most important block in the whole module.
  //
  // Notice the condition: if (clk_en && valid)
  //   Only when BOTH are true does the accumulator update.
  //   If clk_en=0 (sparsity says skip), acc_out just HOLDS
  //   its previous value. No new computation happens.
  //   The multiplier logic above still technically computes
  //   mult_result combinationally, but since we never load it
  //   into the register, downstream switching stops here.
  //
  // In real silicon, clock gating is even more aggressive —
  // synthesis tools insert actual clock gates on the register
  // bank so the clock signal itself doesn't toggle the cell.
  // That happens automatically in Week 6 synthesis once we
  // hand this RTL to Yosys. Right now we are describing the
  // BEHAVIOR; the tool inserts the actual gate later.
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_out <= '0;
    end else if (clk_en && valid) begin
      acc_out <= sum_result;
    end
    // else: clk_en=0 or valid=0 -> acc_out holds, no change
  end

endmodule : sparse_mac