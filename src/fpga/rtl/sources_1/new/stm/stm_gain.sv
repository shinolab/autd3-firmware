`timescale 1ns / 1ps
module stm_gain #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire START,
    input wire [15:0] IDX,
    stm_bus_if.out_gain_port STM_BUS,
    output var [7:0] INTENSITY,
    output var [7:0] PHASE,
    output var DOUT_VALID
);

  logic [7:0] intensity;
  logic [7:0] phase;
  logic dout_valid;

  logic [63:0] data_out;

  logic [7:0] addr;
  logic [1:0] set_cnt;
  logic [$clog2(DEPTH):0] cnt;

  typedef enum logic [1:0] {
    WAITING,
    BRAM_WAIT_0,
    BRAM_WAIT_1,
    RUN
  } state_t;

  state_t state = WAITING;

  assign STM_BUS.GAIN_IDX = IDX;
  assign STM_BUS.GAIN_ADDR = addr;
  assign data_out = STM_BUS.VALUE;

  assign INTENSITY = intensity;
  assign PHASE = phase;
  assign DOUT_VALID = dout_valid;

  always_ff @(posedge CLK) begin
    case (state)
      WAITING: begin
        dout_valid <= 1'b0;
        if (START) begin
          addr  <= '0;
          state <= BRAM_WAIT_0;
        end
      end
      BRAM_WAIT_0: begin
        addr  <= addr + 1;
        state <= BRAM_WAIT_1;
      end
      BRAM_WAIT_1: begin
        cnt <= '0;
        addr <= addr + 1;
        set_cnt <= '0;
        state <= RUN;
      end
      RUN: begin
        addr <= addr + 1;
        dout_valid <= 1;
        case (set_cnt)
          0: begin
            phase <= data_out[7:0];
            intensity <= data_out[15:8];
          end
          1: begin
            phase <= data_out[23:16];
            intensity <= data_out[31:24];
          end
          2: begin
            phase <= data_out[39:32];
            intensity <= data_out[47:40];
          end
          3: begin
            phase <= data_out[55:48];
            intensity <= data_out[63:56];
          end
          default: begin
          end
        endcase
        set_cnt <= set_cnt + 1;
        cnt <= cnt + 1;
        if (cnt == DEPTH - 1) begin
          state <= WAITING;
        end
      end
      default: begin
      end
    endcase
  end

endmodule
