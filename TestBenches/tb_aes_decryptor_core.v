`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Core-only AES Decryptor Testbench (NIST Appendix C)
//////////////////////////////////////////////////////////////////////////////////
module tb_decryptor_core;

  // Clock & reset
  reg         clk   = 0;
  reg         rst_n;
  reg         start;

  // DUT I/O
  reg  [127:0] ciphertext;
  wire         valid;
  wire [127:0] plaintext_out;

  // Golden plaintext (Appendix C)
  localparam [127:0] GOLD = 128'h00112233_44556677_8899AABB_CCDDEEFF;

  // Precomputed round-keys (Appendix A.1)
  reg [127:0] round_keys[0:10];
  integer     i;

  // Instantiate the core-only wrapper
  aes_decryptor_core_top dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .start         (start),
    .ciphertext    (ciphertext),
    .rk0           (round_keys[0]),
    .rk1           (round_keys[1]),
    .rk2           (round_keys[2]),
    .rk3           (round_keys[3]),
    .rk4           (round_keys[4]),
    .rk5           (round_keys[5]),
    .rk6           (round_keys[6]),
    .rk7           (round_keys[7]),
    .rk8           (round_keys[8]),
    .rk9           (round_keys[9]),
    .rk10          (round_keys[10]),
    .valid         (valid),
    .plaintext_out (plaintext_out)
  );

  // 10 MHz clock
  always #50 clk = ~clk;

  initial begin
    // Load the official 11 round-keys
    round_keys[0]  = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    round_keys[1]  = 128'hd6aa74fd_d2af72fa_daa678f1_d6ab76fe;
    round_keys[2]  = 128'hb692cf0b_643dbdf1_be9bc500_6830b3fe;
    round_keys[3]  = 128'hb6ff744e_d2c2c9bf_6c590cbf_0469bf41;
    round_keys[4]  = 128'h47f7f7bc_95353e03_f96c32bc_fd058dfd;
    round_keys[5]  = 128'h3caaa3e8_a99f9deb_50f3af57_adf622aa;
    round_keys[6]  = 128'h5e390f7d_f7a69296_a7553dc1_0aa31f6b;
    round_keys[7]  = 128'h14f9701a_e35fe28c_440adf4d_4ea9c026;
    round_keys[8]  = 128'h47438735_a41c65b9_e016baf4_aebf7ad2;
    round_keys[9]  = 128'h549932d1_f0855768_1093ed9c_be2c974e;
    round_keys[10] = 128'h13111d7f_e3944a17_f307a78b_4d2b30c5;

    // 1) apply reset + official ciphertext
    rst_n      = 0;
    start      = 0;
    ciphertext = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;
    repeat (3) @(posedge clk);

    // 2) release reset, pulse start
    rst_n = 1;
    @(posedge clk); start = 1;
    @(posedge clk); start = 0;

    // 3) wait for valid, then check
    wait (valid);
    @(posedge clk); #1;
    if (plaintext_out === GOLD)
      $display("CORE-DECRYPT PASS: %h", plaintext_out);
    else
      $display("CORE-DECRYPT FAIL: got %h, expected %h",
               plaintext_out, GOLD);

    $finish;
  end

endmodule
