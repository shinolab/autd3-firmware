function automatic [7:0] cvt_uid(input [7:0] idx);
  if (idx < 8'd19) begin
    cvt_uid = idx;
  end else if (idx < 8'd32) begin
    cvt_uid = idx + 2;
  end else begin
    cvt_uid = idx + 3;
  end
endfunction
