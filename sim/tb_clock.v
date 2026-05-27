`timescale 1ns / 1ps

module tb_clock;

    reg cp2;
    reg cp3;
    reg k5;
    reg qd;
    reg pulse;
    reg k0;
    reg k1;
    reg k2;
    reg k3;
    reg k4;

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
    integer second_index;
    integer tone_sample_index;
    integer speaker_cycle_index;
    integer speaker_transition_count;
    reg [7:0] expected_seconds;
    reg [3:0] expected_sec_tens;
    reg [3:0] expected_sec_ones;
    reg saw_speaker_low;
    reg saw_speaker_high;
    reg previous_speaker_sample;

    clock dut (
        .cp2(cp2),
        .cp3(cp3),
        .k5(k5),
        .qd(qd),
        .pulse(pulse),
        .k0(k0),
        .k1(k1),
        .k2(k2),
        .k3(k3),
        .k4(k4),
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

    task k5_reset;
        begin
            k5 = ~k5;
            wait_cp2_cycles(5);
        end
    endtask

    task cp3_tick_to_alarm_match_with_pipeline_check;
        begin
            #9 cp3 = 1'b1;
            @(posedge cp2);
            @(posedge cp2);
            @(posedge cp2);
            #1;
            if (dut.digits !== 24'h010201) begin
                $display("FAIL alarm match pipeline expected time 01:02:01 got=%h", dut.digits);
                $finish;
            end
            if (dut.alarm_check_pending !== 1'b1) begin
                $display("FAIL alarm match should register a pending alarm check");
                $finish;
            end
            if (dut.alarm_active !== 1'b0) begin
                $display("FAIL alarm should wait one CP2 cycle after the matching second");
                $finish;
            end

            @(posedge cp2);
            #1;
            if (dut.alarm_check_pending !== 1'b0) begin
                $display("FAIL pending alarm check should clear after evaluation");
                $finish;
            end
            if (dut.alarm_active !== 1'b1) begin
                $display("FAIL pending alarm check should start the alarm");
                $finish;
            end

            #2 cp3 = 1'b0;
            @(posedge cp2);
            @(posedge cp2);
            @(posedge cp2);
            #1;
        end
    endtask

    task wait_sync;
        begin
            #30;
        end
    endtask

    task sample_speaker_output;
        input integer sample_count;
        begin
            saw_speaker_low = 1'b0;
            saw_speaker_high = 1'b0;
            speaker_transition_count = 0;
            previous_speaker_sample = lg1_d7;
            for (tone_sample_index = 0; tone_sample_index < sample_count; tone_sample_index = tone_sample_index + 1) begin
                #2;
                if (lg1_d7 !== previous_speaker_sample) begin
                    speaker_transition_count = speaker_transition_count + 1;
                end
                previous_speaker_sample = lg1_d7;
                if (lg1_d7 === 1'b0) begin
                    saw_speaker_low = 1'b1;
                end else if (lg1_d7 === 1'b1) begin
                    saw_speaker_high = 1'b1;
                end
            end
        end
    endtask

    task sample_speaker_for_cp2_cycles;
        input integer cycle_count;
        begin
            saw_speaker_low = 1'b0;
            saw_speaker_high = 1'b0;
            speaker_transition_count = 0;
            previous_speaker_sample = lg1_d7;
            for (speaker_cycle_index = 0; speaker_cycle_index < cycle_count; speaker_cycle_index = speaker_cycle_index + 1) begin
                @(posedge cp2);
                #1;
                if (lg1_d7 !== previous_speaker_sample) begin
                    speaker_transition_count = speaker_transition_count + 1;
                end
                previous_speaker_sample = lg1_d7;
                if (lg1_d7 === 1'b0) begin
                    saw_speaker_low = 1'b1;
                end else if (lg1_d7 === 1'b1) begin
                    saw_speaker_high = 1'b1;
                end
            end
        end
    endtask

    task wait_cp2_cycles;
        input integer cycle_count;
        begin
            for (speaker_cycle_index = 0; speaker_cycle_index < cycle_count; speaker_cycle_index = speaker_cycle_index + 1) begin
                @(posedge cp2);
                #1;
            end
        end
    endtask

    task check_digits;
        input [23:0] expected;
        input [255:0] label;
        begin
            wait_sync;
            if (dut.digits !== expected) begin
                $display("FAIL %0s expected=%h got=%h run=%b alarm_en=%b alarm_active=%b cp3_sync=%b",
                    label, expected, dut.digits, dut.run_enable, dut.alarm_enable, dut.alarm_active, dut.cp3_sync);
                $finish;
            end
        end
    endtask

    task check_alarm_digits;
        input [23:0] expected;
        input [255:0] label;
        begin
            wait_sync;
            if (dut.alarm_digits !== expected) begin
                $display("FAIL %0s expected=%h got=%h", label, expected, dut.alarm_digits);
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

    function [6:0] expected_seg7;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: expected_seg7 = 7'b0111111;
                4'd1: expected_seg7 = 7'b0000110;
                4'd2: expected_seg7 = 7'b1011011;
                4'd3: expected_seg7 = 7'b1001111;
                4'd4: expected_seg7 = 7'b1100110;
                4'd5: expected_seg7 = 7'b1101101;
                4'd6: expected_seg7 = 7'b1111101;
                4'd7: expected_seg7 = 7'b0000111;
                4'd8: expected_seg7 = 7'b1111111;
                4'd9: expected_seg7 = 7'b1101111;
                default: expected_seg7 = 7'b0000000;
            endcase
        end
    endfunction

    task check_visible_seconds;
        input [3:0] expected_tens;
        input [3:0] expected_ones;
        input [255:0] label;
        begin
            check_bcd_bus(expected_tens, lg2_a, lg2_b, lg2_c, lg2_d, label);
            if (dut.lg1_segments !== expected_seg7(expected_ones)) begin
                $display("FAIL %0s sec ones expected=%0d segments=%b got=%b",
                    label, expected_ones, expected_seg7(expected_ones), dut.lg1_segments);
                $finish;
            end
        end
    endtask

    task check_blink_bcd_lg;
        input [3:0] expected_val;
        input [2:0] lg_sel;
        input should_blink;
        input [255:0] label;
        reg [3:0] val;
        reg saw_normal;
        reg saw_blank;
        integer i;
        begin
            saw_normal = 1'b0;
            saw_blank = 1'b0;
            for (i = 0; i < 64; i = i + 1) begin
                @(posedge cp2);
                #1;
                case (lg_sel)
                    3'd0: val = {lg2_d, lg2_c, lg2_b, lg2_a};
                    3'd1: val = {lg3_d, lg3_c, lg3_b, lg3_a};
                    3'd2: val = {lg4_d, lg4_c, lg4_b, lg4_a};
                    3'd3: val = {lg5_d, lg5_c, lg5_b, lg5_a};
                    3'd4: val = {lg6_d, lg6_c, lg6_b, lg6_a};
                    default: val = 4'h0;
                endcase
                if (val == expected_val) saw_normal = 1'b1;
                if (val == 4'hF) saw_blank = 1'b1;
            end
            if (should_blink && (!saw_normal || !saw_blank)) begin
                cp3_tick;
                wait_sync;
                for (i = 0; i < 64; i = i + 1) begin
                    @(posedge cp2);
                    #1;
                    case (lg_sel)
                        3'd0: val = {lg2_d, lg2_c, lg2_b, lg2_a};
                        3'd1: val = {lg3_d, lg3_c, lg3_b, lg3_a};
                        3'd2: val = {lg4_d, lg4_c, lg4_b, lg4_a};
                        3'd3: val = {lg5_d, lg5_c, lg5_b, lg5_a};
                        3'd4: val = {lg6_d, lg6_c, lg6_b, lg6_a};
                        default: val = 4'h0;
                    endcase
                    if (val == expected_val) saw_normal = 1'b1;
                    if (val == 4'hF) saw_blank = 1'b1;
                end
            end
            if (should_blink) begin
                if (!saw_normal || !saw_blank) begin
                    $display("FAIL %0s should blink expected=%0d saw_normal=%b saw_blank=%b",
                        label, expected_val, saw_normal, saw_blank);
                    $finish;
                end
            end else begin
                if (saw_blank || !saw_normal) begin
                    $display("FAIL %0s should not blink saw_normal=%b saw_blank=%b",
                        label, saw_normal, saw_blank);
                    $finish;
                end
            end
        end
    endtask

    task check_blink_lg1;
        input [6:0] expected_seg;
        input should_blink;
        input [255:0] label;
        reg [6:0] segs;
        reg saw_normal;
        reg saw_blank;
        integer i;
        begin
            saw_normal = 1'b0;
            saw_blank = 1'b0;
            for (i = 0; i < 64; i = i + 1) begin
                @(posedge cp2);
                #1;
                segs = {lg1_d6, lg1_d5, lg1_d4, lg1_d3, lg1_d2, lg1_d1, lg1_d0};
                if (segs == expected_seg) saw_normal = 1'b1;
                if (segs == 7'b0000000) saw_blank = 1'b1;
            end
            if (should_blink && (!saw_normal || !saw_blank)) begin
                cp3_tick;
                wait_sync;
                for (i = 0; i < 64; i = i + 1) begin
                    @(posedge cp2);
                    #1;
                    segs = {lg1_d6, lg1_d5, lg1_d4, lg1_d3, lg1_d2, lg1_d1, lg1_d0};
                    if (segs == expected_seg) saw_normal = 1'b1;
                    if (segs == 7'b0000000) saw_blank = 1'b1;
                end
            end
            if (should_blink) begin
                if (!saw_normal || !saw_blank) begin
                    $display("FAIL %0s should blink expected_seg=%b saw_normal=%b saw_blank=%b",
                        label, expected_seg, saw_normal, saw_blank);
                    $finish;
                end
            end else begin
                if (saw_blank || !saw_normal) begin
                    $display("FAIL %0s should not blink saw_normal=%b saw_blank=%b",
                        label, saw_normal, saw_blank);
                    $finish;
                end
            end
        end
    endtask

    initial begin
        cp2 = 1'b0;
        cp3 = 1'b0;
        k5 = 1'b0;
        qd = 1'b0;
        pulse = 1'b0;
        k0 = 1'b0;
        k1 = 1'b0;
        k2 = 1'b0;
        k3 = 1'b0;
        k4 = 1'b0;

        wait_sync;
        k5_reset;

        check_digits(24'h000000, "k5 rising change reset");
        check_alarm_digits(16'h0000, "alarm reset");
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL run_enable should default to running");
            $finish;
        end
        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL alarm_active should default low");
            $finish;
        end

        for (second_index = 1; second_index < 60; second_index = second_index + 1) begin
            cp3_tick;
            expected_sec_tens = second_index / 10;
            expected_sec_ones = second_index % 10;
            expected_seconds = {expected_sec_tens, expected_sec_ones};
            check_digits({16'h0000, expected_seconds}, "continuous seconds 00-59");
            if ((second_index == 39) || (second_index == 40) || (second_index == 41) ||
                    (second_index == 50) || (second_index == 59)) begin
                check_visible_seconds(expected_sec_tens, expected_sec_ones, "visible seconds on LG2/LG1");
            end
        end
        cp3_tick;
        check_digits(24'h000100, "seconds roll to next minute after 59");
        check_visible_seconds(4'd0, 4'd0, "visible seconds reset only after 59");

        k5_reset;
        wait_sync;

        check_digits(24'h000000, "k5 falling change reset");
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL K5 falling reset should restore running state");
            $finish;
        end

        cp3_tick;
        cp3_tick;
        cp3_tick;
        check_digits(24'h000003, "count three seconds with alarm disabled");
        check_visible_seconds(4'd0, 4'd3, "count three visible seconds");

        qd_pulse;
        wait_sync;
        if (dut.run_enable !== 1'b0) begin
            $display("FAIL qd should pause the clock");
            $finish;
        end

        qd = 1'b1;
        wait_cp2_cycles(10);
        qd = 1'b0;
        wait_sync;
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL held qd should toggle run state only once");
            $finish;
        end

        qd_pulse;
        wait_sync;
        if (dut.run_enable !== 1'b0) begin
            $display("FAIL second qd pulse should pause the clock again");
            $finish;
        end

        cp3_tick;
        check_digits(24'h000003, "paused clock must ignore cp3");

        pulse = 1'b1;
        wait_cp2_cycles(10);
        pulse = 1'b0;
        wait_sync;
        check_digits(24'h000004, "held pulse should adjust once");
        check_visible_seconds(4'd0, 4'd4, "second adjust visible seconds");

        check_blink_lg1(expected_seg7(4'd4), 1'b1, "sec adjust lg1 blink");
        check_blink_bcd_lg(4'd0, 3'd0, 1'b1, "sec adjust lg2 blink");
        check_blink_bcd_lg(4'd0, 3'd1, 1'b0, "sec adjust lg3 no blink");
        check_blink_bcd_lg(4'd0, 3'd2, 1'b0, "sec adjust lg4 no blink");
        check_blink_bcd_lg(4'd0, 3'd3, 1'b0, "sec adjust lg5 no blink");
        check_blink_bcd_lg(4'd0, 3'd4, 1'b0, "sec adjust lg6 no blink");

        k1 = 1'b1;
        pulse_btn;
        check_digits(24'h000104, "minute adjust preserves seconds");
        check_bcd_bus(4'd1, lg3_a, lg3_b, lg3_c, lg3_d, "minute ones");
        check_visible_seconds(4'd0, 4'd4, "minute adjust keeps visible seconds");

        check_blink_lg1(expected_seg7(4'd4), 1'b0, "min adjust lg1 no blink");
        check_blink_bcd_lg(4'd0, 3'd0, 1'b0, "min adjust lg2 no blink");
        check_blink_bcd_lg(4'd1, 3'd1, 1'b1, "min adjust lg3 blink");
        check_blink_bcd_lg(4'd0, 3'd2, 1'b1, "min adjust lg4 blink");
        check_blink_bcd_lg(4'd0, 3'd3, 1'b0, "min adjust lg5 no blink");
        check_blink_bcd_lg(4'd0, 3'd4, 1'b0, "min adjust lg6 no blink");

        k1 = 1'b0;

        k0 = 1'b1;
        pulse_btn;
        check_digits(24'h010104, "hour adjust");
        check_bcd_bus(4'd1, lg5_a, lg5_b, lg5_c, lg5_d, "hour ones");

        check_blink_lg1(expected_seg7(4'd4), 1'b0, "hour adjust lg1 no blink");
        check_blink_bcd_lg(4'd0, 3'd0, 1'b0, "hour adjust lg2 no blink");
        check_blink_bcd_lg(4'd1, 3'd1, 1'b0, "hour adjust lg3 no blink");
        check_blink_bcd_lg(4'd0, 3'd2, 1'b0, "hour adjust lg4 no blink");
        check_blink_bcd_lg(4'd1, 3'd3, 1'b1, "hour adjust lg5 blink");
        check_blink_bcd_lg(4'd0, 3'd4, 1'b1, "hour adjust lg6 blink");

        k1 = 1'b1;
        pulse_btn;
        check_digits(24'h020104, "k0 k1 hour priority");
        check_blink_bcd_lg(4'd2, 3'd3, 1'b1, "k0 k1 lg5 blink");
        check_blink_bcd_lg(4'd0, 3'd4, 1'b1, "k0 k1 lg6 blink");
        check_blink_bcd_lg(4'd1, 3'd1, 1'b0, "k0 k1 min no blink");

        k0 = 1'b0;
        k1 = 1'b0;
        dut.digits = 24'h000059;
        wait_sync;
        pulse_btn;
        check_digits(24'h000100, "manual second carry");

        k1 = 1'b1;
        dut.digits = 24'h005904;
        wait_sync;
        pulse_btn;
        check_digits(24'h010004, "manual minute carry");

        k1 = 1'b0;
        k0 = 1'b1;
        dut.digits = 24'h230104;
        wait_sync;
        pulse_btn;
        check_digits(24'h000104, "manual hour rollover");

        k0 = 1'b0;
        dut.digits = 24'h010104;
        wait_sync;

        k2 = 1'b1;
        wait_sync;
        check_bcd_bus(4'd0, lg6_a, lg6_b, lg6_c, lg6_d, "alarm hour tens display");
        check_bcd_bus(4'd0, lg5_a, lg5_b, lg5_c, lg5_d, "alarm hour ones display");

        k0 = 1'b1;
        pulse_btn;
        k0 = 1'b0;
        k1 = 1'b1;
        pulse_btn;
        pulse_btn;
        k1 = 1'b0;
        pulse_btn;
        check_alarm_digits(24'h010201, "alarm setting");
        check_bcd_bus(4'd1, lg5_a, lg5_b, lg5_c, lg5_d, "alarm display hour ones");
        check_bcd_bus(4'd2, lg3_a, lg3_b, lg3_c, lg3_d, "alarm display minute ones");
        check_visible_seconds(4'd0, 4'd1, "alarm display second adjust");

        check_blink_lg1(expected_seg7(4'd1), 1'b1, "alarm mode sec adjust lg1 blink");
        check_blink_bcd_lg(4'd0, 3'd0, 1'b1, "alarm mode sec adjust lg2 blink");
        check_blink_bcd_lg(4'd1, 3'd3, 1'b0, "alarm mode sec adjust lg5 no blink");

        dut.alarm_digits = 24'h000059;
        wait_sync;
        pulse_btn;
        check_alarm_digits(24'h000100, "alarm manual second carry");

        k1 = 1'b1;
        dut.alarm_digits = 24'h005901;
        wait_sync;
        pulse_btn;
        check_alarm_digits(24'h010001, "alarm manual minute carry");

        k1 = 1'b0;
        k0 = 1'b1;
        dut.alarm_digits = 24'h230001;
        wait_sync;
        pulse_btn;
        check_alarm_digits(24'h000001, "alarm manual hour rollover");

        k0 = 1'b0;
        dut.alarm_digits = 24'h010201;
        wait_sync;

        qd_pulse;
        wait_sync;
        if (dut.run_enable !== 1'b0) begin
            $display("FAIL qd must be ignored while K2 selects alarm setting");
            $finish;
        end
        cp3_tick;
        check_digits(24'h010104, "alarm setting must preserve paused time");

        k2 = 1'b0;
        wait_sync;
        dut.digits = 24'h010158;
        wait_sync;
        qd_pulse;
        wait_sync;
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL qd should resume the clock");
            $finish;
        end

        cp3_tick;
        check_digits(24'h010159, "alarm disabled pre-trigger second");
        cp3_tick;
        check_digits(24'h010200, "alarm disabled matching time");
        wait_sync;
        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL K3 low should keep alarm inactive at the matching time");
            $finish;
        end
        sample_speaker_output(80);
        if (speaker_transition_count !== 0) begin
            $display("FAIL K3 low should keep speaker silent transitions=%0d", speaker_transition_count);
            $finish;
        end

        k3 = 1'b1;
        wait_sync;
        dut.digits = 24'h010158;
        wait_sync;

        cp3_tick;
        check_digits(24'h010159, "alarm pre-trigger second");
        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL alarm should not trigger early");
            $finish;
        end

        cp3_tick;
        check_digits(24'h010200, "alarm should wait for adjusted second");
        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL alarm should not trigger before adjusted second");
            $finish;
        end

        cp3_tick_to_alarm_match_with_pipeline_check;
        check_digits(24'h010201, "alarm trigger time");
        wait_sync;
        if (dut.alarm_active !== 1'b1) begin
            $display("FAIL alarm should trigger at HH:MM:SS");
            $finish;
        end

        cp3_tick;
        check_digits(24'h010202, "clock must keep running while alarm sounds");
        if (dut.alarm_active !== 1'b1) begin
            $display("FAIL alarm should remain active while time keeps advancing");
            $finish;
        end

        sample_speaker_for_cp2_cycles(60);
        if (!saw_speaker_low || !saw_speaker_high) begin
            $display("FAIL speaker output should start with a short CP2-derived beep while alarm is active");
            $finish;
        end
        if ((speaker_transition_count < 45) || (speaker_transition_count > 65)) begin
            $display("FAIL speaker beep should use a CP2-derived audible tone near CP2/2 transitions=%0d",
                speaker_transition_count);
            $finish;
        end

        wait_cp2_cycles(90);
        sample_speaker_for_cp2_cycles(60);
        if (dut.alarm_active !== 1'b1) begin
            $display("FAIL silent gap should not clear alarm_active");
            $finish;
        end
        if (speaker_transition_count !== 0) begin
            $display("FAIL speaker should be silent between one-second alarm beeps transitions=%0d",
                speaker_transition_count);
            $finish;
        end
        if (lg1_d7 !== 1'b0) begin
            $display("FAIL speaker output should rest low between alarm beeps");
            $finish;
        end

        cp3_tick;
        check_digits(24'h010203, "next second while alarm sounds");
        sample_speaker_for_cp2_cycles(60);
        if (!saw_speaker_low || !saw_speaker_high) begin
            $display("FAIL next CP3 second should start the next alarm beep");
            $finish;
        end
        if ((speaker_transition_count < 45) || (speaker_transition_count > 65)) begin
            $display("FAIL repeated beep should use the same CP2-derived audible tone transitions=%0d",
                speaker_transition_count);
            $finish;
        end
        wait_sync;

        qd_pulse;
        wait_sync;
        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL qd should dismiss the alarm");
            $finish;
        end
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL qd dismiss should not pause the running clock");
            $finish;
        end

        dut.digits = 24'h010200;
        wait_sync;
        cp3_tick;
        wait_sync;
        if (dut.alarm_active !== 1'b1) begin
            $display("FAIL alarm should retrigger on next matching time");
            $finish;
        end

        k3 = 1'b0;
        wait_sync;
        if (dut.alarm_active !== 1'b0) begin
            $display("FAIL disabling alarm should stop the speaker");
            $finish;
        end
        if (dut.run_enable !== 1'b1) begin
            $display("FAIL disabling alarm must not change run state");
            $finish;
        end

        cp3_tick;
        check_digits(24'h010202, "clock must keep running with alarm disabled");

        k4 = 1'b0;
        wait_sync;
        dut.digits = 24'h015958;
        wait_sync;
        cp3_tick;
        check_digits(24'h015959, "hourly chime disabled pre-state");
        cp3_tick;
        check_digits(24'h020000, "hourly chime disabled exact hour");
        sample_speaker_for_cp2_cycles(60);
        if (speaker_transition_count !== 0) begin
            $display("FAIL K4 low should keep hourly chime silent transitions=%0d",
                speaker_transition_count);
            $finish;
        end
        k4 = 1'b1;
        wait_sync;
        sample_speaker_for_cp2_cycles(20);
        if (speaker_transition_count !== 0) begin
            $display("FAIL enabling K4 after the hour should not backfill a chime transitions=%0d",
                speaker_transition_count);
            $finish;
        end

        dut.digits = 24'h025958;
        wait_sync;
        cp3_tick;
        check_digits(24'h025959, "hourly chime pre-state");
        sample_speaker_for_cp2_cycles(60);
        if (speaker_transition_count !== 0) begin
            $display("FAIL hourly chime should stay silent before the exact hour transitions=%0d",
                speaker_transition_count);
            $finish;
        end

        cp3_tick;
        check_digits(24'h030000, "hourly chime trigger time");
        sample_speaker_for_cp2_cycles(60);
        if (!saw_speaker_low || !saw_speaker_high) begin
            $display("FAIL hourly chime should start a short CP2-derived beep at HH:00:00");
            $finish;
        end
        if ((speaker_transition_count < 45) || (speaker_transition_count > 65)) begin
            $display("FAIL hourly chime should use the CP2-derived audible tone transitions=%0d",
                speaker_transition_count);
            $finish;
        end
        wait_cp2_cycles(90);
        if (lg1_d7 !== 1'b0) begin
            $display("FAIL hourly chime should rest low after the short beep");
            $finish;
        end

        dut.digits = 24'h235958;
        wait_sync;
        cp3_tick;
        check_digits(24'h235959, "rollover pre-state");
        cp3_tick;
        check_digits(24'h000000, "24-hour rollover");

        $display("PASS tb_clock");
        $finish;
    end

endmodule
