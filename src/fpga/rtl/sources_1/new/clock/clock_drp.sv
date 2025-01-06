`timescale 1ps / 1ps
module clock_drp (
    input wire CLK,
    input wire LOCKED,
    input wire [38:0] ROM[32],
    input wire UPDATE,
    output reg [6:0] DADDR,
    input wire DRDY,
    output reg DWE,
    output reg [15:0] DIN,
    input wire [15:0] DOUT,
    output reg DEN,
    output wire DCLK,
    output reg RESET
);

  localparam int Tcq = 100;

  localparam int StateCntConst = 23;

  assign DCLK = CLK;

  logic [ 5:0] rom_addr;
  logic [ 5:0] state_cnt;
  logic [38:0] rom_do;

  logic [ 6:0] next_daddr;
  logic        next_dwe;
  logic        next_den;
  logic [15:0] next_din;
  logic        next_mmcm_reset = 1'b1;
  logic [ 5:0] next_rom_addr;
  logic [ 5:0] next_state_cnt = StateCntConst;

  typedef enum logic [3:0] {
    RESTART,
    WAIT_LOCK,
    IDLE,
    LOAD_ROM,
    ADDRESS,
    WAIT_A_DRDY,
    BITMASK,
    BITSET,
    WRITE,
    WAIT_DRDY
  } state_t;

  state_t current_state;
  state_t next_state = RESTART;

  always_ff @(posedge CLK) begin
    rom_do        <= #Tcq ROM[rom_addr];
    DADDR         <= #Tcq next_daddr;
    DWE           <= #Tcq next_dwe;
    DEN           <= #Tcq next_den;
    DIN           <= #Tcq next_din;
    RESET         <= #Tcq next_mmcm_reset;
    rom_addr      <= #Tcq next_rom_addr;
    state_cnt     <= #Tcq next_state_cnt;
    current_state <= #Tcq next_state;
  end

  always_comb begin
    next_daddr      = DADDR;
    next_dwe        = 1'b0;
    next_den        = 1'b0;
    next_mmcm_reset = RESET;
    next_din        = DIN;
    next_rom_addr   = rom_addr;
    next_state_cnt  = state_cnt;

    case (current_state)
      RESTART: begin
        next_daddr      = 7'h00;
        next_din        = 16'h0000;
        next_rom_addr   = 6'h00;
        next_mmcm_reset = 1'b1;
        next_state      = WAIT_LOCK;
      end
      WAIT_LOCK: begin
        next_mmcm_reset = 1'b0;
        next_state_cnt = StateCntConst;
        next_rom_addr = '0;
        next_state = LOCKED ? IDLE : WAIT_LOCK;
      end
      IDLE: begin
        next_rom_addr = '0;
        next_state = UPDATE ? ADDRESS : IDLE;
      end
      ADDRESS: begin
        next_mmcm_reset = 1'b1;
        next_den = 1'b1;
        next_daddr = rom_do[38:32];
        next_state = WAIT_A_DRDY;
      end
      WAIT_A_DRDY: begin
        next_state = DRDY ? BITMASK : WAIT_A_DRDY;
      end
      BITMASK: begin
        next_din   = rom_do[31:16] & DOUT;
        next_state = BITSET;
      end
      BITSET: begin
        next_din      = rom_do[15:0] | DIN;
        next_rom_addr = rom_addr + 1'b1;
        next_state    = WRITE;
      end
      WRITE: begin
        next_dwe       = 1'b1;
        next_den       = 1'b1;
        next_state_cnt = state_cnt - 1'b1;
        next_state     = WAIT_DRDY;
      end
      WAIT_DRDY: begin
        if (DRDY) next_state = state_cnt > 0 ? ADDRESS : WAIT_LOCK;
        else next_state = WAIT_DRDY;
      end
      default: begin
        next_state = RESTART;
      end
    endcase
  end

endmodule
