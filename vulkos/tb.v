/*
 * Vulkos testbench for tt_um_present_sbox: paste this whole file into tb/tb.v.
 *
 * Tests the S-box through the real chip pins, as the fabricated chip would be
 * used: nibble on ui_in[3:0], result on uo_out[3:0].
 * Exhaustive: all 16 nibbles, each with all 16 values on the unused pins
 * ui_in[7:4] (256 combinations), plus a check that the bidirectional pins
 * are inputs and driven to 0.
 */

`default_nettype none

module tb;

    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    reg  [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena;
    reg        clk;
    reg        rst_n;

    reg  [3:0] expected [0:15];
    reg  [4:0] nib;      // 5 bits so the loop can count up to 16 and stop
    reg  [4:0] upper;
    integer    errors;

    tt_um_present_sbox dut (
        .ui_in  (ui_in),
        .uo_out (uo_out),
        .uio_in (uio_in),
        .uio_out(uio_out),
        .uio_oe (uio_oe),
        .ena    (ena),
        .clk    (clk),
        .rst_n  (rst_n)
    );

    initial begin
        $dumpfile("waves/present_sbox.vcd");
        $dumpvars(0, tb);

        expected[ 0] = 4'hC; expected[ 1] = 4'h5; expected[ 2] = 4'h6; expected[ 3] = 4'hB;
        expected[ 4] = 4'h9; expected[ 5] = 4'h0; expected[ 6] = 4'hA; expected[ 7] = 4'hD;
        expected[ 8] = 4'h3; expected[ 9] = 4'hE; expected[10] = 4'hF; expected[11] = 4'h8;
        expected[12] = 4'h4; expected[13] = 4'h7; expected[14] = 4'h1; expected[15] = 4'h2;

        // Fixed values for the pins this design does not use.
        uio_in = 8'h00;
        ena    = 1'b1;
        clk    = 1'b0;
        rst_n  = 1'b1;
        errors = 0;

        for (upper = 5'd0; upper < 5'd16; upper = upper + 5'd1) begin
            for (nib = 5'd0; nib < 5'd16; nib = nib + 5'd1) begin
                ui_in = {upper[3:0], nib[3:0]};
                #1;
                if (uo_out !== {4'b0000, expected[nib[3:0]]}) begin
                    $display("FAIL  ui_in=%h  uo_out=%h  expected=%h",
                             ui_in, uo_out, {4'b0000, expected[nib[3:0]]});
                    errors = errors + 1;
                end
            end
        end

        if (uio_oe !== 8'h00 || uio_out !== 8'h00) begin
            $display("FAIL  uio_oe=%h uio_out=%h, both should be 00", uio_oe, uio_out);
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS  tt_um_present_sbox: all 256 pin combinations correct");
            $display("VULKOS_RESULT: PASS");
            $finish;
        end else begin
            $display("FAIL  tt_um_present_sbox: %0d errors", errors);
            $display("VULKOS_RESULT: FAIL");
            $fatal(1, "S-box test failed");
        end
    end

endmodule