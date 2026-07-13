`ifndef SPARSEFLOW_BASE_SEQ_SV
`define SPARSEFLOW_BASE_SEQ_SV
// ============================================================
// sparseflow_base_seq.sv
// SparseFlow - basic directed sequence
//
// DEBUG: added $display statements at start/end of body() to
// confirm whether this sequence's body() ever actually runs,
// since the prior simulation showed zero scoreboard output
// despite extending runtime to 11us.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_base_seq extends uvm_sequence #(sparseflow_seq_item);

  `uvm_object_utils(sparseflow_base_seq)

  function new(string name = "sparseflow_base_seq");
    super.new(name);
  endfunction

  task do_write(bit [7:0] addr, bit [31:0] data);
    sparseflow_seq_item item;
    item = sparseflow_seq_item::type_id::create("item");
    start_item(item);
    item.is_write = 1'b1;
    item.addr     = addr;
    item.wdata    = data;
    finish_item(item);
  endtask

  task do_read(bit [7:0] addr);
    sparseflow_seq_item item;
    item = sparseflow_seq_item::type_id::create("item");
    start_item(item);
    item.is_write = 1'b0;
    item.addr     = addr;
    finish_item(item);
  endtask

  task body();
    $display("T=%0t : [SEQ] body() STARTED", $time);

    do_write(REG_BITMAP_LO, 32'hFFFFFFFF);
    $display("T=%0t : [SEQ] wrote BITMAP_LO", $time);
    do_write(REG_BITMAP_HI, 32'hFFFFFFFF);
    do_write(REG_MATRIX_ROWS, 32'd1);
    do_write(REG_MATRIX_COLS, 32'd64);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_PERF_SKIP);
    do_write(REG_CTRL, 32'h0);
    #100ns;

    do_write(REG_BITMAP_LO, 32'h0000000F);
    do_write(REG_BITMAP_HI, 32'h00000000);
    do_write(REG_MATRIX_ROWS, 32'd1);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_PERF_SKIP);
    do_write(REG_CTRL, 32'h0);
    #100ns;

    do_write(REG_BITMAP_LO, 32'h00000000);
    do_write(REG_BITMAP_HI, 32'h00000000);
    do_write(REG_MATRIX_ROWS, 32'd1);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_PERF_SKIP);
    do_write(REG_CTRL, 32'h0);
    #100ns;

    $display("T=%0t : [SEQ] body() FINISHED", $time);
  endtask

endclass : sparseflow_base_seq
`endif
