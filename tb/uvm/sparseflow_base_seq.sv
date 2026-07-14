`ifndef SPARSEFLOW_BASE_SEQ_SV
`define SPARSEFLOW_BASE_SEQ_SV

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

  task run_one_test(bit [31:0] bmap_lo, bit [31:0] bmap_hi,
                    bit [31:0] rows);
    do_write(REG_BITMAP_LO,   bmap_lo);
    do_write(REG_BITMAP_HI,   bmap_hi);
    do_write(REG_MATRIX_ROWS, rows);
    do_write(REG_MATRIX_COLS, 32'd64);
    do_write(REG_CTRL, 32'h1);
    #500ns;
    do_read(REG_STATUS);
    do_read(REG_PERF_SKIP);
    do_read(REG_PERF_CYC);
    do_read(REG_RESULT);
    do_write(REG_CTRL, 32'h0);
    #100ns;
  endtask

  task body();
    $display("T=%0t [SEQ] body() STARTED", $time);

    // Test 1: 0% sparsity - all 64 MACs active
    // Expected skip = 0
    run_one_test(32'hFFFFFFFF, 32'hFFFFFFFF, 32'd1);

    // Test 2: 50% sparsity - alternating bits
    // Expected skip = 32
    run_one_test(32'hAAAAAAAA, 32'hAAAAAAAA, 32'd1);

    // Test 3: ~94% sparsity - only 4 MACs active
    // Expected skip = 60
    run_one_test(32'h0000000F, 32'h00000000, 32'd1);

    // Test 4: 100% sparsity - all zeros
    // Expected skip = 64
    run_one_test(32'h00000000, 32'h00000000, 32'd1);

    // Test 5: single MAC active (bit 0 only)
    // Expected skip = 63
    run_one_test(32'h00000001, 32'h00000000, 32'd1);

    // Test 6: single MAC active (bit 1 only)
    // Expected skip = 63
    run_one_test(32'h00000002, 32'h00000000, 32'd1);

    $display("T=%0t [SEQ] body() FINISHED", $time);
  endtask

endclass : sparseflow_base_seq
`endif
