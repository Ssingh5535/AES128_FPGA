`timescale 1ns/1ps
module tb_aes_mixcolumns;
  reg  [127:0] state_in;
  wire [127:0] state_out;

  // Instantiate your MixColumns
  MixColumns uut (
    .state_in (state_in),
    .state_out(state_out)
  );

  initial begin
    // Drive test vector
    state_in = 128'hD4BF5D30_E0B452AE_B84111F1_1E2798E5;
    #1;  // allow combinational logic to settle

    // Display and check
    $display("IN  = %h", state_in);
    $display("OUT = %h", state_out);
    if (state_out === 128'h046681E5_E0CB199A_48F8D37A_2806264C) 
      $display("PASS MixColumns");
    else
      $display("FAIL MixColumns: got %h", state_out);

    $finish;
  end
endmodule
