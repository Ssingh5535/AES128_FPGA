`timescale 1ns/1ps
module tb_aes_inv_mixcolumns;

  // DUT I/O
  reg  [127:0] state_in;
  wire [127:0] state_out;

  // From FIPS-197 Appendix C:
  // MixColumns maps [D4 BF 5D 30] → [04 66 81 E5].
  // Therefore InvMixColumns should map [04 66 81 E5] back to [D4 BF 5D 30].
  // We repeat that pattern in all 4 columns for a 128-bit test.
  localparam [127:0] GOLD = 128'hD4BF_5D30_D4BF_5D30_D4BF_5D30_D4BF_5D30;

  // Instantiate the module under test
  aes_inv_mixcolumns dut (
    .state_in  (state_in),
    .state_out (state_out)
  );

  initial begin
    // Apply the test vector: four repeats of 04 66 81 E5
    state_in = {4{32'h0466_81E5}};
    #1;  // allow combinational logic to settle

    // Check against the golden result
    if (state_out === GOLD) begin
      $display("PASS inv_mixcolumns: %h", state_out);
    end else begin
      $display("FAIL inv_mixcolumns: got %h, expected %h", state_out, GOLD);
    end

    $finish;
  end

endmodule
