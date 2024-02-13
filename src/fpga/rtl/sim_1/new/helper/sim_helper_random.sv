`timescale 1ns / 1ps
module sim_helper_random;
  int seed = 0;

  task init();
    int p_file;
    int result;
    int r;
    p_file = $fopen("rand.txt", "r");
    result = $fscanf(p_file, "%d", seed);
    $fclose(p_file);
    r = $random(seed);
  endtask

  function automatic longint range(longint max, longint min);
    automatic longint r = $random();
    range = ($unsigned(r) % (max - min + 1)) + min;
  endfunction

endmodule
