`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2025
// Module Name: tb_aes_key_expansion
// Project Name: AES
//////////////////////////////////////////////////////////////////////////////////

module tb_aes_key_expansion;
  reg          clk, rst_n, start;
  reg   [127:0] key_in;
  wire         valid;
  wire  [3:0]  round;
  wire  [127:0] round_key;

  // Golden schedule for 00010203…0E0F
  reg [127:0] expected [0:10];
  initial begin
    expected[0]  = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    expected[1]  = 128'hD6AA74FD_D2AF72FA_DAA678F1_D6AB76FE;
    expected[2]  = 128'hB692CF0B_643DBDF1_BE9BC500_6830B3FE;
    expected[3]  = 128'hB6FF744E_D2C2C9BF_6C590CBF_0469BF41;
    expected[4]  = 128'h47F7F7BC_95353E03_F96C32BC_FD058DFD;
    expected[5]  = 128'h3CAAA3E8_A99F9DEB_50F3AF57_ADF622AA;
    expected[6]  = 128'h5E390F7D_F7A69296_A7553DC1_0AA31F6B;
    expected[7]  = 128'h14F9701A_E35FE28C_440ADF4D_4EA9C026;
    expected[8]  = 128'h47438735_A41C65B9_E016BAF4_AEBF7AD2;
    expected[9]  = 128'h549932D1_F0855768_1093ED9C_BE2C974E;
    expected[10] = 128'h13111D7F_E3944A17_F307A78B_4D2B30C5;
  end

  // DUT instantiation
  aes_key_expansion dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (start),
    .key_in    (key_in),
    .valid     (valid),
    .round     (round),
    .round_key (round_key)
  );

  // Clock gen: 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // Reset and apply the master key
    rst_n  = 0;
    start  = 0;
    key_in = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    #20      rst_n = 1;  // release reset
    #10;

    // Pulse start to latch round 0
    @(posedge clk);
      start = 1;
    @(posedge clk);
      start = 0;

    // Now collect all 11 round keys
    repeat (11) begin
      @(posedge valid);
      #1;
      if (round_key !== expected[round]) begin
        $display("!!! ROUND %0d MISMATCH: got %h, expected %h",
                  round, round_key, expected[round]);
      end else begin
        $display("    ROUND %0d OK:      %h",
                  round, round_key);
      end
    end

    $finish;
  end

endmodule
