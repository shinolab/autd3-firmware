`timescale 1ns / 1ps
module modulation_swapchain (
    input wire CLK,
    input wire [63:0] SYS_TIME,
    input wire UPDATE_SETTINGS,
    input wire REQ_RD_SEGMENT,
    input wire [7:0] TRANSITION_MODE,
    input wire [63:0] TRANSITION_VALUE,
    input wire [14:0] CYCLE[params::NumSegment],
    input wire [31:0] REP[params::NumSegment],
    input wire [14:0] SYNC_IDX[params::NumSegment],
    input wire GPIO_IN[4],
    output wire STOP,
    output wire SEGMENT,
    output wire [14:0] IDX[params::NumSegment]
);

  logic segment = 1'b0;
  logic req_segment;
  logic stop = 1'b0;
  logic [31:0] rep;
  logic [31:0] loop_cnt;

  logic idx_changed[params::NumSegment];
  logic [14:0] idx_old[params::NumSegment];
  logic [14:0] tic_idx[params::NumSegment];

  logic signed [64:0] time_diff;

  assign SEGMENT = segment;
  assign STOP = stop;

  typedef enum logic {
    IDX_MODE_SYNC_IDX,
    IDX_MODE_TIC
  } idx_mode_t;

  typedef enum logic [1:0] {
    WAIT_START,
    FINITE_LOOP,
    INFINITE_LOOP
  } state_t;

  idx_mode_t idx_mode = IDX_MODE_SYNC_IDX;
  state_t state = INFINITE_LOOP;

  addsub_64_64 addsub_diff_time (
      .CLK(CLK),
      .A  ({1'b0, TRANSITION_VALUE}),
      .B  ({1'b0, SYS_TIME}),
      .ADD(1'b0),
      .S  (time_diff)
  );

  for (genvar i = 0; i < params::NumSegment; i++) begin : gen_stm_swapchain
    assign idx_changed[i] = idx_old[i] != SYNC_IDX[i];
    assign IDX[i] = (idx_mode == IDX_MODE_SYNC_IDX) ? idx_old[i] : tic_idx[i];
  end

  always_ff @(posedge CLK) begin
    if (UPDATE_SETTINGS) begin
      if (REQ_RD_SEGMENT == segment) begin
        stop <= 1'b0;
        idx_mode <= IDX_MODE_SYNC_IDX;
        state <= INFINITE_LOOP;
      end else begin
        if (REP[REQ_RD_SEGMENT] == 32'hFFFFFFFF) begin
          stop <= 1'b0;
          segment <= REQ_RD_SEGMENT;
          idx_mode <= IDX_MODE_SYNC_IDX;
          state <= INFINITE_LOOP;
        end else begin
          rep <= REP[REQ_RD_SEGMENT];
          req_segment <= REQ_RD_SEGMENT;
          state <= WAIT_START;
        end
      end
    end else begin
      case (state)
        WAIT_START: begin
          case (TRANSITION_MODE)
            params::TRANSITION_MODE_SYNC_IDX: begin
              if (idx_changed[req_segment] && (SYNC_IDX[req_segment] == '0)) begin
                stop <= 1'b0;
                loop_cnt <= '0;
                segment <= req_segment;
                idx_mode <= IDX_MODE_SYNC_IDX;
                state <= FINITE_LOOP;
              end
            end
            params::TRANSITION_MODE_SYS_TIME: begin
              if (time_diff[64]) begin
                stop <= 1'b0;
                loop_cnt <= '0;
                segment <= req_segment;
                idx_mode <= IDX_MODE_TIC;
                tic_idx[req_segment] <= '0;
                state <= FINITE_LOOP;
              end
            end
            params::TRANSITION_MODE_GPIO: begin
              if (idx_changed[req_segment] && GPIO_IN[TRANSITION_VALUE]) begin
                stop <= 1'b0;
                loop_cnt <= '0;
                segment <= req_segment;
                idx_mode <= IDX_MODE_TIC;
                tic_idx[req_segment] <= '0;
                state <= FINITE_LOOP;
              end
            end
          endcase
        end
        INFINITE_LOOP: begin
          state <= INFINITE_LOOP;
        end
        FINITE_LOOP: begin
          case (idx_mode)
            IDX_MODE_SYNC_IDX: begin
              if (idx_changed[segment] & (SYNC_IDX[segment] == '0)) begin
                if (loop_cnt == rep) begin
                  stop <= 1'b1;
                end else begin
                  loop_cnt <= loop_cnt + 1;
                end
              end
            end
            IDX_MODE_TIC: begin
              if (idx_changed[segment]) begin
                if (tic_idx[segment] == CYCLE[segment]) begin
                  tic_idx[segment] <= '0;
                  if (loop_cnt == rep) begin
                    stop <= 1'b1;
                  end else begin
                    loop_cnt <= loop_cnt + 1;
                  end
                end else begin
                  tic_idx[segment] <= tic_idx[segment] + 1;
                end
              end
            end
          endcase
        end
        default: begin
          state <= INFINITE_LOOP;
        end
      endcase
    end
  end

  always_ff @(posedge CLK) idx_old <= SYNC_IDX;

endmodule
