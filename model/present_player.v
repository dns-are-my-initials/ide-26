/*
 * PRESENT permutation layer (pLayer): moves bit i to position P(i).
 *
 * Python equivalent:   p_layer(state)
 *     P(i) = (16 * i) mod 63   for i = 0..62
 *     P(63) = 63
 *
 * This module contains no gates at all. Every line just connects one input
 * wire to one output wire.
 */

`default_nettype none

module present_player (
    input  wire [63:0] din,
    output wire [63:0] dout
);

    // A generate loop runs when the circuit is BUILT, not while it runs.
    // It stamps out 63 separate assign statements, one wire each.
    genvar i;
    generate
        for (i = 0; i < 63; i = i + 1) begin : g_perm
            // TODO: replace the ??? with the destination of bit i
            assign dout[ ??? ] = din[i];
        end
    endgenerate

    // Bit 63 is the exception: it stays where it is.
    assign dout[63] = din[63];

endmodule
