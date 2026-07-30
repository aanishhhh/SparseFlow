 
// ============================================================
// sparseflow_pkg.sv
// SparseFlow - Global Parameter Package
// ============================================================

package sparseflow_pkg;

  parameter int DATA_WIDTH  = 16;
  parameter int ACCUM_WIDTH = 32;

  parameter int MAC_ROWS = 8;
  parameter int MAC_COLS = 8;
  parameter int NUM_MACS = MAC_ROWS * MAC_COLS;  // = 64

  parameter int BITMAP_WIDTH = NUM_MACS;  // = 64

  parameter int BUF_DEPTH  = 64;
  parameter int ADDR_WIDTH = 6;

  parameter int INPUT_ENTRY_WIDTH =
      BITMAP_WIDTH + (DATA_WIDTH * NUM_MACS);  // = 1088

  // AXI4-Lite register map (byte offsets)
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
  parameter logic [7:0] REG_RESULT      = 8'h28; // R: final computed result

  parameter int PERF_CNT_WIDTH = 32;
  parameter int SKIP_CNT_WIDTH = 7;

  // FSM state encoding - one-hot
  typedef enum logic [4:0] {
    ST_IDLE      = 5'b00001,
    ST_LOAD      = 5'b00010,
    ST_COMPUTE   = 5'b00100,
    ST_WRITEBACK = 5'b01000,
    ST_DONE      = 5'b10000
  } fsm_state_t;

endpackage : sparseflow_pkg
