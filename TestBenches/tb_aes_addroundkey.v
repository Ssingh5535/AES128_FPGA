`timescale 1ns/1ps
module tb_aes_addroundkey;
  reg  [127:0] a, b;
  wire [127:0] y;

  AddRoundKey uut (
    .state_in(a),
    .round_key(b),
    .state_out(y)
  );

  initial begin
    a = 128'hFFFFFFFF_00000000_FF00FF00_12345678;
    b = 128'h00000000_FFFFFFFF_00FF00FF_87654321;
    #1;
    $display("A = %h", a);
    $display("B = %h", b);
    $display("Y = %h", y);  // expect FFFFFFFF^00000000 = FFFFFFFF, etc.
    $finish;
  end
endmodule
