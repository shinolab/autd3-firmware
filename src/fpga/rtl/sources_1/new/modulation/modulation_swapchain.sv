`timescale 1ns / 1ps
module modulation_swapchain (
    input wire CLK,
    input wire UPDATE_SETTINGS,
    input wire REQ_RD_SEGMENT,
    input wire [31:0] REP[2],
    input wire [14:0] IDX_IN[2],
    output wire SEGMENT,
    output wire STOP,
    output wire [14:0] IDX_OUT[2]
);

  logic segment = 0;
  logic req_segment;
  logic stop = 0;
  logic [31:0] rep;
  logic [31:0] loop_cnt;

  logic [14:0] idx[2];

  logic idx_changed[2];
  logic [14:0] idx_buf[2];

  assign idx = IDX_IN;
  assign SEGMENT = segment;
  assign STOP = stop;
  assign IDX_OUT = idx_buf;

  typedef enum logic [1:0] {
    WAIT_START,
    FINITE_LOOP,
    INFINITE_LOOP
  } state_t;

  state_t state = INFINITE_LOOP;

  always_ff @(posedge CLK) begin
    if (UPDATE_SETTINGS) begin
      if (REQ_RD_SEGMENT == segment) begin
        stop  <= 1'b0;
        state <= INFINITE_LOOP;
      end else begin
        if (((REQ_RD_SEGMENT == 1'b0) & (REP[0] == 32'hFFFFFFFF)) | ((REQ_RD_SEGMENT == 1'b1) & (REP[1] == 32'hFFFFFFFF))) begin
          stop <= 1'b0;
          segment <= REQ_RD_SEGMENT;
          state <= INFINITE_LOOP;
        end else begin
          rep <= REQ_RD_SEGMENT == 1'b0 ? REP[0] : REP[1];
          req_segment <= REQ_RD_SEGMENT;
          state <= WAIT_START;
        end
      end
    end else begin
      case (state)
        WAIT_START: begin
          if (req_segment == 1'b0) begin
            if (idx[0] == '0) begin
              stop <= 1'b0;
              loop_cnt <= '0;
              segment <= 1'b0;
              state <= FINITE_LOOP;
            end else begin
              state <= WAIT_START;
            end
          end else begin
            if (idx[1] == '0) begin
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
          if (segment == 1'b0) begin
            if (idx_changed[0] & (idx[0] == '0)) begin
              if (loop_cnt == rep) begin
                stop <= 1'b1;
              end else begin
                loop_cnt <= loop_cnt + 1;
              end
            end
          end else begin
            if (idx_changed[1] & (idx[1] == '0)) begin
              if (loop_cnt == rep) begin
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
    idx_buf <= idx;
  end

  assign idx_changed[0] = idx_buf[0] != idx[0];
  assign idx_changed[1] = idx_buf[1] != idx[1];

endmodule
