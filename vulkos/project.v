// Vulkos project file: paste this whole file into src/project.v.
// It is hw/present_sbox.v followed by hw/tt_um_present_sbox.v.

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
            4'h2: dout = 4'h6;
            4'h3: dout = 4'hB;
            4'h4: dout = 4'h9;
            4'h5: dout = 4'h0;
            4'h6: dout = 4'hA;
            4'h7: dout = 4'hD;
            4'h8: dout = 4'h3;
            4'h9: dout = 4'hE;
            4'hA: dout = 4'hF;
            4'hB: dout = 4'h8;
            4'hC: dout = 4'h4;
            4'hD: dout = 4'h7;
            4'hE: dout = 4'h1;
            4'hF: dout = 4'h2;
            default: dout = 4'h0;  // never reached: all 16 inputs are listed above
        endcase
    end

endmodule

/*
 * Tiny Tapeout wrapper for one PRESENT S-box, so it can go through the full
 * flow on its own and give a first real area number.
 *
 *   ui_in[3:0]   nibble in
 *   uo_out[3:0]  S(nibble) out
 *
 * Needs present_sbox.v in the same project (or pasted into the same file).
 */


module tt_um_present_sbox (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n     // reset, active low (0 = reset)
);

    wire [3:0] sbox_out;

    // One instance = one physical copy of the S-box circuit on the chip.
    present_sbox u_sbox (
        .din (ui_in[3:0]),
        .dout(sbox_out)
    );

    assign uo_out  = {4'b0000, sbox_out};
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;
    wire _unused_ok = &{ena, clk, rst_n, ui_in[7:4], uio_in, 1'b0};

endmodule