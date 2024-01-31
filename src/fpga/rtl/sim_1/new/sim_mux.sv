`timescale 1ns / 1ps
module sim_mux ();

  logic CLK_20P48M;
  logic locked;
  sim_helper_clk sim_helper_clk (
      .CLK_20P48M(CLK_20P48M),
      .LOCKED(locked),
      .SYS_TIME()
  );

  localparam int DEPTH = 249;

  sim_helper_random sim_helper_random ();

  logic op_mode;
  logic [7:0] intensity_normal, phase_normal;
  logic dout_valid_normal;
  logic [7:0] intensity_stm, phase_stm;
  logic dout_valid_stm;
  logic [15:0] stm_idx, stm_start_idx, stm_finish_idx;
  logic use_stm_start_idx, use_stm_finish_idx;
  logic [7:0] intensity, phase;
  logic dout_valid;

  logic [7:0] intensity_buf_normal[DEPTH];
  logic [7:0] phase_buf_normal[DEPTH];
  logic [7:0] intensity_buf_stm[DEPTH];
  logic [7:0] phase_buf_stm[DEPTH];

  mux mux (
      .CLK(CLK_20P48M),
      .OP_MODE(op_mode),
      .INTENSITY_NORMAL(intensity_normal),
      .PHASE_NORMAL(phase_normal),
      .DOUT_VALID_NORMAL(dout_valid_normal),
      .INTENSITY_STM(intensity_stm),
      .PHASE_STM(phase_stm),
      .DOUT_VALID_STM(dout_valid_stm),
      .STM_IDX(stm_idx),
      .USE_STM_START_IDX(use_stm_start_idx),
      .USE_STM_FINISH_IDX(use_stm_finish_idx),
      .STM_START_IDX(stm_start_idx),
      .STM_FINISH_IDX(stm_finish_idx),
      .INTENSITY(intensity),
      .PHASE(phase),
      .DOUT_VALID(dout_valid)
  );

  task automatic set_normal();
    for (int i = 0; i < DEPTH; i++) begin
      intensity_buf_normal[i] = sim_helper_random.range(8'hFF, 0);
      phase_buf_normal[i] = sim_helper_random.range(8'hFF, 0);
    end
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK_20P48M);
      dout_valid_normal <= 1'b1;
      intensity_normal <= intensity_buf_normal[i];
      phase_normal <= phase_buf_normal[i];
    end
    @(posedge CLK_20P48M);
    dout_valid_normal <= 1'b0;
  endtask

  task automatic set_stm();
    for (int i = 0; i < DEPTH; i++) begin
      intensity_buf_stm[i] = sim_helper_random.range(8'hFF, 0);
      phase_buf_stm[i] = sim_helper_random.range(8'hFF, 0);
    end
    for (int i = 0; i < DEPTH; i++) begin
      @(posedge CLK_20P48M);
      dout_valid_stm <= 1'b1;
      intensity_stm <= intensity_buf_stm[i];
      phase_stm <= phase_buf_stm[i];
    end
    @(posedge CLK_20P48M);
    dout_valid_stm <= 1'b0;
  endtask

  task automatic check_normal();
    while (1) begin
      @(posedge CLK_20P48M);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      if (intensity_buf_normal[i] !== intensity) begin
        $display("failed at intensity[%d], %d!=%d", i, intensity_buf_normal[i], intensity);
        $finish();
      end
      if (phase_buf_normal[i] !== phase) begin
        $display("failed at phase[%d], %d!=%d", i, phase_buf_normal[i], phase);
        $finish();
      end
      @(posedge CLK_20P48M);
    end
  endtask

  task automatic check_stm();
    while (1) begin
      @(posedge CLK_20P48M);
      if (dout_valid) begin
        break;
      end
    end

    for (int i = 0; i < DEPTH; i++) begin
      if (intensity_buf_stm[i] !== intensity) begin
        $display("failed at intensity[%d], %d!=%d", i, intensity_buf_stm[i], intensity);
        $finish();
      end
      if (phase_buf_stm[i] !== phase) begin
        $display("failed at phase[%d], %d!=%d", i, phase_buf_stm[i], phase);
        $finish();
      end
      @(posedge CLK_20P48M);
    end
  endtask

  initial begin
    op_mode = 0;
    use_stm_start_idx = 0;
    use_stm_finish_idx = 0;

    sim_helper_random.init();

    @(posedge locked);

    $display("check normal");
    op_mode = 0;
    fork
      set_normal();
      set_stm();
      check_normal();
    join

    $display("check normal to stm");
    use_stm_start_idx = 0;
    use_stm_finish_idx = 0;
    op_mode = 1;
    fork
      set_normal();
      set_stm();
      check_stm();
    join

    $display("check stm to normal");
    op_mode = 0;
    fork
      set_normal();
      set_stm();
      check_normal();
    join

    $display("check stm idx...");
    use_stm_start_idx = 1;
    use_stm_finish_idx = 1;
    stm_start_idx = 1;
    stm_finish_idx = 2;
    stm_idx = 0;
    op_mode = 1;
    $display("\tstill normal");
    fork
      set_normal();
      set_stm();
      check_normal();
    join
    stm_idx = 1;
    $display("\tstm");
    fork
      set_normal();
      set_stm();
      check_stm();
    join
    op_mode = 0;
    $display("\tstill stm");
    fork
      set_normal();
      set_stm();
      check_stm();
    join
    stm_idx = 2;
    $display("\tnormal");
    fork
      set_normal();
      set_stm();
      check_normal();
    join

    $display("OK! sim_mux");
    $finish();
  end

endmodule
