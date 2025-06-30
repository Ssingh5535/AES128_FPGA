`timescale 1ns/1ps
module tb_aes_decryptor;

  // Clock & reset
  reg         clk = 0;
  reg         rst_n;

  // DUT inputs
  reg         start;
  reg  [127:0] key;
  reg  [127:0] ciphertext;

  // DUT outputs
  wire        valid;
  wire [127:0] plaintext_out;

  // Golden plaintext (NIST AES-128 test vector)
  localparam [127:0] GOLD = 128'h00112233_44556677_8899AABB_CCDDEEFF;

  // Instantiate the decrypter
  aes_decryptor_top dut (
    .clk           (clk),
    .rst_n         (rst_n),
    .start         (start),
    .key           (key),
    .ciphertext    (ciphertext),
    .valid         (valid),
    .plaintext_out (plaintext_out)
  );

  // 10 MHz clock
  always #50 clk = ~clk;

  initial begin
    // 1) apply reset and stimulus
    rst_n      = 0;
    start      = 0;
    key        = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    // <<< CORRECT NIST-AES CIPHERTEXT >>>
    ciphertext = 128'h69C4E0D8_6A7B0430_D8CDB780_70B4C55A;
    repeat (5) @(posedge clk);
    rst_n = 1;

    // 2) pulse start
    @(posedge clk); start = 1;
    @(posedge clk); start = 0;

    // 3) wait for valid
    wait (valid);
    @(posedge clk); #1;

    // 4) check result
    if (plaintext_out === GOLD)
      $display("FULL-DECRYPT PASS: %h", plaintext_out);
    else
      $display("FULL-DECRYPT FAIL: got %h, expected %h", plaintext_out, GOLD);

    $finish;
  end
endmodule
