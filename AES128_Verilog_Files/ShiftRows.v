`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2025 11:28:46 PM
// Design Name: 
// Module Name: InvShiftRows
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


module ShiftRows(
    input wire [127:0] state_in,
    output wire [127:0] state_out
    );
        // build each column (4 bytes) after shifting:
    // col 0: {b0, b5,  b10, b15}
    // col 1: {b4, b9,  b14, b3 }
    // col 2: {b8, b13, b2,  b7 }
    // col 3: {b12,b1,  b6,  b11}
    assign state_out = {
      // col 0
      state_in[127:120],
      state_in[87:80],
      state_in[47:40],
      state_in[7:0],
      // col 1
      state_in[95:88],
      state_in[55:48],
      state_in[15:8],
      state_in[103:96],
      // col 2
      state_in[63:56],
      state_in[23:16],
      state_in[111:104],
      state_in[71:64],
      // col 3
      state_in[31:24],
      state_in[119:112],
      state_in[79:72],
      state_in[39:32]
    };
endmodule
