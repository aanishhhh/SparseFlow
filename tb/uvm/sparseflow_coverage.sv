// ============================================================
// sparseflow_coverage.sv
// SparseFlow - Functional coverage collector
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_coverage extends uvm_subscriber #(sparseflow_seq_item);

  `uvm_component_utils(sparseflow_coverage)

  sparseflow_seq_item item;

  covergroup sparsity_cg;
    cp_bitmap: coverpoint item.wdata {
      bins all_zeros  = {32'h00000000};
      bins all_ones   = {32'hFFFFFFFF};
      bins alternate  = {32'hAAAAAAAA};
      bins low_active = {[32'h00000001:32'h0000FFFF]};
      bins mid_active = {[32'h00010000:32'h7FFFFFFF]};
      bins single_mac = {32'h00000001,32'h00000002,
                         32'h00000004,32'h00000008};
    }
    cp_addr: coverpoint item.addr {
      bins bitmap_lo   = {REG_BITMAP_LO};
      bins bitmap_hi   = {REG_BITMAP_HI};
      bins ctrl        = {REG_CTRL};
      bins matrix_rows = {REG_MATRIX_ROWS};
      bins perf_skip   = {REG_PERF_SKIP};
      bins result      = {REG_RESULT};
    }
    cp_direction: coverpoint item.is_write {
      bins write_txn = {1'b1};
      bins read_txn  = {1'b0};
    }
    cx_addr_dir: cross cp_addr, cp_direction;
  endgroup : sparsity_cg

  covergroup perf_cg;
    cp_perf: coverpoint item.addr {
      bins perf_skip  = {REG_PERF_SKIP};
      bins perf_cycle = {REG_PERF_CYC};
      bins result     = {REG_RESULT};
    }
  endgroup : perf_cg

  function new(string name = "sparseflow_coverage",
               uvm_component parent = null);
    super.new(name, parent);
    sparsity_cg = new();
    perf_cg     = new();
  endfunction

  function void write(sparseflow_seq_item t);
    item = t;
    sparsity_cg.sample();
    perf_cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COVERAGE",
      $sformatf("sparsity_cg coverage: %.1f%%",
                 sparsity_cg.get_coverage()), UVM_LOW)
    `uvm_info("COVERAGE",
      $sformatf("perf_cg coverage: %.1f%%",
                 perf_cg.get_coverage()), UVM_LOW)
  endfunction

endclass : sparseflow_coverage
