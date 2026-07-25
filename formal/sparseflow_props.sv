module sparseflow_props (
  input logic clk,
  input logic rst_n,
  input logic [63:0] bitmap,
  input logic row_valid
);

  logic [63:0] mac_en;
  logic [6:0]  skip_count;

  sparsity_ctrl dut (
    .clk        (clk),
    .rst_n      (rst_n),
    .bitmap     (bitmap),
    .row_valid  (row_valid),
    .mac_en     (mac_en),
    .skip_count (skip_count)
  );

  reg reset_seen = 0;
  always @(posedge clk)
    if (!rst_n) reset_seen <= 1;

  always @(posedge clk) begin
    if (reset_seen) begin
      if (row_valid)
        assert (mac_en == bitmap);
      if (!row_valid)
        assert (mac_en == 0);
      assert (skip_count <= 64);
    end
  end

endmodule
