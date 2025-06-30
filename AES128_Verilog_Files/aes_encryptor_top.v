`timescale 1ns/1ps

//-----------------------------------------------------------------------------
// File: aes_encryptor_top.v
// Top-level AES-128 encryption module
// Combines key expansion, initial AddRoundKey, 9 rounds, and final round
//----------------------------------------------------------------------------- 
module aes_encryptor_top (
    input  wire         clk,
    input  wire         rst_n,        // active-low reset
    input  wire         start,        // pulse to begin encryption
    input  wire [127:0] key,          // AES-128 master key
    input  wire [127:0] plaintext,    // 128-bit input block
    output reg  [127:0] ciphertext,   // 128-bit output block
    output reg          valid         // pulses high when ciphertext is ready
);

    //----------------------------------------------------------------------------
    // Wires from key expansion
    //----------------------------------------------------------------------------
    wire         kexp_valid;
    wire  [3:0]  kexp_round;
    wire [127:0] kexp_round_key;

    //----------------------------------------------------------------------------
    // Instantiate AES key-expansion
    //----------------------------------------------------------------------------
    aes_key_expansion u_kexp (
        .clk      (clk),
        .rst_n    (rst_n),
        .start    (start),
        .key_in   (key),
        .valid    (kexp_valid),
        .round    (kexp_round),
        .round_key(kexp_round_key)
    );

    //----------------------------------------------------------------------------
    // Instantiate a single round and final-round module
    //----------------------------------------------------------------------------
    wire [127:0] round_out;
    wire [127:0] final_out;

    aes_round       u_round      (
        .state_in  (state_reg),
        .round_key (kexp_round_key),
        .state_out (round_out)
    );

    aes_final_round u_final_round(
        .state_in  (state_reg),
        .round_key (kexp_round_key),
        .state_out (final_out)
    );

    //----------------------------------------------------------------------------
    // Internal state and control
    //----------------------------------------------------------------------------
    reg [127:0] state_reg;
    reg         processing;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg  <= 128'd0;
            ciphertext <= 128'd0;
            valid      <= 1'b0;
            processing <= 1'b0;
        end else begin
            valid <= 1'b0;

            // Start encryption process
            if (start)
                processing <= 1'b1;

            // On each round-key valid pulse, update state
            if (processing && kexp_valid) begin
                case (kexp_round)
                    4'd0: begin
                        // Initial AddRoundKey
                        state_reg <= plaintext ^ kexp_round_key;
                    end

                    4'd1, 4'd2, 4'd3,
                    4'd4, 4'd5, 4'd6,
                    4'd7, 4'd8, 4'd9: begin
                        // Rounds 1-9
                        state_reg <= round_out;
                    end

                    4'd10: begin
                        // Final round
                        state_reg  <= final_out;
                        ciphertext <= final_out;
                        valid      <= 1'b1;
                        processing <= 1'b0;  // done
                    end

                    default: begin
                        // should not occur
                        state_reg <= state_reg;
                    end
                endcase
            end
        end
    end

endmodule
