`timescale 1ns/1ps
module tb_aes_inv_shiftrows;

  // DUT I/O
  reg  [127:0] state_in;
  wire [127:0] state_out;

  // Expected inverse-ShiftRows result for
  // state_in = 00 11 22 33 | 44 55 66 77 | 88 99 AA BB | CC DD EE FF
  // (bytes printed MSB→LSB)
  // After InvShiftRows: 
  // 00 DD AA 77 | 44 11 EE BB | 88 55 22 FF | CC 99 66 33
  localparam [127:0] GOLD = 128'h00DD_AA77_4411_EEBB_8855_22FF_CC99_6633;

  // instantiate the InvShiftRows module
  aes_inv_shiftrows dut (
    .state_in  (state_in),
    .state_out (state_out)
  );

  initial begin
    // apply the test vector
    state_in = 128'h0011_2233_4455_6677_8899_AABB_CCDD_EEFF;
    #1;  // allow combinational logic to settle

    // compare to the golden result
    if (state_out === GOLD) begin
      $display("PASS inv_shiftrows: %h", state_out);
    end else begin
      $display("FAIL inv_shiftrows: got %h, expected %h", state_out, GOLD);
    end

    $finish;
  end

endmodule
