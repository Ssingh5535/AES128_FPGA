module aes_final_round (
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

    // 3) AddRoundKey
    AddRoundKey u_ark (
      .state_in (sr_out),
      .round_key(round_key),
      .state_out(state_out)
    );
endmodule
