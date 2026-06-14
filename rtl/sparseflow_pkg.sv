// ============================================================
// sparseflow_pkg.sv
// SparseFlow — Global Parameter Package
//
// PURPOSE:
//   Single source of truth for every number in the design.
//   Every other .sv file imports this package with:
//     import sparseflow_pkg::*;
//
//   Rule: never hardcode 64, 16, 32 anywhere else in RTL.
//   Always use parameter names from this file.
//
// AUTHOR: Aanish
// PROJECT: SparseFlow — RTL to GDS2
// ============================================================

package sparseflow_pkg;

  // ----------------------------------------------------------
  // DATA WIDTHS
  // ----------------------------------------------------------
  // DATA_WIDTH = 16 (INT16 operands)
  //   Each MAC input A and input B is 16 bits wide.
  //   Matches INT16 precision used in pruned DNN inference.
  //
  // ACCUM_WIDTH = 32 (32-bit accumulator, saturating)
  //   Worst case per MAC: 32767 x 32767 = 1,073,676,289
  //   With 64 MACs accumulating: ~68 billion total
  //   That needs 37 bits exactly. We use 32 bits + saturation:
  //   if result exceeds 2^31-1, we clamp to max instead of
  //   wrapping around. Wrapping = silent wrong answer = bad.
  // ----------------------------------------------------------
  parameter int DATA_WIDTH  = 16;
  parameter int ACCUM_WIDTH = 32;

  // ----------------------------------------------------------
  // MAC ARRAY SIZE
  // ----------------------------------------------------------
  // 8 rows x 8 columns = 64 MACs running every clock cycle.
  //
  // NUM_MACS is always derived from rows x cols.
  // Never write the number 64 directly anywhere else in RTL.
  // Use NUM_MACS so if we ever resize, one change updates all.
  // ----------------------------------------------------------
  parameter int MAC_ROWS = 8;
  parameter int MAC_COLS = 8;
  parameter int NUM_MACS = MAC_ROWS * MAC_COLS;

  // ----------------------------------------------------------
  // SPARSITY BITMAP
  // ----------------------------------------------------------
  parameter int BITMAP_WIDTH = NUM_MACS;

  // ----------------------------------------------------------
  // BUFFER DEPTH AND ADDRESS WIDTH
  // ----------------------------------------------------------
  parameter int BUF_DEPTH  = 64;
  parameter int ADDR_WIDTH = 6;

  // ----------------------------------------------------------
  // INPUT BUFFER ENTRY WIDTH
  // ----------------------------------------------------------
  parameter int INPUT_ENTRY_WIDTH =
      BITMAP_WIDTH + (DATA_WIDTH * NUM_MACS);

  // ----------------------------------------------------------
  // AXI4-LITE REGISTER MAP
  // ----------------------------------------------------------
  parameter logic [7:0] REG_CTRL        = 8'h00;
  parameter logic [7:0] REG_STATUS      = 8'h04;
  parameter logic [7:0] REG_BITMAP_LO   = 8'h08;
  parameter logic [7:0] REG_BITMAP_HI   = 8'h0C;
  parameter logic [7:0] REG_MATRIX_ROWS = 8'h10;
  parameter logic [7:0] REG_MATRIX_COLS = 8'h14;
  parameter logic [7:0] REG_IN_ADDR     = 8'h18;
  parameter logic [7:0] REG_OUT_ADDR    = 8'h1C;
  parameter logic [7:0] REG_PERF_CYC    = 8'h20;
  parameter logic [7:0] REG_PERF_SKIP   = 8'h24;

  // ----------------------------------------------------------
  // PERFORMANCE COUNTER WIDTHS
  // ----------------------------------------------------------
  parameter int PERF_CNT_WIDTH = 32;
  parameter int SKIP_CNT_WIDTH = 7;

  // ----------------------------------------------------------
  // FSM STATE ENCODING — ONE-HOT
  // ----------------------------------------------------------
  typedef enum logic [4:0] {
    ST_IDLE      = 5'b00001,
    ST_LOAD      = 5'b00010,
    ST_COMPUTE   = 5'b00100,
    ST_WRITEBACK = 5'b01000,
    ST_DONE      = 5'b10000
  } fsm_state_t;

endpackage : sparseflow_pkg