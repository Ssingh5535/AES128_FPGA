`timescale 1ns/1ps

module tb_aes_encryptor;

  // Clock, reset, and I/O
  reg         clk;
  reg         rst_n;
  reg         start;
  reg  [127:0] key;
  reg  [127:0] plaintext;
  wire [127:0] ciphertext;
  wire        valid;

  // Instantiate your AES encryptor
  aes_encryptor_top dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (start),
    .key       (key),
    .plaintext (plaintext),
    .ciphertext(ciphertext),
    .valid     (valid)
  );

  // 1) Clock generation: 100 MHz → 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // 2) Stimulus
  initial begin
    // Dump waveform
    $dumpfile("tb_aes_encryptor.vcd");
    $dumpvars(0, tb_aes_encryptor);

    // Initial conditions
    rst_n     = 0;
    start     = 0;
    key       = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    plaintext = 128'h00112233_44556677_8899AABB_CCDDEEFF;

    // Apply reset
    #20;
    rst_n = 1;
    #20;

    // 3) Launch encryption
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // 4) Wait for the valid pulse
    wait (valid == 1);
    #1;  // small margin

    // 5) Check result
    if (ciphertext === 128'h69C4E0D8_6A7B0430_D8CDB780_70B4C55A) begin
      $display("PASS: ciphertext = %h", ciphertext);
    end else begin
      $display("FAIL: got %h, expected 69C4E0D86A7B0430D8CDB78070B4C55A", ciphertext);
    end

    $finish;
  end

endmodule
