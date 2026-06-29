// ============================================================
// sparseflow_seq_item.sv
// SparseFlow - UVM sequence item (transaction)
//
// FIX: missing UVM library import and macro include. Without
// these two lines, uvm_sequence_item and all `uvm_* macros are
// undefined as far as the compiler is concerned, causing
// syntax errors and "non-module file" classification.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_seq_item extends uvm_sequence_item;

  rand bit         is_write;
  rand bit [7:0]   addr;
  rand bit [31:0]  wdata;
       bit [31:0]  rdata;

  `uvm_object_utils_begin(sparseflow_seq_item)
    `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_field_int(addr,     UVM_ALL_ON)
    `uvm_field_int(wdata,    UVM_ALL_ON)
    `uvm_field_int(rdata,    UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "sparseflow_seq_item");
    super.new(name);
  endfunction

  constraint valid_addr_c {
    addr inside {
      REG_CTRL, REG_STATUS, REG_BITMAP_LO, REG_BITMAP_HI,
      REG_MATRIX_ROWS, REG_MATRIX_COLS, REG_IN_ADDR,
      REG_OUT_ADDR, REG_PERF_CYC, REG_PERF_SKIP, REG_RESULT
    };
  }

endclass : sparseflow_seq_item
