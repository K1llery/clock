`timescale 1ns / 1ps

module tb_clock;

    reg cp2;
    reg cp3;
    reg clr_n;
    reg qd;
    reg pulse;
    reg k0;
    reg k1;

    wire lg1_d0;
    wire lg1_d1;
    wire lg1_d2;
    wire lg1_d3;
    wire lg1_d4;
    wire lg1_d5;
    wire lg1_d6;
    wire lg1_d7;
    wire lg2_a;
    wire lg2_b;
    wire lg2_c;
    wire lg2_d;
    wire lg3_a;
    wire lg3_b;
    wire lg3_c;
    wire lg3_d;
    wire lg4_a;
    wire lg4_b;
    wire lg4_c;
    wire lg4_d;
    wire lg5_a;
    wire lg5_b;
    wire lg5_c;
    wire lg5_d;
    wire lg6_a;
    wire lg6_b;
    wire lg6_c;
    wire lg6_d;

    clock dut (
        .cp2(cp2),
        .cp3(cp3),
        .clr_n(clr_n),
        .qd(qd),
        .pulse(pulse),
        .k0(k0),
        .k1(k1),
        .lg1_d0(lg1_d0),
        .lg1_d1(lg1_d1),
        .lg1_d2(lg1_d2),
        .lg1_d3(lg1_d3),
        .lg1_d4(lg1_d4),
        .lg1_d5(lg1_d5),
        .lg1_d6(lg1_d6),
        .lg1_d7(lg1_d7),
        .lg2_a(lg2_a),
        .lg2_b(lg2_b),
        .lg2_c(lg2_c),
        .lg2_d(lg2_d),
        .lg3_a(lg3_a),
        .lg3_b(lg3_b),
        .lg3_c(lg3_c),
        .lg3_d(lg3_d),
        .lg4_a(lg4_a),
        .lg4_b(lg4_b),
        .lg4_c(lg4_c),
        .lg4_d(lg4_d),
        .lg5_a(lg5_a),
        .lg5_b(lg5_b),
        .lg5_c(lg5_c),
        .lg5_d(lg5_d),
        .lg6_a(lg6_a),
        .lg6_b(lg6_b),
        .lg6_c(lg6_c),
        .lg6_d(lg6_d)
    );

    always #5 cp2 = ~cp2;

    task cp3_tick;
        begin
            #9 cp3 = 1'b1;
            #12 cp3 = 1'b0;
            #9;
        end
    endtask

    task qd_pulse;
        begin
            #9 qd = 1'b1;
            #12 qd = 1'b0;
            #9;
        end
    endtask

    task pulse_btn;
        begin
            #9 pulse = 1'b1;
            #12 pulse = 1'b0;
            #9;
        end
    endtask

    task check_digits;
        input [23:0] expected;
        input [255:0] label;
        begin
            #12;
            if (dut.digits !== expected) begin
                $display("FAIL %0s expected=%h got=%h", label, expected, dut.digits);
                $finish;
            end
        end
    endtask

    task check_bcd_bus;
        input [3:0] expected;
        input actual_a;
        input actual_b;
        input actual_c;
        input actual_d;
        input [255:0] label;
        reg [3:0] actual;
        begin
            actual = {actual_d, actual_c, actual_b, actual_a};
            if (actual !== expected) begin
                $display("FAIL %0s expected=%0d got=%0d", label, expected, actual);
                $finish;
            end
        end
    endtask

    initial begin
        cp2 = 1'b0;
        cp3 = 1'b0;
        clr_n = 1'b1;
        qd = 1'b0;
        pulse = 1'b0;
        k0 = 1'b0;
        k1 = 1'b0;

        #2 clr_n = 1'b0;
        #8 clr_n = 1'b1;
        #20;

        check_digits(24'h000000, "reset");
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL run_enable should default to running");
            $finish;
        end

        cp3_tick;
        cp3_tick;
        cp3_tick;
        check_digits(24'h000003, "count three seconds");
        if (dut.lg1_segments !== 7'b1001111) begin
            $display("FAIL direct 7-seg decode for digit 3 is wrong");
            $finish;
        end
        check_bcd_bus(4'd0, lg2_a, lg2_b, lg2_c, lg2_d, "sec tens");

        qd_pulse;
        #12;
        if (dut.run_enable !== 1'b0) begin
            $display("FAIL qd should pause the clock");
            $finish;
        end

        cp3_tick;
        check_digits(24'h000003, "paused clock must ignore cp3");

        k1 = 1'b1;
        pulse_btn;
        check_digits(24'h000100, "minute adjust");
        check_bcd_bus(4'd1, lg3_a, lg3_b, lg3_c, lg3_d, "minute ones");
        k1 = 1'b0;

        k0 = 1'b1;
        pulse_btn;
        check_digits(24'h010100, "hour adjust");
        check_bcd_bus(4'd1, lg5_a, lg5_b, lg5_c, lg5_d, "hour ones");
        k0 = 1'b0;

        dut.digits = 24'h235958;
        qd_pulse;
        #12;
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL qd should resume the clock");
            $finish;
        end

        cp3_tick;
        check_digits(24'h235959, "rollover pre-state");
        cp3_tick;
        check_digits(24'h000000, "24-hour rollover");

        $display("PASS tb_clock");
        $finish;
    end

endmodule
