// ============================================================
// sparseflow_base_seq.sv
// SparseFlow - basic directed sequence
//
// Generates a stream of seq_items that: write a known bitmap,
// trigger a run via CTRL, then read back PERF_SKIPPED. This
// directly exercises the scoreboard's reference model check.
//
// uvm_sequence#(sparseflow_seq_item) is UVM's base sequence
// class, parameterized with our transaction type.
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import sparseflow_pkg::*;

class sparseflow_base_seq extends uvm_sequence #(sparseflow_seq_item);

  `uvm_object_utils(sparseflow_base_seq)

  function new(string name = "sparseflow_base_seq");
    super.new(name);
  endfunction

  // ----------------------------------------------------------
  // do_write: helper task to create, randomize-then-override,
  // and send one write transaction through the sequencer.
  //
  // start_item/finish_item is the standard UVM pattern for
  // sending a single item: start_item blocks until the
  // sequencer is ready to accept it, finish_item blocks until
  // the driver has fully completed driving it.
  // ----------------------------------------------------------
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

  // ----------------------------------------------------------
  // body: the main sequence logic, called automatically when
  // this sequence is started on a sequencer.
  // ----------------------------------------------------------
  task body();
    // Test case 1: bitmap = all 64 bits set (0% sparsity,
    // 0 MACs should be skipped)
    do_write(REG_BITMAP_LO, 32'hFFFFFFFF);
    do_write(REG_BITMAP_HI, 32'hFFFFFFFF);
    do_write(REG_MATRIX_ROWS, 32'd1);
    do_write(REG_MATRIX_COLS, 32'd64);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_PERF_SKIP);
    do_write(REG_CTRL, 32'h0);
    #100ns;

    // Test case 2: bitmap = 0x0F (4 active, 60 skipped -
    // same pattern we hand-verified in Week 2)
    do_write(REG_BITMAP_LO, 32'h0000000F);
    do_write(REG_BITMAP_HI, 32'h00000000);
    do_write(REG_MATRIX_ROWS, 32'd1);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_PERF_SKIP);
    do_write(REG_CTRL, 32'h0);
    #100ns;

    // Test case 3: bitmap = all zeros (100% sparsity,
    // all 64 MACs should be skipped)
    do_write(REG_BITMAP_LO, 32'h00000000);
    do_write(REG_BITMAP_HI, 32'h00000000);
    do_write(REG_MATRIX_ROWS, 32'd1);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_PERF_SKIP);
    do_write(REG_CTRL, 32'h0);
    #100ns;
  endtask

endclass : sparseflow_base_seq
