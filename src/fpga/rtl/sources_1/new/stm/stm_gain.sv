`timescale 1ns / 1ps
module stm_gain #(
    parameter int DEPTH = 249
) (
    input wire CLK,
    input wire START,
    input wire [12:0] IDX,
    stm_bus_if.out_gain_port STM_BUS,
    output wire [7:0] INTENSITY,
    output wire [7:0] PHASE,
    output wire DOUT_VALID
);

  logic [7:0] intensity;
  logic [7:0] phase;
  logic dout_valid;

  logic [511:0] data_out;

  logic [7:0] addr;
  logic [$clog2(DEPTH)-1:0] cnt;

  typedef enum logic [1:0] {
    WAITING,
    BRAM_WAIT_0,
    BRAM_WAIT_1,
    RUN
  } state_t;

  state_t state = WAITING;

  assign STM_BUS.GAIN_IDX = IDX[9:0];
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
        cnt   <= '0;
        addr  <= addr + 1;
        state <= RUN;
      end
      RUN: begin
        addr <= addr + 1;
        dout_valid <= 1;
        cnt <= cnt + 1;
        case (cnt[4:0])
          5'h0: begin
            phase <= data_out[7:0];
            intensity <= data_out[15:8];
          end
          5'h1: begin
            phase <= data_out[23:16];
            intensity <= data_out[31:24];
          end
          5'h2: begin
            phase <= data_out[39:32];
            intensity <= data_out[47:40];
          end
          5'h3: begin
            phase <= data_out[55:48];
            intensity <= data_out[63:56];
          end
          5'h4: begin
            phase <= data_out[71:64];
            intensity <= data_out[79:72];
          end
          5'h5: begin
            phase <= data_out[87:80];
            intensity <= data_out[95:88];
          end
          5'h6: begin
            phase <= data_out[103:96];
            intensity <= data_out[111:104];
          end
          5'h7: begin
            phase <= data_out[119:112];
            intensity <= data_out[127:120];
          end
          5'h8: begin
            phase <= data_out[135:128];
            intensity <= data_out[143:136];
          end
          5'h9: begin
            phase <= data_out[151:144];
            intensity <= data_out[159:152];
          end
          5'hA: begin
            phase <= data_out[167:160];
            intensity <= data_out[175:168];
          end
          5'hB: begin
            phase <= data_out[183:176];
            intensity <= data_out[191:184];
          end
          5'hC: begin
            phase <= data_out[199:192];
            intensity <= data_out[207:200];
          end
          5'hD: begin
            phase <= data_out[215:208];
            intensity <= data_out[223:216];
          end
          5'hE: begin
            phase <= data_out[231:224];
            intensity <= data_out[239:232];
          end
          5'hF: begin
            phase <= data_out[247:240];
            intensity <= data_out[255:248];
          end
          5'h10: begin
            phase <= data_out[263:256];
            intensity <= data_out[271:264];
          end
          5'h11: begin
            phase <= data_out[279:272];
            intensity <= data_out[287:280];
          end
          5'h12: begin
            phase <= data_out[295:288];
            intensity <= data_out[303:296];
          end
          5'h13: begin
            phase <= data_out[311:304];
            intensity <= data_out[319:312];
          end
          5'h14: begin
            phase <= data_out[327:320];
            intensity <= data_out[335:328];
          end
          5'h15: begin
            phase <= data_out[343:336];
            intensity <= data_out[351:344];
          end
          5'h16: begin
            phase <= data_out[359:352];
            intensity <= data_out[367:360];
          end
          5'h17: begin
            phase <= data_out[375:368];
            intensity <= data_out[383:376];
          end
          5'h18: begin
            phase <= data_out[391:384];
            intensity <= data_out[399:392];
          end
          5'h19: begin
            phase <= data_out[407:400];
            intensity <= data_out[415:408];
          end
          5'h1A: begin
            phase <= data_out[423:416];
            intensity <= data_out[431:424];
          end
          5'h1B: begin
            phase <= data_out[439:432];
            intensity <= data_out[447:440];
          end
          5'h1C: begin
            phase <= data_out[455:448];
            intensity <= data_out[463:456];
          end
          5'h1D: begin
            phase <= data_out[471:464];
            intensity <= data_out[479:472];
          end
          5'h1E: begin
            phase <= data_out[487:480];
            intensity <= data_out[495:488];
          end
          5'h1F: begin
            phase <= data_out[503:496];
            intensity <= data_out[511:504];
          end
          default: begin
          end
        endcase
        state <= (cnt == DEPTH - 1) ? WAITING : state;
      end
      default: state <= WAITING;
    endcase
  end

endmodule
