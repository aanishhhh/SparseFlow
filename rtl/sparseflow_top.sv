 
import sparseflow_pkg::*;

module sparseflow_top (
  input  logic        clk,
  input  logic         rst_n,

  input  logic [7:0]   s_axi_awaddr,
  input  logic         s_axi_awvalid,
  output logic         s_axi_awready,
  input  logic [31:0]  s_axi_wdata,
  input  logic         s_axi_wvalid,
  output logic         s_axi_wready,
  output logic [1:0]   s_axi_bresp,
  output logic         s_axi_bvalid,
  input  logic         s_axi_bready,
  input  logic [7:0]   s_axi_araddr,
  input  logic         s_axi_arvalid,
  output logic         s_axi_arready,
  output logic [31:0]  s_axi_rdata,
  output logic         s_axi_rvalid,
  input  logic         s_axi_rready,

  output logic         done_irq,
  output logic         busy
);

  logic [31:0] reg_ctrl;
  logic [31:0] reg_status;
  logic [31:0] reg_bitmap_lo;
  logic [31:0] reg_bitmap_hi;
  logic [31:0] reg_matrix_rows;
  logic [31:0] reg_matrix_cols;
  logic [31:0] reg_in_addr;
  logic [31:0] reg_out_addr;
  logic [31:0] reg_perf_cyc;
  logic [31:0] reg_perf_skip;
  logic [31:0] reg_result;

  logic start_pulse;

  fsm_state_t state, next_state;
  logic [ADDR_WIDTH:0] row_count;

  logic                          ib_wr_en, ib_rd_en, ib_full, ib_empty;
  logic [INPUT_ENTRY_WIDTH-1:0]  ib_wr_data, ib_rd_data;

  logic [BITMAP_WIDTH-1:0]   current_bitmap;
  logic [NUM_MACS-1:0]       mac_en;
  logic [SKIP_CNT_WIDTH-1:0] skip_count;

  logic [DATA_WIDTH-1:0]  mac_data [NUM_MACS];
  logic [ACCUM_WIDTH-1:0] mac_acc_out [NUM_MACS];
  logic [ACCUM_WIDTH-1:0] row_result;

  logic ob_wr_en, ob_rd_en, ob_full, ob_empty;
  logic [ACCUM_WIDTH-1:0] ob_wr_data, ob_rd_data;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axi_awready   <= 1'b0;
      s_axi_wready    <= 1'b0;
      s_axi_bvalid    <= 1'b0;
      s_axi_bresp     <= 2'b00;
      reg_ctrl        <= '0;
      reg_bitmap_lo   <= '0;
      reg_bitmap_hi   <= '0;
      reg_matrix_rows <= '0;
      reg_matrix_cols <= '0;
      reg_in_addr     <= '0;
      reg_out_addr    <= '0;
      start_pulse     <= 1'b0;
    end else begin
      start_pulse   <= 1'b0;
      s_axi_awready <= 1'b1;
      s_axi_wready  <= 1'b1;

      if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
        case (s_axi_awaddr)
          REG_CTRL: begin
            reg_ctrl <= s_axi_wdata;
            if (s_axi_wdata[0] == 1'b1) begin
              start_pulse <= 1'b1;
            end
          end
          REG_BITMAP_LO:   reg_bitmap_lo   <= s_axi_wdata;
          REG_BITMAP_HI:   reg_bitmap_hi   <= s_axi_wdata;
          REG_MATRIX_ROWS: reg_matrix_rows <= s_axi_wdata;
          REG_MATRIX_COLS: reg_matrix_cols <= s_axi_wdata;
          REG_IN_ADDR:     reg_in_addr     <= s_axi_wdata;
          REG_OUT_ADDR:    reg_out_addr    <= s_axi_wdata;
          default: ;
        endcase
        s_axi_bvalid <= 1'b1;
        s_axi_bresp  <= 2'b00;
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rdata   <= '0;
    end else begin
      s_axi_arready <= 1'b1;

      if (s_axi_arvalid && !s_axi_rvalid) begin
        case (s_axi_araddr)
          REG_STATUS:      s_axi_rdata <= reg_status;
          REG_PERF_CYC:    s_axi_rdata <= reg_perf_cyc;
          REG_PERF_SKIP:   s_axi_rdata <= reg_perf_skip;
          REG_MATRIX_ROWS: s_axi_rdata <= reg_matrix_rows;
          REG_MATRIX_COLS: s_axi_rdata <= reg_matrix_cols;
          REG_RESULT:      s_axi_rdata <= reg_result;
          default:         s_axi_rdata <= 32'hDEAD_BEEF;
        endcase
        s_axi_rvalid <= 1'b1;
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ST_IDLE;
    end else begin
      state <= next_state;
    end
  end

  always_comb begin
    next_state = state;
    case (state)
      ST_IDLE: begin
        if (start_pulse) next_state = ST_LOAD;
      end
      ST_LOAD: begin
        if (row_count >= reg_matrix_rows) next_state = ST_COMPUTE;
      end
      ST_COMPUTE: begin
        if (ib_empty) next_state = ST_WRITEBACK;
      end
      ST_WRITEBACK: begin
        if (ob_empty) next_state = ST_DONE;
      end
      ST_DONE: begin
        if (!reg_ctrl[0]) next_state = ST_IDLE;
      end
      default: next_state = ST_IDLE;
    endcase
  end

  assign busy     = (state != ST_IDLE);
  assign done_irq = (state == ST_DONE);

  always_comb begin
    reg_status = 32'h0;
    reg_status[0] = busy;
    reg_status[1] = (state == ST_DONE);
  end

  input_buffer u_input_buffer (
    .clk      (clk),
    .rst_n    (rst_n),
    .wr_en    (ib_wr_en),
    .wr_data  (ib_wr_data),
    .rd_en    (ib_rd_en),
    .rd_data  (ib_rd_data),
    .full     (ib_full),
    .empty    (ib_empty)
  );

  assign ib_wr_en   = (state == ST_LOAD) && !ib_full;
  assign ib_wr_data = {reg_bitmap_hi, reg_bitmap_lo,
                       {(DATA_WIDTH*NUM_MACS){1'b0}}};
  assign ib_rd_en   = (state == ST_COMPUTE) && !ib_empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      row_count <= '0;
    end else if (state == ST_LOAD && ib_wr_en) begin
      row_count <= row_count + 1'b1;
    end else if (state == ST_IDLE) begin
      row_count <= '0;
    end
  end

  assign current_bitmap = ib_rd_data[INPUT_ENTRY_WIDTH-1 : DATA_WIDTH*NUM_MACS];

  sparsity_ctrl u_sparsity_ctrl (
    .clk        (clk),
    .rst_n      (rst_n),
    .bitmap     (current_bitmap),
    .row_valid  (ib_rd_en),
    .mac_en     (mac_en),
    .skip_count (skip_count)
  );

  genvar i;
  generate
    for (i = 0; i < NUM_MACS; i++) begin : gen_mac_array
      assign mac_data[i] =
        ib_rd_data[(DATA_WIDTH*(i+1))-1 : DATA_WIDTH*i];

      sparse_mac u_mac (
        .clk     (clk),
        .rst_n   (rst_n),
        .clk_en  (mac_en[i]),
        .valid   (ib_rd_en),
        .a       (mac_data[i]),
        .b       (16'd1),
        .acc_in  ('0),
        .acc_out (mac_acc_out[i])
      );
    end
  endgenerate

  always_comb begin
    automatic logic signed [ACCUM_WIDTH-1:0] sum_acc;
    sum_acc = '0;
    for (int k = 0; k < NUM_MACS; k++) begin
      sum_acc = sum_acc + $signed(mac_acc_out[k]);
    end
    row_result = sum_acc;
  end

  output_buffer u_output_buffer (
    .clk      (clk),
    .rst_n    (rst_n),
    .wr_en    (ob_wr_en),
    .wr_data  (ob_wr_data),
    .rd_en    (ob_rd_en),
    .rd_data  (ob_rd_data),
    .full     (ob_full),
    .empty    (ob_empty)
  );

  assign ob_wr_data = row_result;
  assign ob_wr_en   = ib_rd_en && !ob_full;
  assign ob_rd_en   = (state == ST_WRITEBACK) && !ob_empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_result <= '0;
    end else if (ob_rd_en) begin
      reg_result <= ob_rd_data;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      reg_perf_cyc  <= '0;
      reg_perf_skip <= '0;
    end else if (state == ST_IDLE) begin
      reg_perf_cyc  <= '0;
      reg_perf_skip <= '0;
    end else begin
      reg_perf_cyc <= reg_perf_cyc + 1'b1;
      if (ib_rd_en) begin
        reg_perf_skip <= reg_perf_skip + skip_count;
      end
    end
  end

endmodule : sparseflow_top
