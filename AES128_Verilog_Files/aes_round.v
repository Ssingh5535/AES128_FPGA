`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 02:36:45 AM
// Design Name: 
// Module Name: aes_round
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module aes_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);
    // 1) SubBytes
    wire [127:0] sb_out;
    genvar i;
    generate
      for (i = 0; i < 16; i = i + 1) begin : SUBBYTES
        aes_sbox u_sbox (
          .in  (state_in[8*(15-i)+:8]),
          .out (sb_out  [8*(15-i)+:8])
        );
      end
    endgenerate

    // 2) ShiftRows
    wire [127:0] sr_out;
    ShiftRows u_sr (
      .state_in(sb_out),
      .state_out(sr_out)
    );

    // 3) MixColumns
    wire [127:0] mc_out;
    MixColumns u_mc (
      .state_in(sr_out),
      .state_out(mc_out)
    );

    // 4) AddRoundKey
    AddRoundKey u_ark (
      .state_in (mc_out),
      .round_key(round_key),
      .state_out(state_out)
    );
endmodule