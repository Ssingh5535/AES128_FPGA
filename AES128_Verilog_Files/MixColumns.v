`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/02/2025 12:07:04 AM
// Design Name: 
// Module Name: MixColumns
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


module MixColumns(
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);
    // xtime = multiply by 2 in GF(2^8)
    function [7:0] xtime;
        input [7:0] b;
        xtime = (b << 1) ^ (b[7] ? 8'h1B : 8'h00);
    endfunction

    // helpers
    function [7:0] mul2; input [7:0] b; mul2 = xtime(b);                endfunction
    function [7:0] mul3; input [7:0] b; mul3 = xtime(b) ^ b;            endfunction

    // break state into bytes b0…b15
    wire [7:0] b0  = state_in[127:120], b1  = state_in[119:112],
               b2  = state_in[111:104], b3  = state_in[103:96],
               b4  = state_in[95:88],   b5  = state_in[87:80],
               b6  = state_in[79:72],   b7  = state_in[71:64],
               b8  = state_in[63:56],   b9  = state_in[55:48],
               b10 = state_in[47:40],   b11 = state_in[39:32],
               b12 = state_in[31:24],   b13 = state_in[23:16],
               b14 = state_in[15:8],    b15 = state_in[7:0];

    // column 0
    wire [7:0] r0 = mul2(b0) ^ mul3(b1) ^ b2       ^ b3;
    wire [7:0] r1 = b0       ^ mul2(b1) ^ mul3(b2) ^ b3;
    wire [7:0] r2 = b0       ^ b1       ^ mul2(b2) ^ mul3(b3);
    wire [7:0] r3 = mul3(b0) ^ b1       ^ b2       ^ mul2(b3);
    // column 1
    wire [7:0] r4 = mul2(b4) ^ mul3(b5) ^ b6       ^ b7;
    wire [7:0] r5 = b4       ^ mul2(b5) ^ mul3(b6) ^ b7;
    wire [7:0] r6 = b4       ^ b5       ^ mul2(b6) ^ mul3(b7);
    wire [7:0] r7 = mul3(b4) ^ b5       ^ b6       ^ mul2(b7);
    // column 2
    wire [7:0] r8  = mul2(b8)  ^ mul3(b9)  ^ b10      ^ b11;
    wire [7:0] r9  = b8        ^ mul2(b9)  ^ mul3(b10) ^ b11;
    wire [7:0] r10 = b8        ^ b9        ^ mul2(b10) ^ mul3(b11);
    wire [7:0] r11 = mul3(b8)  ^ b9        ^ b10      ^ mul2(b11);
    // column 3
    wire [7:0] r12 = mul2(b12) ^ mul3(b13) ^ b14      ^ b15;
    wire [7:0] r13 = b12       ^ mul2(b13) ^ mul3(b14) ^ b15;
    wire [7:0] r14 = b12       ^ b13       ^ mul2(b14) ^ mul3(b15);
    wire [7:0] r15 = mul3(b12) ^ b13       ^ b14       ^ mul2(b15);

    assign state_out = {
        r0,  r1,  r2,  r3,
        r4,  r5,  r6,  r7,
        r8,  r9,  r10, r11,
        r12, r13, r14, r15
    };
endmodule