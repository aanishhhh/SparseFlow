// ============================================================
// sparseflow_scoreboard.sv
// SparseFlow - UVM scoreboard
//
// Subscribes to the monitor's broadcast of every AXI
// transaction. Tracks register writes (bitmap, matrix size)
// to build up expected state, then checks reads against a
// reference model computation.
//
// SCOPE FOR WEEK 3: verifies PERF_SKIPPED correctly reflects
// the population count of zero-bits in whatever bitmap was
// written via AXI. This is fully observable through the real
// AXI interface (no force/release backdoor needed), and
// directly exercises the novel sparsity_ctrl popcount logic.
//
// Full result-value checking (the 5+10+8+12=35 style test)
// requires the dual-operand datapath extension noted as a
// known simplification in sparseflow_top.sv - tracked as
// future work, not blocking for this scoreboard's scope.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(sparseflow_scoreboard)

  // ----------------------------------------------------------
  // Analysis import - this macro generates a "write" method
  // that the monitor's analysis port calls automatically every
  // time it broadcasts an item. We implement that write()
  // method below to actually process each transaction.
  // ----------------------------------------------------------
  `uvm_analysis_imp_decl(_mon)
  uvm_analysis_imp_mon #(sparseflow_seq_item, sparseflow_scoreboard) mon_imp;

  // ----------------------------------------------------------
  // Shadow state - the scoreboard's own tracking of what's
  // been written to bitmap registers, since reading
  // PERF_SKIPPED only makes sense in context of what bitmap
  // was most recently written.
  // ----------------------------------------------------------
  bit [31:0] shadow_bitmap_lo;
  bit [31:0] shadow_bitmap_hi;

  int pass_count;
  int fail_count;

  function new(string name = "sparseflow_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    mon_imp = new("mon_imp", this);
    pass_count = 0;
    fail_count = 0;
  endfunction

  // ----------------------------------------------------------
  // write_mon: called automatically by the monitor's analysis
  // port for every transaction observed on the bus. This is
  // the actual scoreboard logic.
  // ----------------------------------------------------------
  function void write_mon(sparseflow_seq_item item);

    if (item.is_write) begin
      // Track bitmap writes in our shadow state
      case (item.addr)
        REG_BITMAP_LO: shadow_bitmap_lo = item.wdata;
        REG_BITMAP_HI: shadow_bitmap_hi = item.wdata;
        default: ; // other writes (CTRL, matrix size, etc.)
                    // don't need shadow tracking for this check
      endcase
    end else begin
      // Check reads of PERF_SKIPPED against our reference model
      if (item.addr == REG_PERF_SKIP) begin
        check_perf_skip(item.rdata);
      end
    end

  endfunction

  // ----------------------------------------------------------
  // Reference model: compute expected skip count from the
  // shadow bitmap state, then compare against the actual
  // PERF_SKIPPED value read back from the DUT.
  // ----------------------------------------------------------
  function void check_perf_skip(bit [31:0] actual_skip);
    bit [63:0] full_bitmap;
    int        expected_skip;

    full_bitmap   = {shadow_bitmap_hi, shadow_bitmap_lo};
    expected_skip = 0;

    for (int i = 0; i < NUM_MACS; i++) begin
      if (full_bitmap[i] == 1'b0) begin
        expected_skip++;
      end
    end

    if (actual_skip == expected_skip) begin
      pass_count++;
      `uvm_info("SCOREBOARD",
        $sformatf("PASS: PERF_SKIPPED=%0d matches expected=%0d (bitmap=%h)",
                   actual_skip, expected_skip, full_bitmap),
        UVM_MEDIUM)
    end else begin
      fail_count++;
      `uvm_error("SCOREBOARD",
        $sformatf("FAIL: PERF_SKIPPED=%0d but expected=%0d (bitmap=%h)",
                   actual_skip, expected_skip, full_bitmap))
    end
  endfunction

  // ----------------------------------------------------------
  // report_phase: UVM calls this automatically at the very
  // end of simulation. Good place to print a final summary.
  // ----------------------------------------------------------
  function void report_phase(uvm_phase phase);
    `uvm_info("SCOREBOARD",
      $sformatf("FINAL SCORE: %0d passed, %0d failed",
                 pass_count, fail_count),
      UVM_LOW)
  endfunction

endclass : sparseflow_scoreboard
