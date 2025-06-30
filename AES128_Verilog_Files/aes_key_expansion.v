`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: aes_key_expansion
// AES-128 on-the-fly key schedule generator with debug tracing
//////////////////////////////////////////////////////////////////////////////////
module aes_key_expansion (
  input  wire         clk,
  input  wire         rst_n,      // active-low reset
  input  wire         start,      // one-cycle pulse to grab key_in
  input  wire [127:0] key_in,     // master key = round 0
  output reg          valid,      // pulses when round_key is ready
  output reg  [3:0]   round,      // 0…10
  output reg  [127:0] round_key   // current 128-bit round key
);

  //--- Internal storage & state -------------------
  reg [31:0] w         [0:43];      // 44 words
  reg [5:0]  i;                     // next word index
  reg        busy;                  // high while expanding
  reg [31:0] rotated, next_word;    // working registers
  integer    k;

  //--- AES S-Box as a function -------------------
  function [7:0] sbox_byte(input [7:0] b);
    begin
      case (b)
        8'h00: sbox_byte = 8'h63;  8'h01: sbox_byte = 8'h7c;
        8'h02: sbox_byte = 8'h77;  8'h03: sbox_byte = 8'h7b;
        8'h04: sbox_byte = 8'hf2;  8'h05: sbox_byte = 8'h6b;
        8'h06: sbox_byte = 8'h6f;  8'h07: sbox_byte = 8'hc5;
        8'h08: sbox_byte = 8'h30;  8'h09: sbox_byte = 8'h01;
        8'h0A: sbox_byte = 8'h67;  8'h0B: sbox_byte = 8'h2b;
        8'h0C: sbox_byte = 8'hfe;  8'h0D: sbox_byte = 8'hd7;
        8'h0E: sbox_byte = 8'hab;  8'h0F: sbox_byte = 8'h76;
        8'h10: sbox_byte = 8'hca;  8'h11: sbox_byte = 8'h82;
        8'h12: sbox_byte = 8'hc9;  8'h13: sbox_byte = 8'h7d;
        8'h14: sbox_byte = 8'hfa;  8'h15: sbox_byte = 8'h59;
        8'h16: sbox_byte = 8'h47;  8'h17: sbox_byte = 8'hf0;
        8'h18: sbox_byte = 8'had;  8'h19: sbox_byte = 8'hd4;
        8'h1A: sbox_byte = 8'ha2;  8'h1B: sbox_byte = 8'haf;
        8'h1C: sbox_byte = 8'h9c;  8'h1D: sbox_byte = 8'ha4;
        8'h1E: sbox_byte = 8'h72;  8'h1F: sbox_byte = 8'hc0;
        8'h20: sbox_byte = 8'hb7;  8'h21: sbox_byte = 8'hfd;
        8'h22: sbox_byte = 8'h93;  8'h23: sbox_byte = 8'h26;
        8'h24: sbox_byte = 8'h36;  8'h25: sbox_byte = 8'h3f;
        8'h26: sbox_byte = 8'hf7;  8'h27: sbox_byte = 8'hcc;
        8'h28: sbox_byte = 8'h34;  8'h29: sbox_byte = 8'ha5;
        8'h2A: sbox_byte = 8'he5;  8'h2B: sbox_byte = 8'hf1;
        8'h2C: sbox_byte = 8'h71;  8'h2D: sbox_byte = 8'hd8;
        8'h2E: sbox_byte = 8'h31;  8'h2F: sbox_byte = 8'h15;
        8'h30: sbox_byte = 8'h04;  8'h31: sbox_byte = 8'hc7;
        8'h32: sbox_byte = 8'h23;  8'h33: sbox_byte = 8'hc3;
        8'h34: sbox_byte = 8'h18;  8'h35: sbox_byte = 8'h96;
        8'h36: sbox_byte = 8'h05;  8'h37: sbox_byte = 8'h9a;
        8'h38: sbox_byte = 8'h07;  8'h39: sbox_byte = 8'h12;
        8'h3A: sbox_byte = 8'h80;  8'h3B: sbox_byte = 8'he2;
        8'h3C: sbox_byte = 8'heb;  8'h3D: sbox_byte = 8'h27;
        8'h3E: sbox_byte = 8'hb2;  8'h3F: sbox_byte = 8'h75;
        8'h40: sbox_byte = 8'h09;  8'h41: sbox_byte = 8'h83;
        8'h42: sbox_byte = 8'h2c;  8'h43: sbox_byte = 8'h1a;
        8'h44: sbox_byte = 8'h1b;  8'h45: sbox_byte = 8'h6e;
        8'h46: sbox_byte = 8'h5a;  8'h47: sbox_byte = 8'ha0;
        8'h48: sbox_byte = 8'h52;  8'h49: sbox_byte = 8'h3b;
        8'h4A: sbox_byte = 8'hd6;  8'h4B: sbox_byte = 8'hb3;
        8'h4C: sbox_byte = 8'h29;  8'h4D: sbox_byte = 8'he3;
        8'h4E: sbox_byte = 8'h2f;  8'h4F: sbox_byte = 8'h84;
        8'h50: sbox_byte = 8'h53;  8'h51: sbox_byte = 8'hd1;
        8'h52: sbox_byte = 8'h00;  8'h53: sbox_byte = 8'hed;
        8'h54: sbox_byte = 8'h20;  8'h55: sbox_byte = 8'hfc;
        8'h56: sbox_byte = 8'hb1;  8'h57: sbox_byte = 8'h5b;
        8'h58: sbox_byte = 8'h6a;  8'h59: sbox_byte = 8'hcb;
        8'h5A: sbox_byte = 8'hbe;  8'h5B: sbox_byte = 8'h39;
        8'h5C: sbox_byte = 8'h4a;  8'h5D: sbox_byte = 8'h4c;
        8'h5E: sbox_byte = 8'h58;  8'h5F: sbox_byte = 8'hcf;
        8'h60: sbox_byte = 8'hd0;  8'h61: sbox_byte = 8'hef;
        8'h62: sbox_byte = 8'haa;  8'h63: sbox_byte = 8'hfb;
        8'h64: sbox_byte = 8'h43;  8'h65: sbox_byte = 8'h4d;
        8'h66: sbox_byte = 8'h33;  8'h67: sbox_byte = 8'h85;
        8'h68: sbox_byte = 8'h45;  8'h69: sbox_byte = 8'hf9;
        8'h6A: sbox_byte = 8'h02;  8'h6B: sbox_byte = 8'h7f;
        8'h6C: sbox_byte = 8'h50;  8'h6D: sbox_byte = 8'h3c;
        8'h6E: sbox_byte = 8'h9f;  8'h6F: sbox_byte = 8'ha8;
        8'h70: sbox_byte = 8'h51;  8'h71: sbox_byte = 8'ha3;
        8'h72: sbox_byte = 8'h40;  8'h73: sbox_byte = 8'h8f;
        8'h74: sbox_byte = 8'h92;  8'h75: sbox_byte = 8'h9d;
        8'h76: sbox_byte = 8'h38;  8'h77: sbox_byte = 8'hf5;
        8'h78: sbox_byte = 8'hbc;  8'h79: sbox_byte = 8'hb6;
        8'h7A: sbox_byte = 8'hda;  8'h7B: sbox_byte = 8'h21;
        8'h7C: sbox_byte = 8'h10;  8'h7D: sbox_byte = 8'hff;
        8'h7E: sbox_byte = 8'hf3;  8'h7F: sbox_byte = 8'hd2;
        8'h80: sbox_byte = 8'hcd;  8'h81: sbox_byte = 8'h0c;
        8'h82: sbox_byte = 8'h13;  8'h83: sbox_byte = 8'hec;
        8'h84: sbox_byte = 8'h5f;  8'h85: sbox_byte = 8'h97;
        8'h86: sbox_byte = 8'h44;  8'h87: sbox_byte = 8'h17;
        8'h88: sbox_byte = 8'hc4;  8'h89: sbox_byte = 8'ha7;
        8'h8A: sbox_byte = 8'h7e;  8'h8B: sbox_byte = 8'h3d;
        8'h8C: sbox_byte = 8'h64;  8'h8D: sbox_byte = 8'h5d;
        8'h8E: sbox_byte = 8'h19;  8'h8F: sbox_byte = 8'h73;
        8'h90: sbox_byte = 8'h60;  8'h91: sbox_byte = 8'h81;
        8'h92: sbox_byte = 8'h4f;  8'h93: sbox_byte = 8'hdc;
        8'h94: sbox_byte = 8'h22;  8'h95: sbox_byte = 8'h2a;
        8'h96: sbox_byte = 8'h90;  8'h97: sbox_byte = 8'h88;
        8'h98: sbox_byte = 8'h46;  8'h99: sbox_byte = 8'hee;
        8'h9A: sbox_byte = 8'hb8;  8'h9B: sbox_byte = 8'h14;
        8'h9C: sbox_byte = 8'hde;  8'h9D: sbox_byte = 8'h5e;
        8'h9E: sbox_byte = 8'h0b;  8'h9F: sbox_byte = 8'hdb;
        8'hA0: sbox_byte = 8'he0;  8'hA1: sbox_byte = 8'h32;
        8'hA2: sbox_byte = 8'h3a;  8'hA3: sbox_byte = 8'h0a;
        8'hA4: sbox_byte = 8'h49;  8'hA5: sbox_byte = 8'h06;
        8'hA6: sbox_byte = 8'h24;  8'hA7: sbox_byte = 8'h5c;
        8'hA8: sbox_byte = 8'hc2;  8'hA9: sbox_byte = 8'hd3;
        8'hAA: sbox_byte = 8'hac;  8'hAB: sbox_byte = 8'h62;
        8'hAC: sbox_byte = 8'h91;  8'hAD: sbox_byte = 8'h95;
        8'hAE: sbox_byte = 8'he4;  8'hAF: sbox_byte = 8'h79;
        8'hB0: sbox_byte = 8'he7;  8'hB1: sbox_byte = 8'hc8;
        8'hB2: sbox_byte = 8'h37;  8'hB3: sbox_byte = 8'h6d;
        8'hB4: sbox_byte = 8'h8d;  8'hB5: sbox_byte = 8'hd5;
        8'hB6: sbox_byte = 8'h4e;  8'hB7: sbox_byte = 8'ha9;
        8'hB8: sbox_byte = 8'h6c;  8'hB9: sbox_byte = 8'h56;
        8'hBA: sbox_byte = 8'hf4;  8'hBB: sbox_byte = 8'hea;
        8'hBC: sbox_byte = 8'h65;  8'hBD: sbox_byte = 8'h7a;
        8'hBE: sbox_byte = 8'hae;  8'hBF: sbox_byte = 8'h08;
        8'hC0: sbox_byte = 8'hba;  8'hC1: sbox_byte = 8'h78;
        8'hC2: sbox_byte = 8'h25;  8'hC3: sbox_byte = 8'h2e;
        8'hC4: sbox_byte = 8'h1c;  8'hC5: sbox_byte = 8'ha6;
        8'hC6: sbox_byte = 8'hb4;  8'hC7: sbox_byte = 8'hc6;
        8'hC8: sbox_byte = 8'he8;  8'hC9: sbox_byte = 8'hdd;
        8'hCA: sbox_byte = 8'h74;  8'hCB: sbox_byte = 8'h1f;
        8'hCC: sbox_byte = 8'h4b;  8'hCD: sbox_byte = 8'hbd;
        8'hCE: sbox_byte = 8'h8b;  8'hCF: sbox_byte = 8'h8a;
        8'hD0: sbox_byte = 8'h70;  8'hD1: sbox_byte = 8'h3e;
        8'hD2: sbox_byte = 8'hb5;  8'hD3: sbox_byte = 8'h66;
        8'hD4: sbox_byte = 8'h48;  8'hD5: sbox_byte = 8'h03;
        8'hD6: sbox_byte = 8'hf6;  8'hD7: sbox_byte = 8'h0e;
        8'hD8: sbox_byte = 8'h61;  8'hD9: sbox_byte = 8'h35;
        8'hDA: sbox_byte = 8'h57;  8'hDB: sbox_byte = 8'hb9;
        8'hDC: sbox_byte = 8'h86;  8'hDD: sbox_byte = 8'hc1;
        8'hDE: sbox_byte = 8'h1d;  8'hDF: sbox_byte = 8'h9e;
        8'hE0: sbox_byte = 8'he1;  8'hE1: sbox_byte = 8'hf8;
        8'hE2: sbox_byte = 8'h98;  8'hE3: sbox_byte = 8'h11;
        8'hE4: sbox_byte = 8'h69;  8'hE5: sbox_byte = 8'hd9;
        8'hE6: sbox_byte = 8'h8e;  8'hE7: sbox_byte = 8'h94;
        8'hE8: sbox_byte = 8'h9b;  8'hE9: sbox_byte = 8'h1e;
        8'hEA: sbox_byte = 8'h87;  8'hEB: sbox_byte = 8'he9;
        8'hEC: sbox_byte = 8'hce;  8'hED: sbox_byte = 8'h55;
        8'hEE: sbox_byte = 8'h28;  8'hEF: sbox_byte = 8'hdf;
        8'hF0: sbox_byte = 8'h8c;  8'hF1: sbox_byte = 8'ha1;
        8'hF2: sbox_byte = 8'h89;  8'hF3: sbox_byte = 8'h0d;
        8'hF4: sbox_byte = 8'hBF;
  8'hF5: sbox_byte = 8'hE6;
  8'hF6: sbox_byte = 8'h42;
  8'hF7: sbox_byte = 8'h68;
  8'hF8: sbox_byte = 8'h41;
  8'hF9: sbox_byte = 8'h99;
  8'hFA: sbox_byte = 8'h2D;
  8'hFB: sbox_byte = 8'h0F;
  8'hFC: sbox_byte = 8'hB0;
  8'hFD: sbox_byte = 8'h54;
  8'hFE: sbox_byte = 8'hBB;
  8'hFF: sbox_byte = 8'h16;
      endcase
    end
  endfunction

  //--- Rcon generator for AES-128 -------------------
  function [31:0] Rcon_word(input [3:0] r);
    begin
      case (r)
        4'd1:  Rcon_word = 32'h01000000;
        4'd2:  Rcon_word = 32'h02000000;
        4'd3:  Rcon_word = 32'h04000000;
        4'd4:  Rcon_word = 32'h08000000;
        4'd5:  Rcon_word = 32'h10000000;
        4'd6:  Rcon_word = 32'h20000000;
        4'd7:  Rcon_word = 32'h40000000;
        4'd8:  Rcon_word = 32'h80000000;
        4'd9:  Rcon_word = 32'h1B000000;
        4'd10: Rcon_word = 32'h36000000;
        default: Rcon_word = 32'h00000000;
      endcase
    end
  endfunction

  //--- Main FSM: reset → latch round 0 → expand ------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy      <= 1'b0;
      valid     <= 1'b0;
      i         <= 6'd0;
      round     <= 4'd0;
      round_key <= 128'd0;
      for (k = 0; k < 44; k = k + 1)
        w[k] <= 32'h0;
    end else begin
      valid <= 1'b0;

      // Round 0: latch the master key
      if (start && !busy) begin
        w[0] <= key_in[127:96];
        w[1] <= key_in[95 :64];
        w[2] <= key_in[63 :32];
        w[3] <= key_in[31 : 0];
        round_key <= key_in;
        round     <= 4'd0;
        valid     <= 1'b1;
        busy      <= 1'b1;
        i         <= 6'd4;
      end
      // Key expansion in progress
      else if (busy) begin

        // compute next_word
        if (i[1:0] == 2'd0) begin
          // RotWord + SubWord + Rcon
          rotated   = { w[i-1][23:0], w[i-1][31:24] };
          next_word = w[i-4]
                    ^ { sbox_byte(rotated[31:24]),
                         sbox_byte(rotated[23:16]),
                         sbox_byte(rotated[15: 8]),
                         sbox_byte(rotated[ 7: 0]) }
                    ^ Rcon_word(i >> 2);
        end else begin
          // simple XOR
          next_word = w[i-4] ^ w[i-1];
        end

        // *** DEBUG TRACE ***
        $display("i=%0d: w[%0d]=%h  rot=%h  sb=[%02h %02h %02h %02h]  Rcon=%h  next=%h",
                 i-1, i-1, w[i-1],
                 rotated,
                 sbox_byte(rotated[31:24]),
                 sbox_byte(rotated[23:16]),
                 sbox_byte(rotated[15: 8]),
                 sbox_byte(rotated[ 7: 0]),
                 Rcon_word(i>>2),
                 next_word);

        // store it
        w[i] <= next_word;

        // emit a round_key every 4 words
        if (i[1:0] == 2'd3) begin
          round     <= i[5:2];
          round_key <= { w[i-3], w[i-2], w[i-1], next_word };
          valid     <= 1'b1;
        end

        // done after w[43]
        if (i == 6'd43)
          busy <= 1'b0;

        i <= i + 6'd1;
      end
    end
  end

endmodule
