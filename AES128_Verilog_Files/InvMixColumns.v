`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// aes_inv_mixcolumns.v
// Inverse MixColumns: multiply each column by the matrix
//  [14 11 13  9]
//  [ 9 14 11 13]
//  [13  9 14 11]
//  [11 13  9 14]
//////////////////////////////////////////////////////////////////////////////////
module aes_inv_mixcolumns(
  input  wire [127:0] state_in,
  output wire [127:0] state_out
);
  // treat each column of 4 bytes
  genvar c;
  for(c=0;c<4;c=c+1) begin : col
    wire [7:0] a0 = state_in[8*(15-4*c)+:8];
    wire [7:0] a1 = state_in[8*(15-(4*c+1))+:8];
    wire [7:0] a2 = state_in[8*(15-(4*c+2))+:8];
    wire [7:0] a3 = state_in[8*(15-(4*c+3))+:8];

    // Galois-field multiply by constants 9,11,13,14
    function [7:0] xtime2; input [7:0] x;         xtime2 = (x<<1) ^ (x[7]?8'h1B:8'h00); endfunction
    function [7:0] mul;   input [7:0] x; input [3:0] m;
      case(m)
        4'h9:  mul = xtime2(xtime2(xtime2(x))) ^ x;
        4'hb:  mul = xtime2(xtime2(xtime2(x))) ^ xtime2(x) ^ x;
        4'hd:  mul = xtime2(xtime2(xtime2(x))) ^ xtime2(xtime2(x)) ^ x;
        4'he:  mul = xtime2(xtime2(xtime2(x))) ^ xtime2(xtime2(x)) ^ xtime2(x);
        default: mul = 8'h00;
      endcase
    endfunction

    wire [7:0] b0 = mul(a0,4'hE) ^ mul(a1,4'hB) ^ mul(a2,4'hD) ^ mul(a3,4'h9);
    wire [7:0] b1 = mul(a1,4'hE) ^ mul(a2,4'hB) ^ mul(a3,4'hD) ^ mul(a0,4'h9);
    wire [7:0] b2 = mul(a2,4'hE) ^ mul(a3,4'hB) ^ mul(a0,4'hD) ^ mul(a1,4'h9);
    wire [7:0] b3 = mul(a3,4'hE) ^ mul(a0,4'hB) ^ mul(a1,4'hD) ^ mul(a2,4'h9);

    assign state_out[8*(15-4*c)+:8]     = b0;
    assign state_out[8*(15-(4*c+1))+:8] = b1;
    assign state_out[8*(15-(4*c+2))+:8] = b2;
    assign state_out[8*(15-(4*c+3))+:8] = b3;
  end
endmodule
