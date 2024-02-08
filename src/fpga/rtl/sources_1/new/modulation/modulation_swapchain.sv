`timescale 1ns / 1ps
module modulation_swapchain (
    input var CLK,
    input var UPDATE_SETTINGS,
    input var REQ_RD_SEGMENT,
    input var [31:0] REP,
    mod_cnt_if.swapchain_port MOD_CNT
);

  logic segment = 0;
  logic req_segment;
  logic stop = 0;
  logic [31:0] rep;
  logic [31:0] loop_cnt;

  logic [14:0] idx_0, idx_1;

  logic idx_0_changed, idx_1_changed;
  logic [14:0] idx_0_buf, idx_1_buf;

  assign idx_0 = MOD_CNT.IDX_0;
  assign idx_1 = MOD_CNT.IDX_1;
  assign MOD_CNT.SEGMENT = segment;
  assign MOD_CNT.STOP = stop;

  typedef enum logic [1:0] {
    WAIT_START,
    FINITE_LOOP,
    INFINITE_LOOP
  } state_t;

  state_t state = INFINITE_LOOP;

  always_ff @(posedge CLK) begin
    if (UPDATE_SETTINGS) begin
      if (REQ_RD_SEGMENT === segment) begin
        stop  <= 1'b0;
        state <= INFINITE_LOOP;
      end else begin
        if (REP === 32'hFFFFFFFF) begin
          stop <= 1'b0;
          segment <= REQ_RD_SEGMENT;
          state <= INFINITE_LOOP;
        end else begin
          rep <= REP;
          req_segment <= REQ_RD_SEGMENT;
          state <= WAIT_START;
        end
      end
    end else begin
      case (state)
        WAIT_START: begin
          if (req_segment === 1'b0) begin
            if (idx_0 === '0) begin
              stop <= 1'b0;
              loop_cnt <= '0;
              segment <= 1'b0;
              state <= FINITE_LOOP;
            end else begin
              state <= WAIT_START;
            end
          end else begin
            if (idx_1 === '0) begin
              stop <= 1'b0;
              loop_cnt <= '0;
              segment <= 1'b1;
              state <= FINITE_LOOP;
            end else begin
              state <= WAIT_START;
            end
          end
        end
        INFINITE_LOOP: begin
          state <= INFINITE_LOOP;
        end
        FINITE_LOOP: begin
          if (segment === 1'b0) begin
            if (idx_0_changed & (idx_0 === '0)) begin
              if (loop_cnt === rep) begin
                stop <= 1'b1;
              end else begin
                loop_cnt <= loop_cnt + 1;
              end
            end
          end else begin
            if (idx_1_changed & (idx_1 === '0)) begin
              if (loop_cnt === rep) begin
                stop <= 1'b1;
              end else begin
                loop_cnt <= loop_cnt + 1;
              end
            end
          end
        end
        default: begin
          state <= INFINITE_LOOP;
        end
      endcase
    end
  end

  always_ff @(posedge CLK) begin
    idx_0_buf <= idx_0;
    idx_1_buf <= idx_1;
  end

  assign idx_0_changed = idx_0_buf !== idx_0;
  assign idx_1_changed = idx_1_buf !== idx_1;

endmodule
