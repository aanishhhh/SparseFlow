// ============================================================
// output_buffer.sv
// SparseFlow — Output FIFO Buffer
//
// Holds completed accumulator results (one 32-bit value per
// row) waiting to be written back to memory. The MAC array
// pushes results in during COMPUTE, the FSM drains them out
// during WRITEBACK.
//
// Structurally identical to input_buffer.sv but with a much
// narrower entry: just ACCUM_WIDTH (32 bits) instead of the
// full 1088-bit input row. Same pointer trick for full/empty.
// ============================================================

import sparseflow_pkg::*;

module output_buffer (
  input  logic                       clk,
  input  logic                       rst_n,

  // Write side — MAC array pushes finished results here
  input  logic                       wr_en,
  input  logic [ACCUM_WIDTH-1:0]     wr_data,

  // Read side — writeback logic pulls results out here
  input  logic                       rd_en,
  output logic [ACCUM_WIDTH-1:0]     rd_data,

  // Status flags
  output logic                       full,
  output logic                       empty
);

  // ----------------------------------------------------------
  // Memory array
  // ----------------------------------------------------------
  logic [ACCUM_WIDTH-1:0] mem [BUF_DEPTH];

  // ----------------------------------------------------------
  // FIFO pointers
  // ----------------------------------------------------------
  logic [ADDR_WIDTH:0] wr_ptr;
  logic [ADDR_WIDTH:0] rd_ptr;

  // ----------------------------------------------------------
  // Write logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
    end
    else if (wr_en && !full) begin
      mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
      wr_ptr <= wr_ptr + 1'b1;
    end
  end

  // ----------------------------------------------------------
  // Read logic
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr  <= '0;
      rd_data <= '0;
    end
    else if (rd_en && !empty) begin
      rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
      rd_ptr  <= rd_ptr + 1'b1;
    end
  end

  // ----------------------------------------------------------
  // Full / Empty detection
  // ----------------------------------------------------------
  assign empty = (wr_ptr == rd_ptr);

  assign full =
      (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
      (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);

endmodule : output_buffer