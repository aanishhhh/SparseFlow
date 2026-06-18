 
// ============================================================
// input_buffer.sv
// SparseFlow — Input FIFO Buffer
//
// Holds rows of (bitmap + data) waiting to be consumed by the
// MAC array. Host/DMA writes rows in during LOAD state, the
// FSM reads them out one per cycle during COMPUTE state.
//
// Each entry = INPUT_ENTRY_WIDTH bits = 1088 bits:
//   bitmap[63:0]  + data[1023:0]  (64 MACs x 16-bit operands)
// ============================================================

import sparseflow_pkg::*;

module input_buffer (
  input  logic                          clk,
  input  logic                          rst_n,

  // Write side — host/DMA loads new rows here
  input  logic                          wr_en,
  input  logic [INPUT_ENTRY_WIDTH-1:0]  wr_data,

  // Read side — FSM/MAC array pulls rows out here
  input  logic                          rd_en,
  output logic [INPUT_ENTRY_WIDTH-1:0]  rd_data,

  // Status flags
  output logic                          full,
  output logic                          empty
);

  // ----------------------------------------------------------
  // The actual memory — an array of BUF_DEPTH entries, each
  // INPUT_ENTRY_WIDTH bits wide. This will synthesize to a
  // register file or block RAM depending on the tool's choice.
  // ----------------------------------------------------------
  logic [INPUT_ENTRY_WIDTH-1:0] mem [BUF_DEPTH];

  // ----------------------------------------------------------
  // Pointers — ADDR_WIDTH+1 bits wide (7 bits, not 6)
  // ----------------------------------------------------------
  // Why one extra bit?
  //   ADDR_WIDTH=6 only gives addresses 0-63 (64 positions).
  //   If we used only 6 bits for both pointers, "buffer full"
  //   and "buffer empty" would look IDENTICAL: both happen
  //   when wr_ptr == rd_ptr (same address).
  //
  //   By adding a 7th bit that keeps counting and wrapping
  //   independently, we get:
  //     EMPTY: wr_ptr == rd_ptr completely (all 7 bits match)
  //     FULL:  lower 6 bits match, but bit[6] differs
  //   This is the standard "one extra bit" FIFO trick.
  // ----------------------------------------------------------
  logic [ADDR_WIDTH:0] wr_ptr;  // 7 bits
  logic [ADDR_WIDTH:0] rd_ptr;  // 7 bits

  // ----------------------------------------------------------
  // Write logic
  // ----------------------------------------------------------
  // On every clock edge, if wr_en=1 AND we are not full,
  // write wr_data into the memory at the address given by
  // the lower ADDR_WIDTH bits of wr_ptr, then increment wr_ptr.
  //
  // We use wr_ptr[ADDR_WIDTH-1:0] as the actual memory index
  // (only 6 bits needed to address 64 slots) but wr_ptr itself
  // is 7 bits so it can keep counting past the wraparound point
  // for full/empty detection.
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
    end else if (wr_en && !full) begin
      mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
      wr_ptr <= wr_ptr + 1'b1;
    end
    // else: wr_en=0, or buffer is full -> ignore the write
    // (a real system would also assert an error/backpressure
    //  signal here; we keep it simple for this project)
  end

  // ----------------------------------------------------------
  // Read logic
  // ----------------------------------------------------------
  // rd_data is registered so it's stable for one full cycle
  // after rd_en is asserted. This matches standard "synchronous
  // read" FIFO behavior — the data appears the cycle AFTER
  // rd_en goes high, not combinationally in the same cycle.
  // ----------------------------------------------------------
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr  <= '0;
      rd_data <= '0;
    end else if (rd_en && !empty) begin
      rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
      rd_ptr  <= rd_ptr + 1'b1;
    end
    // else: rd_en=0, or buffer is empty -> rd_data holds
  end

  // ----------------------------------------------------------
  // Full / empty detection using the extra bit trick
  // ----------------------------------------------------------
  // EMPTY: wr_ptr and rd_ptr are exactly equal (all 7 bits)
  //   -> no entries have been written that haven't been read
  //
  // FULL: the lower ADDR_WIDTH bits are equal (same physical
  //       slot) BUT the top bit (bit[ADDR_WIDTH]) differs
  //   -> write pointer has wrapped exactly one full lap ahead
  //      of the read pointer, meaning all 64 slots are occupied
  // ----------------------------------------------------------
  assign empty = (wr_ptr == rd_ptr);

  assign full  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) &&
                 (wr_ptr[ADDR_WIDTH]     != rd_ptr[ADDR_WIDTH]);

endmodule : input_buffer
