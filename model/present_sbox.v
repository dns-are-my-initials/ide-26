/*
 * PRESENT S-box: one 4-bit lookup, built as combinational logic.
 *
 * Python equivalent:   out = SBOX[in]
 *
 * There is no clock here. The output always equals S(input); when the input
 * changes, the output follows a few gate delays later.
 */

`default_nettype none

module present_sbox (
    input  wire [3:0] din,   // one nibble in
    output reg  [3:0] dout   // the substituted nibble out
);
    // "reg" here does NOT mean a flip-flop. In Verilog, any signal assigned
    // inside an always block must be declared reg. Because this block is
    // always @(*) (combinational), the tools build plain logic gates.

    always @(*) begin
        case (din)
            4'h0: dout = 4'hC;
            4'h1: dout = 4'h5;
            // TODO: fill in 4'h2 to 4'hF from the S-box table
            //       (paper, Section 3, or SBOX in model/present.py)

            default: dout = 4'h0;  // never reached once all 16 cases are listed
        endcase
    end

endmodule
