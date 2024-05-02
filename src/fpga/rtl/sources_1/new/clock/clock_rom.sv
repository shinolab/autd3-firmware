`timescale 1ns / 1ps
module clock_rom (
    input wire CLK,
    clock_bus_if.out_port CLOCK_BUS,
    output var [38:0] ROM[32],
    output wire UPDATE
);

  logic we;
  logic [4:0] addr;
  logic [38:0] din;
  logic [38:0] dout;

  logic [4:0] rom_addr;
  logic update;

  assign CLOCK_BUS.WE = we;
  assign CLOCK_BUS.ADDR = addr;
  assign CLOCK_BUS.DIN = {15'd0, din};
  assign dout = CLOCK_BUS.DOUT[38:0];
  assign UPDATE = update;

  typedef enum logic [3:0] {
    WAIT,
    WAIT_BRAM_0,
    WAIT_BRAM_1,
    WAIT_BRAM_2,
    LOAD
  } state_t;

  state_t state = WAIT;

  always_ff @(posedge CLK) begin
    case (state)
      WAIT: begin
        update <= 1'b0;
        addr   <= 5'h1F;
        if (dout[0]) begin
          we <= 1'b1;
          rom_addr <= '0;
          din <= '0;
          state <= WAIT_BRAM_0;
        end else begin
          we <= 1'b0;
          state <= WAIT;
        end
      end
      WAIT_BRAM_0: begin
        we <= 1'b0;
        addr <= '0;
        state <= WAIT_BRAM_1;
      end
      WAIT_BRAM_1: begin
        addr  <= addr + 1;
        state <= WAIT_BRAM_2;
      end
      WAIT_BRAM_2: begin
        addr  <= addr + 1;
        state <= LOAD;
      end
      LOAD: begin
        ROM[rom_addr] <= dout;
        addr <= addr + 1;
        rom_addr <= rom_addr + 1;
        if (rom_addr == 22) begin
          update <= 1'b1;
          state  <= WAIT;
        end else begin
          state <= LOAD;
        end
      end

    endcase
  end

endmodule
