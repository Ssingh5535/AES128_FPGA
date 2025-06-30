`timescale 1ns/1ps
module tb_aes_inv_sbox;

  // DUT I/O
  reg  [7:0]  in_byte;
  wire [7:0]  out_byte;

  // golden inverse S-box table
  reg [7:0] golden [0:255];
  integer   i;

  // instantiate the InvSBox
  aes_inv_sbox dut (
    .in  (in_byte),
    .out (out_byte)
  );

  initial begin
    // ------------------------------------------------------------------------
    // 1) Initialize the full 256-entry golden table (InvSBox from FIPS-197)
    // ------------------------------------------------------------------------
    golden[8'h00] = 8'h52; golden[8'h01] = 8'h09; golden[8'h02] = 8'h6A; golden[8'h03] = 8'hD5;
    golden[8'h04] = 8'h30; golden[8'h05] = 8'h36; golden[8'h06] = 8'hA5; golden[8'h07] = 8'h38;
    golden[8'h08] = 8'hBF; golden[8'h09] = 8'h40; golden[8'h0A] = 8'hA3; golden[8'h0B] = 8'h9E;
    golden[8'h0C] = 8'h81; golden[8'h0D] = 8'hF3; golden[8'h0E] = 8'hD7; golden[8'h0F] = 8'hFB;

    golden[8'h10] = 8'h7C; golden[8'h11] = 8'hE3; golden[8'h12] = 8'h39; golden[8'h13] = 8'h82;
    golden[8'h14] = 8'h9B; golden[8'h15] = 8'h2F; golden[8'h16] = 8'hFF; golden[8'h17] = 8'h87;
    golden[8'h18] = 8'h34; golden[8'h19] = 8'h8E; golden[8'h1A] = 8'h43; golden[8'h1B] = 8'h44;
    golden[8'h1C] = 8'hC4; golden[8'h1D] = 8'hDE; golden[8'h1E] = 8'hE9; golden[8'h1F] = 8'hCB;

    golden[8'h20] = 8'h54; golden[8'h21] = 8'h7B; golden[8'h22] = 8'h94; golden[8'h23] = 8'h32;
    golden[8'h24] = 8'hA6; golden[8'h25] = 8'hC2; golden[8'h26] = 8'h23; golden[8'h27] = 8'h3D;
    golden[8'h28] = 8'hEE; golden[8'h29] = 8'h4C; golden[8'h2A] = 8'h95; golden[8'h2B] = 8'h0B;
    golden[8'h2C] = 8'h42; golden[8'h2D] = 8'hFA; golden[8'h2E] = 8'hC3; golden[8'h2F] = 8'h4E;

    golden[8'h30] = 8'h08; golden[8'h31] = 8'h2E; golden[8'h32] = 8'hA1; golden[8'h33] = 8'h66;
    golden[8'h34] = 8'h28; golden[8'h35] = 8'hD9; golden[8'h36] = 8'h24; golden[8'h37] = 8'hB2;
    golden[8'h38] = 8'h76; golden[8'h39] = 8'h5B; golden[8'h3A] = 8'hA2; golden[8'h3B] = 8'h49;
    golden[8'h3C] = 8'h6D; golden[8'h3D] = 8'h8B; golden[8'h3E] = 8'hD1; golden[8'h3F] = 8'h25;

    golden[8'h40] = 8'h72; golden[8'h41] = 8'hF8; golden[8'h42] = 8'hF6; golden[8'h43] = 8'h64;
    golden[8'h44] = 8'h86; golden[8'h45] = 8'h68; golden[8'h46] = 8'h98; golden[8'h47] = 8'h16;
    golden[8'h48] = 8'hD4; golden[8'h49] = 8'hA4; golden[8'h4A] = 8'h5C; golden[8'h4B] = 8'hCC;
    golden[8'h4C] = 8'h5D; golden[8'h4D] = 8'h65; golden[8'h4E] = 8'hB6; golden[8'h4F] = 8'h92;

    golden[8'h50] = 8'h6C; golden[8'h51] = 8'h70; golden[8'h52] = 8'h48; golden[8'h53] = 8'h50;
    golden[8'h54] = 8'hFD; golden[8'h55] = 8'hED; golden[8'h56] = 8'hB9; golden[8'h57] = 8'hDA;
    golden[8'h58] = 8'h5E; golden[8'h59] = 8'h15; golden[8'h5A] = 8'h46; golden[8'h5B] = 8'h57;
    golden[8'h5C] = 8'hA7; golden[8'h5D] = 8'h8D; golden[8'h5E] = 8'h9D; golden[8'h5F] = 8'h84;

    golden[8'h60] = 8'h90; golden[8'h61] = 8'hD8; golden[8'h62] = 8'hAB; golden[8'h63] = 8'h00;
    golden[8'h64] = 8'h8C; golden[8'h65] = 8'hBC; golden[8'h66] = 8'hD3; golden[8'h67] = 8'h0A;
    golden[8'h68] = 8'hF7; golden[8'h69] = 8'hE4; golden[8'h6A] = 8'h58; golden[8'h6B] = 8'h05;
    golden[8'h6C] = 8'hB8; golden[8'h6D] = 8'hB3; golden[8'h6E] = 8'h45; golden[8'h6F] = 8'h06;

    golden[8'h70] = 8'hD0; golden[8'h71] = 8'h2C; golden[8'h72] = 8'h1E; golden[8'h73] = 8'h8F;
    golden[8'h74] = 8'hCA; golden[8'h75] = 8'h3F; golden[8'h76] = 8'h0F; golden[8'h77] = 8'h02;
    golden[8'h78] = 8'hC1; golden[8'h79] = 8'hAF; golden[8'h7A] = 8'hBD; golden[8'h7B] = 8'h03;
    golden[8'h7C] = 8'h01; golden[8'h7D] = 8'h13; golden[8'h7E] = 8'h8A; golden[8'h7F] = 8'h6B;

    golden[8'h80] = 8'h3A; golden[8'h81] = 8'h91; golden[8'h82] = 8'h11; golden[8'h83] = 8'h41;
    golden[8'h84] = 8'h4F; golden[8'h85] = 8'h67; golden[8'h86] = 8'hDC; golden[8'h87] = 8'hEA;
    golden[8'h88] = 8'h97; golden[8'h89] = 8'hF2; golden[8'h8A] = 8'hCF; golden[8'h8B] = 8'hCE;
    golden[8'h8C] = 8'hF0; golden[8'h8D] = 8'hB4; golden[8'h8E] = 8'hE6; golden[8'h8F] = 8'h73;

    golden[8'h90] = 8'h96; golden[8'h91] = 8'hAC; golden[8'h92] = 8'h74; golden[8'h93] = 8'h22;
    golden[8'h94] = 8'hE7; golden[8'h95] = 8'hAD; golden[8'h96] = 8'h35; golden[8'h97] = 8'h85;
    golden[8'h98] = 8'hE2; golden[8'h99] = 8'hF9; golden[8'h9A] = 8'h37; golden[8'h9B] = 8'hE8;
    golden[8'h9C] = 8'h1C; golden[8'h9D] = 8'h75; golden[8'h9E] = 8'hDF; golden[8'h9F] = 8'h6E;

    golden[8'hA0] = 8'h47; golden[8'hA1] = 8'hF1; golden[8'hA2] = 8'h1A; golden[8'hA3] = 8'h71;
    golden[8'hA4] = 8'h1D; golden[8'hA5] = 8'h29; golden[8'hA6] = 8'hC5; golden[8'hA7] = 8'h89;
    golden[8'hA8] = 8'h6F; golden[8'hA9] = 8'hB7; golden[8'hAA] = 8'h62; golden[8'hAB] = 8'h0E;
    golden[8'hAC] = 8'hAA; golden[8'hAD] = 8'h18; golden[8'hAE] = 8'hBE; golden[8'hAF] = 8'h1B;

    golden[8'hB0] = 8'hFC; golden[8'hB1] = 8'h56; golden[8'hB2] = 8'h3E; golden[8'hB3] = 8'h4B;
    golden[8'hB4] = 8'hC6; golden[8'hB5] = 8'hD2; golden[8'hB6] = 8'h79; golden[8'hB7] = 8'h20;
    golden[8'hB8] = 8'h9A; golden[8'hB9] = 8'hDB; golden[8'hBA] = 8'hC0; golden[8'hBB] = 8'hFE;
    golden[8'hBC] = 8'h78; golden[8'hBD] = 8'hCD; golden[8'hBE] = 8'h5A; golden[8'hBF] = 8'hF4;

    golden[8'hC0] = 8'h1F; golden[8'hC1] = 8'hDD; golden[8'hC2] = 8'hA8; golden[8'hC3] = 8'h33;
    golden[8'hC4] = 8'h88; golden[8'hC5] = 8'h07; golden[8'hC6] = 8'hC7; golden[8'hC7] = 8'h31;
    golden[8'hC8] = 8'hB1; golden[8'hC9] = 8'h12; golden[8'hCA] = 8'h10; golden[8'hCB] = 8'h59;
    golden[8'hCC] = 8'h27; golden[8'hCD] = 8'h80; golden[8'hCE] = 8'hEC; golden[8'hCF] = 8'h5F;

    golden[8'hD0] = 8'h60; golden[8'hD1] = 8'h51; golden[8'hD2] = 8'h7F; golden[8'hD3] = 8'hA9;
    golden[8'hD4] = 8'h19; golden[8'hD5] = 8'hB5; golden[8'hD6] = 8'h4A; golden[8'hD7] = 8'h0D;
    golden[8'hD8] = 8'h2D; golden[8'hD9] = 8'hE5; golden[8'hDA] = 8'h7A; golden[8'hDB] = 8'h9F;
    golden[8'hDC] = 8'h93; golden[8'hDD] = 8'hC9; golden[8'hDE] = 8'h9C; golden[8'hDF] = 8'hEF;

    golden[8'hE0] = 8'hA0; golden[8'hE1] = 8'hE0; golden[8'hE2] = 8'h3B; golden[8'hE3] = 8'h4D;
    golden[8'hE4] = 8'hAE; golden[8'hE5] = 8'h2A; golden[8'hE6] = 8'hF5; golden[8'hE7] = 8'hB0;
    golden[8'hE8] = 8'hC8; golden[8'hE9] = 8'hEB; golden[8'hEA] = 8'hBB; golden[8'hEB] = 8'h3C;
    golden[8'hEC] = 8'h83; golden[8'hED] = 8'h53; golden[8'hEE] = 8'h99; golden[8'hEF] = 8'h61;

    golden[8'hF0] = 8'h17; golden[8'hF1] = 8'h2B; golden[8'hF2] = 8'h04; golden[8'hF3] = 8'h7E;
    golden[8'hF4] = 8'hBA; golden[8'hF5] = 8'h77; golden[8'hF6] = 8'hD6; golden[8'hF7] = 8'h26;
    golden[8'hF8] = 8'hE1; golden[8'hF9] = 8'h69; golden[8'hFA] = 8'h14; golden[8'hFB] = 8'h63;
    golden[8'hFC] = 8'h55; golden[8'hFD] = 8'h21; golden[8'hFE] = 8'h0C; golden[8'hFF] = 8'h7D;

    // ------------------------------------------------------------------------
    // 2) Apply every possible input and compare
    // ------------------------------------------------------------------------
    for (i = 0; i < 256; i = i + 1) begin
      in_byte = i;
      #1;  // allow the comb. paths to settle
      if (out_byte !== golden[i]) begin
        $display("FAIL: inv_sbox[0x%02h] = 0x%02h (expected 0x%02h)", 
                  i, out_byte, golden[i]);
      end
    end

    $display("aes_inv_sbox test complete");
    $finish;
  end

endmodule
