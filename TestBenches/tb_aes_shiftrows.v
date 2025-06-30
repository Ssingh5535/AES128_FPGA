`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2025 01:32:22 PM
// Design Name: 
// Module Name: tb_aes_shiftrows
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


`timescale 1ns/1ps
module tb_aes_shiftrows;
  reg  [127:0] state_in;
  wire [127:0] state_out;

  ShiftRows uut (
    .state_in(state_in),
    .state_out(state_out)
  );

  initial begin
    // Fill state_in with bytes 0..15:
    state_in = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    #1;
    $display("Input:  %h", state_in);
    $display("Output: %h", state_out);
    // Expected Output: 0005040C_01050D0E_02060A0F_0307090B
    $finish;
  end
endmodule