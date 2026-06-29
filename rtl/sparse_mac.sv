// ============================================================
// sparse_mac.sv
// SparseFlow - Single MAC cell with sparsity-aware clock gating
//
// FIX: saturation comparisons were broken due to a classic
// SystemVerilog gotcha - concatenation results are ALWAYS
// unsigned, even if the original signals were declared signed.
// {1'b1, MAX_NEG} produced a huge UNSIGNED value, so even a
// small correct result like 5 was being compared as unsigned
// against it and incorrectly triggering the negative-clamp
// branch, corrupting every result to 0x80000000.
//
// Fix: use $signed() to explicitly force both sides of each
// comparison to be interpreted as signed, matching wide_sum's
// actual signed declaration.
// ============================================================

import sparseflow_pkg::*;

module sparse_mac (
  input  logic                      clk,
  input  logic                      rst_n,
  input  logic                      clk_en,
  input  logic                      valid,
  input  logic [DATA_WIDTH-1:0]     a,
  input  logic [DATA_WIDTH-1:0]     b,
  input  logic [ACCUM_WIDTH-1:0]    acc_in,
  output logic [ACCUM_WIDTH-1:0]    acc_out
);

  logic signed [DATA_WIDTH-1:0]        a_signed;
  logic signed [DATA_WIDTH-1:0]        b_signed;
  logic signed [(2*DATA_WIDTH)-1:0]    mult_result;
  logic signed [ACCUM_WIDTH-1:0]       sum_result;
  logic signed [ACCUM_WIDTH-1:0]       acc_in_signed;

  assign a_signed      = a;
  assign b_signed       = b;
  assign acc_in_signed  = acc_in;

  assign mult_result = a_signed * b_signed;

  logic signed [ACCUM_WIDTH:0] wide_sum;  // 33 bits, one extra
  assign wide_sum = {acc_in_signed[ACCUM_WIDTH-1], acc_in_signed} +
                     {mult_result[(2*DATA_WIDTH)-1], mult_result};

  localparam logic signed [ACCUM_WIDTH-1:0] MAX_POS = 32'h7FFFFFFF;
  localparam logic signed [ACCUM_WIDTH-1:0] MAX_NEG = 32'h80000000;

  // ----------------------------------------------------------
  // FIX: wrap each comparison operand in $signed() explicitly.
  // This forces SystemVerilog to do a true signed comparison
  // instead of silently reinterpreting everything as unsigned
  // because concatenation results default to unsigned.
  // ----------------------------------------------------------
  always_comb begin
    if (wide_sum > $signed({1'b0, MAX_POS})) begin
      sum_result = MAX_POS;
    end else if (wide_sum < $signed({1'b1, MAX_NEG})) begin
      sum_result = MAX_NEG;
    end else begin
      sum_result = wide_sum[ACCUM_WIDTH-1:0];
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_out <= '0;
    end else if (clk_en && valid) begin
      acc_out <= sum_result;
    end
  end

endmodule : sparse_mac
