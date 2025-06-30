`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2025 11:54:44 AM
// Design Name: 
// Module Name: tb_aes_roundtrip
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
//////////////////////////////////////////////////////////////////////////////////
// TB: AES-128 encrypt → decrypt round-trip for an arbitrary 16-byte string
//////////////////////////////////////////////////////////////////////////////////
module tb_aes_roundtrip;

  // Clock & reset
  reg        clk   = 0;
  reg        rst_n = 0;
  always #50 clk = ~clk;  // 10 MHz

  // Test string (must be exactly 16 characters)
  localparam MSG_LEN = 16;
  reg [8*MSG_LEN-1:0] test_str = "Hello, AES World";

  // Pack ASCII string into a 128-bit vector (big-endian)
  wire [127:0] plaintext;
  genvar i;
  generate
    for (i = 0; i < MSG_LEN; i = i+1) begin
      assign plaintext[8*(MSG_LEN-1-i) +: 8] = test_str[8*i +: 8];
    end
  endgenerate

  // Master key (you can change at will)
  reg [127:0] key = 128'h00010203_04050607_08090A0B_0C0D0E0F;

  //-------------------------------------------------------------------------
  // Encryption side signals
  //-------------------------------------------------------------------------
  reg         enc_start;
  wire        enc_valid;
  wire [127:0] enc_cipher;

  // Instantiate your encryptor
  aes_encryptor_top u_enc (
    .clk        (clk),
    .rst_n      (rst_n),
    .start      (enc_start),
    .key        (key),
    .plaintext  (plaintext),
    .ciphertext (enc_cipher),
    .valid      (enc_valid)
  );

  //-------------------------------------------------------------------------
  // Decryption side signals
  //-------------------------------------------------------------------------
  reg         dec_start;
  wire        dec_valid;
  wire [127:0] dec_plain;

  // Instantiate your decryptor
  aes_decryptor_top u_dec (
    .clk           (clk),
    .rst_n         (rst_n),
    .start         (dec_start),
    .key           (key),
    .ciphertext    (enc_cipher),
    .valid         (dec_valid),
    .plaintext_out (dec_plain)
  );

  //-------------------------------------------------------------------------
  // Test sequence
  //-------------------------------------------------------------------------
  initial begin
    // 1) hold reset
    #200;
    rst_n = 1;

    // 2) kick off encryption
    @(posedge clk);
      enc_start = 1;
    @(posedge clk);
      enc_start = 0;

    // 3) wait for ciphertext
    wait (enc_valid);
    @(posedge clk);

    // 4) kick off decryption
    @(posedge clk);
      dec_start = 1;
    @(posedge clk);
      dec_start = 0;

    // 5) wait for plaintext_out
    wait (dec_valid);
    @(posedge clk);

    // 6) compare round-trip
    if (dec_plain === plaintext) begin
      $display("ROUNDTRIP PASS: \"%s\" → %h → \"%s\"",
               test_str, enc_cipher, dec_plain);
    end else begin
      $display("ROUNDTRIP FAIL!");
      $display("  IN   = \"%s\"", test_str);
      $display("  KEY  = %h", key);
      $display("  CIPH = %h", enc_cipher);
      $display("  OUT  = %h", dec_plain);
    end

    $finish;
  end

endmodule
