`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Top-level AES-128 Decryptor
//  • Runs internal key-expander to produce rk_mem[0..10]
//  • **CRITICAL**: captures the master key into rk_mem[0] on the start pulse
//  • Waits until all 11 round-keys are ready, then kicks off the core
//  • Instantiates aes_decryptor_core_top with 11 separate rk ports
//////////////////////////////////////////////////////////////////////////////////
module aes_decryptor_top(
  input  wire        clk,           // 10 MHz clock
  input  wire        rst_n,         // active-low reset
  input  wire        start,         // pulse: valid ciphertext in
  input  wire [127:0] key,          // master AES key
  input  wire [127:0] ciphertext,   // block to decrypt

  output wire        valid,         // pulses when plaintext is ready
  output wire [127:0] plaintext_out // decrypted block
);

  //-------------------------------------------------------------------------
  // 1) Key-Expansion
  //-------------------------------------------------------------------------
  wire         ke_valid;
  wire  [3:0]  ke_round;
  wire [127:0] ke_roundkey;
  reg          ke_start;

  // latch user 'start' → key-expander start
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      ke_start <= 1'b0;
    else
      ke_start <= start;
  end

  aes_key_expansion keyexp (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (ke_start),
    .key_in    (key),
    .valid     (ke_valid),
    .round     (ke_round),
    .round_key (ke_roundkey)
  );

  // capture all 11 round-keys into rk_mem[0..10]
  reg [127:0] rk_mem [0:10];
  integer     ji;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (ji = 0; ji < 11; ji = ji + 1)
        rk_mem[ji] <= 128'd0;
    end else begin
      // **CRITICAL**: grab the master key into rk_mem[0] on the very first start
      if (ke_start)
        rk_mem[0] <= key;

      // then store each generated round-key into its slot
      else if (ke_valid)
        rk_mem[ke_round] <= ke_roundkey;
    end
  end

  //-------------------------------------------------------------------------
  // 2) Gating logic: wait for rk_mem[10] before starting decrypt core
  //-------------------------------------------------------------------------
  reg key_done, start_req, core_start;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      key_done   <= 1'b0;
      start_req  <= 1'b0;
      core_start <= 1'b0;
    end else begin
      if (start)
        start_req <= 1'b1;

      if (ke_valid && ke_round == 4'd10)
        key_done <= 1'b1;

      if (start_req && key_done) begin
        core_start <= 1'b1;
        start_req  <= 1'b0;
      end else begin
        core_start <= 1'b0;
      end
    end
  end

  //-------------------------------------------------------------------------
  // 3) Core-only decryptor
  //-------------------------------------------------------------------------
  aes_decryptor_core_top core (
    .clk           (clk),
    .rst_n         (rst_n),
    .start         (core_start),
    .ciphertext    (ciphertext),

    .rk0           (rk_mem[0]),
    .rk1           (rk_mem[1]),
    .rk2           (rk_mem[2]),
    .rk3           (rk_mem[3]),
    .rk4           (rk_mem[4]),
    .rk5           (rk_mem[5]),
    .rk6           (rk_mem[6]),
    .rk7           (rk_mem[7]),
    .rk8           (rk_mem[8]),
    .rk9           (rk_mem[9]),
    .rk10          (rk_mem[10]),

    .valid         (valid),
    .plaintext_out (plaintext_out)
  );

endmodule
