`timescale 1ns/1ps
module tb_aes_sbox;
  reg  [7:0] in;
  wire [7:0] out;

  // instantiate
  aes_sbox uut (
    .in(in),
    .out(out)
  );

  integer i;
  initial begin
    $display("in  => out");
    for (i = 0; i < 256; i = i + 1) begin
      in = i;
      #1;  // allow combinational to settle
      $display("%02h => %02h", in, out);
    end
    $finish;
  end
endmodule