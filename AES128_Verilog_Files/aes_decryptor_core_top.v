`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Core-only AES-128 Decryption wrapper, debug prints, correct final-round FSM
//////////////////////////////////////////////////////////////////////////////////
module aes_decryptor_core_top(
  input  wire        clk,
  input  wire        rst_n,        // active-low
  input  wire        start,        // pulse: valid ciphertext in
  input  wire [127:0] ciphertext,  // block to decrypt

  // Eleven separately-driven round keys:
  input  wire [127:0] rk0,
  input  wire [127:0] rk1,
  input  wire [127:0] rk2,
  input  wire [127:0] rk3,
  input  wire [127:0] rk4,
  input  wire [127:0] rk5,
  input  wire [127:0] rk6,
  input  wire [127:0] rk7,
  input  wire [127:0] rk8,
  input  wire [127:0] rk9,
  input  wire [127:0] rk10,

  output reg         valid,        // pulses when plaintext_out is ready
  output reg  [127:0] plaintext_out
);

  //------------------------------------------------------------------------
  // Select one of the 11 round-keys by index
  //------------------------------------------------------------------------
  function [127:0] select_key(input [3:0] r);
    case(r)
      4'd0:  select_key = rk0;
      4'd1:  select_key = rk1;
      4'd2:  select_key = rk2;
      4'd3:  select_key = rk3;
      4'd4:  select_key = rk4;
      4'd5:  select_key = rk5;
      4'd6:  select_key = rk6;
      4'd7:  select_key = rk7;
      4'd8:  select_key = rk8;
      4'd9:  select_key = rk9;
      4'd10: select_key = rk10;
      default: select_key = 128'd0;
    endcase
  endfunction

  //------------------------------------------------------------------------
  // 1) InvShiftRows
  //------------------------------------------------------------------------
  reg  [127:0] state_reg;
  wire [127:0] after_shift;
  aes_inv_shiftrows U_ISR (
    .state_in  (state_reg),
    .state_out (after_shift)
  );

  //------------------------------------------------------------------------
  // 2) InvSubBytes
  //------------------------------------------------------------------------
  wire [7:0] sb_in  [0:15];
  wire [7:0] sb_out [0:15];
  genvar gi;
  generate
    for (gi = 0; gi < 16; gi = gi + 1) begin : INV_SBOXES
      assign sb_in[gi] = after_shift[8*(15-gi)+:8];
      aes_inv_sbox U_ISB (
        .in  (sb_in[gi]),
        .out (sb_out[gi])
      );
    end
  endgenerate

  // pack back to 128-bit
  wire [127:0] subblock;
  generate
    for (gi = 0; gi < 16; gi = gi + 1)
      assign subblock[8*(15-gi)+:8] = sb_out[gi];
  endgenerate

  //------------------------------------------------------------------------
  // 3) AddRoundKey
  //------------------------------------------------------------------------
  reg  [3:0]   rnd;
  wire [127:0] after_sub = subblock ^ select_key(rnd);

  //------------------------------------------------------------------------
  // 4) InvMixColumns
  //------------------------------------------------------------------------
  wire [127:0] after_mix;
  aes_inv_mixcolumns U_IMC (
    .state_in  (after_sub),
    .state_out (after_mix)
  );

  //------------------------------------------------------------------------
  // 5) FSM with debug printing & correct final-round skip
  //------------------------------------------------------------------------
  localparam IDLE  = 2'b00,
             LOAD  = 2'b01,
             ROUND = 2'b10,
             FINAL = 2'b11;
  reg [1:0] state;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state         <= IDLE;
      state_reg     <= 128'd0;
      rnd           <= 4'd0;
      valid         <= 1'b0;
      plaintext_out <= 128'd0;
      $display("[%0t] ~~ RESET ~~", $time);
    end else begin
      // cycle-by-cycle header
      $display("[%0t] CLK: state=%b start=%b rnd=%0d state_reg=%h",
               $time, state, start, rnd, state_reg);
      valid <= 1'b0;

      case(state)

        // IDLE: wait for start, grab CT ^ rk10
        IDLE: if (start) begin
          $display("[%0t] IDLE→LOAD: CT=%h ^ RK10=%h = %h",
                   $time, ciphertext, select_key(10),
                   (ciphertext ^ select_key(10)));
          state_reg <= ciphertext ^ select_key(10);
          rnd       <= 4'd9;
          state     <= LOAD;
        end

        // LOAD: let the new state_reg settle for one cycle
        LOAD: begin
          $display("[%0t] LOAD : state_reg settled = %h", $time, state_reg);
          state <= ROUND;
        end

        // ROUND: do rounds 9 down to 1
        ROUND: begin
          if (rnd > 0) begin
            $display("[%0t] ROUND%0d start: state_in = %h", $time, rnd+1, state_reg);
            $display("    after_shift = %h", after_shift);
            $display("    after_sub   = %h  (sub=%h ^ rk%0d=%h)",
                     after_sub, subblock, rnd, select_key(rnd));
            $display("    after_mix   = %h", after_mix);

            state_reg <= after_mix;
            rnd       <= rnd - 1;
          end else begin
            // rnd == 0: skip MixColumns, go straight to FINAL
            $display("[%0t] ROUND0: skipping mix, entering FINAL", $time);
            state <= FINAL;
          end
        end

        // FINAL: InvShiftRows + InvSubBytes + AddRoundKey(rk0)
        FINAL: begin
          $display("[%0t] FINAL start: state_in = %h", $time, state_reg);
          $display("    after_shift = %h", after_shift);
          $display("    after_sub   = %h  (PLAINTEXT)", after_sub);
          plaintext_out <= after_sub;
          valid         <= 1'b1;
          state         <= IDLE;
        end

      endcase
    end
  end

endmodule
