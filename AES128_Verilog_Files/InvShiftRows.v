`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// aes_inv_shiftrows.v
// Inverse ShiftRows:  row 0 no shift, row1 right-1, row2 right-2, row3 right-3
//////////////////////////////////////////////////////////////////////////////////
module aes_inv_shiftrows(
  input  wire [127:0] state_in,
  output wire [127:0] state_out
);
  // break into bytes [r,c]
  wire [7:0] s[0:15];
  genvar i;
  for(i=0;i<16;i=i+1)
    assign s[i] = state_in[8*(15-i)+:8];

  // rearrange:
  // row 0: s[ 0] s[ 4] s[ 8] s[12]  (no change)
  // row 1: s[ 1] s[ 5] s[ 9] s[13] -> rotate right by 1
  // row 2: s[ 2] s[ 6] s[10] s[14] -> rotate right by 2
  // row 3: s[ 3] s[ 7] s[11] s[15] -> rotate right by 3
  wire [7:0] t[0:15];
  assign t[ 0] = s[ 0];
  assign t[ 4] = s[ 4];
  assign t[ 8] = s[ 8];
  assign t[12] = s[12];

  assign t[ 1] = s[13];
  assign t[ 5] = s[ 1];
  assign t[ 9] = s[ 5];
  assign t[13] = s[ 9];

  assign t[ 2] = s[10];
  assign t[ 6] = s[14];
  assign t[10] = s[ 2];
  assign t[14] = s[ 6];

  assign t[ 3] = s[ 7];
  assign t[ 7] = s[11];
  assign t[11] = s[15];
  assign t[15] = s[ 3];

  // pack back out
  generate
    for(i=0;i<16;i=i+1) begin : pack_out
      assign state_out[8*(15-i)+:8] = t[i];
    end
  endgenerate
endmodule
