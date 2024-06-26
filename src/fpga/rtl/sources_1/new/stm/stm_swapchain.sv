`timescale 1ns / 1ps
module stm_swapchain (
    input wire CLK,
    input wire [63:0] SYS_TIME,
    input wire UPDATE_SETTINGS,
    input wire REQ_RD_SEGMENT,
    input wire [7:0] TRANSITION_MODE,
    input wire [63:0] TRANSITION_VALUE,
    input wire [17:0] ECAT_SYNC_BASE_CNT,
    input wire [12:0] CYCLE[params::NumSegment],
    input wire [31:0] REP[params::NumSegment],
    input wire [12:0] SYNC_IDX[params::NumSegment],
    input wire GPIO_IN[4],
    output wire STOP,
    output wire SEGMENT,
    output wire [12:0] IDX[params::NumSegment]
);

  logic segment = 1'b0;
  logic req_segment;
  logic stop = 1'b0;
  logic ext_mode = 1'b0;
  logic [31:0] rep;
  logic [31:0] loop_cnt;

  logic idx_changed[params::NumSegment];
  logic [12:0] idx_old[params::NumSegment];
  logic [12:0] tic_idx[params::NumSegment];

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

  localparam int LATENCY = 66 + 4 + 1;
  logic [$clog2(LATENCY)-1:0] diff_latency;
  logic [63:0] lap;
  logic [31:0] lap_rem_unused;
  logic [63:0] transition_time;
  div_64_32 div_64_32_lap (
      .s_axis_dividend_tdata(TRANSITION_VALUE),
      .s_axis_dividend_tvalid(1'b1),
      .s_axis_divisor_tdata(params::ECATSyncBase),
      .s_axis_divisor_tvalid(1'b1),
      .aclk(CLK),
      .m_axis_dout_tdata({lap, lap_rem_unused}),
      .m_axis_dout_tvalid()
  );
  mult_sync_base mult_sync_base_time (
      .CLK(CLK),
      .A  (lap),
      .B  (ECAT_SYNC_BASE_CNT),
      .P  (transition_time)
  );
  addsub_64_64 addsub_diff_time (
      .CLK(CLK),
      .A  ({1'b0, transition_time}),
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
        ext_mode <= TRANSITION_MODE == params::TRANSITION_MODE_EXT;
        state <= INFINITE_LOOP;
      end else begin
        if (REP[REQ_RD_SEGMENT] == 32'hFFFFFFFF) begin
          stop <= 1'b0;
          segment <= REQ_RD_SEGMENT;
          idx_mode <= IDX_MODE_SYNC_IDX;
          ext_mode <= TRANSITION_MODE == params::TRANSITION_MODE_EXT;
          state <= INFINITE_LOOP;
        end else begin
          rep <= REP[REQ_RD_SEGMENT];
          req_segment <= REQ_RD_SEGMENT;
          diff_latency <= '0;
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
              if (diff_latency == LATENCY - 1) begin
                if (time_diff[64]) begin
                  stop <= 1'b0;
                  loop_cnt <= '0;
                  segment <= req_segment;
                  idx_mode <= IDX_MODE_TIC;
                  tic_idx[req_segment] <= '0;
                  state <= FINITE_LOOP;
                end
              end else begin
                diff_latency <= diff_latency + 1;
                state <= WAIT_START;
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
            default: ;
          endcase
        end
        INFINITE_LOOP: begin
          if (ext_mode) begin
            if (idx_changed[segment] & (SYNC_IDX[segment] == '0)) begin
              segment <= ~segment;
            end
          end
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
            default: ;
          endcase
        end
        default: state <= INFINITE_LOOP;
      endcase
    end
  end

  always_ff @(posedge CLK) idx_old <= SYNC_IDX;

endmodule
