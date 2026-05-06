`timescale 1ns / 1ps

module clock(
    input  wire cp1,
    input  wire cp2,
    input  wire cp3,
    input  wire clr_n,
    input  wire qd,
    input  wire pulse,
    input  wire k0,
    input  wire k1,
    input  wire k2,
    input  wire k3,
    output wire lg1_d0,
    output wire lg1_d1,
    output wire lg1_d2,
    output wire lg1_d3,
    output wire lg1_d4,
    output wire lg1_d5,
    output wire lg1_d6,
    output wire lg1_d7,
    output wire lg2_a,
    output wire lg2_b,
    output wire lg2_c,
    output wire lg2_d,
    output wire lg3_a,
    output wire lg3_b,
    output wire lg3_c,
    output wire lg3_d,
    output wire lg4_a,
    output wire lg4_b,
    output wire lg4_c,
    output wire lg4_d,
    output wire lg5_a,
    output wire lg5_b,
    output wire lg5_c,
    output wire lg5_d,
    output wire lg6_a,
    output wire lg6_b,
    output wire lg6_c,
    output wire lg6_d
);

    reg        run_enable;
    reg        alarm_active;
    reg        alarm_check_pending;
    reg [6:0]  alarm_tone_divider;
    reg [1:0]  alarm_active_cp1_sync;
    reg [23:0] digits;
    reg [23:0] digits_next_tick;
    reg [15:0] alarm_digits;

    reg [2:0] cp3_sync;
    reg [2:0] qd_sync;
    reg [2:0] pulse_sync;
    reg [1:0] k0_sync;
    reg [1:0] k1_sync;
    reg [1:0] k2_sync;
    reg [1:0] k3_sync;

    wire show_alarm = k2_sync[1];
    wire alarm_enable = k3_sync[1];
    wire [23:0] shown_digits = show_alarm ? {alarm_digits, 8'h00} : digits;

    wire [3:0] sec_ones  = shown_digits[3:0];
    wire [3:0] sec_tens  = shown_digits[7:4];
    wire [3:0] min_ones  = shown_digits[11:8];
    wire [3:0] min_tens  = shown_digits[15:12];
    wire [3:0] hour_ones = shown_digits[19:16];
    wire [3:0] hour_tens = shown_digits[23:20];

    wire [6:0] lg1_segments = seg7_cc(sec_ones);

    wire cp3_rise = (cp3_sync[2:1] == 2'b01);
    wire qd_rise = (qd_sync[2:1] == 2'b01);
    wire pulse_rise = (pulse_sync[2:1] == 2'b01);
    wire qd_control_allowed = !show_alarm;
    wire alarm_time_matches = (digits[23:8] == alarm_digits);

    wire k0_level = k0_sync[1];
    wire k1_level = k1_sync[1];
    wire speaker_out = alarm_active_cp1_sync[1] ? alarm_tone_divider[6] : 1'b0;

    function [7:0] inc_hour_pair;
        input [7:0] current;
        reg [3:0] h_tens;
        reg [3:0] h_ones;
        begin
            h_tens = current[7:4];
            h_ones = current[3:0];

            if (h_tens == 4'd2) begin
                if (h_ones == 4'd3) begin
                    h_tens = 4'd0;
                    h_ones = 4'd0;
                end else begin
                    h_ones = h_ones + 4'd1;
                end
            end else if (h_ones == 4'd9) begin
                h_ones = 4'd0;
                h_tens = h_tens + 4'd1;
            end else begin
                h_ones = h_ones + 4'd1;
            end

            inc_hour_pair = {h_tens, h_ones};
        end
    endfunction

    function [15:0] inc_minute_pair;
        input [15:0] current;
        reg [3:0] h_tens;
        reg [3:0] h_ones;
        reg [3:0] m_tens;
        reg [3:0] m_ones;
        reg [7:0] next_hour;
        begin
            h_tens = current[15:12];
            h_ones = current[11:8];
            m_tens = current[7:4];
            m_ones = current[3:0];
            next_hour = 8'h00;

            if ((m_tens == 4'd5) && (m_ones == 4'd9)) begin
                m_tens = 4'd0;
                m_ones = 4'd0;
                next_hour = inc_hour_pair({h_tens, h_ones});
                h_tens = next_hour[7:4];
                h_ones = next_hour[3:0];
            end else if (m_ones == 4'd9) begin
                m_ones = 4'd0;
                m_tens = m_tens + 4'd1;
            end else begin
                m_ones = m_ones + 4'd1;
            end

            inc_minute_pair = {h_tens, h_ones, m_tens, m_ones};
        end
    endfunction

    function [15:0] inc_alarm_hour;
        input [15:0] current;
        reg [7:0] next_hour;
        begin
            next_hour = inc_hour_pair(current[15:8]);
            inc_alarm_hour = {next_hour, current[7:0]};
        end
    endfunction

    function [15:0] inc_alarm_minute;
        input [15:0] current;
        begin
            inc_alarm_minute = inc_minute_pair(current);
        end
    endfunction

    function [23:0] inc_hour;
        input [23:0] current;
        reg [7:0] next_hour;
        begin
            next_hour = inc_hour_pair(current[23:16]);
            inc_hour = {next_hour, current[15:8], 8'h00};
        end
    endfunction

    function [23:0] inc_minute;
        input [23:0] current;
        begin
            inc_minute = {inc_minute_pair(current[23:8]), 8'h00};
        end
    endfunction

    function [23:0] inc_second;
        input [23:0] current;
        reg [15:0] next_hhmm;
        reg [3:0] s_tens;
        reg [3:0] s_ones;
        begin
            next_hhmm = current[23:8];
            s_tens = current[7:4];
            s_ones = current[3:0];

            if (s_ones == 4'd9) begin
                s_ones = 4'd0;
                case (s_tens)
                    4'd0: s_tens = 4'd1;
                    4'd1: s_tens = 4'd2;
                    4'd2: s_tens = 4'd3;
                    4'd3: s_tens = 4'd4;
                    4'd4: s_tens = 4'd5;
                    default: begin
                        s_tens = 4'd0;
                        next_hhmm = inc_minute_pair(current[23:8]);
                    end
                endcase
            end else begin
                s_ones = s_ones + 4'd1;
            end

            inc_second = {next_hhmm, s_tens, s_ones};
        end
    endfunction

    function [6:0] seg7_cc;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: seg7_cc = 7'b0111111;
                4'd1: seg7_cc = 7'b0000110;
                4'd2: seg7_cc = 7'b1011011;
                4'd3: seg7_cc = 7'b1001111;
                4'd4: seg7_cc = 7'b1100110;
                4'd5: seg7_cc = 7'b1101101;
                4'd6: seg7_cc = 7'b1111101;
                4'd7: seg7_cc = 7'b0000111;
                4'd8: seg7_cc = 7'b1111111;
                4'd9: seg7_cc = 7'b1101111;
                default: seg7_cc = 7'b0000000;
            endcase
        end
    endfunction

    always @(*) begin
        digits_next_tick = inc_second(digits);
    end

    always @(negedge clr_n or posedge cp2) begin
        if (!clr_n) begin
            run_enable <= 1'b1;
            alarm_active <= 1'b0;
            alarm_check_pending <= 1'b0;
            digits <= 24'h000000;
            alarm_digits <= 16'h0000;
            cp3_sync <= 3'b000;
            qd_sync <= 3'b000;
            pulse_sync <= 3'b000;
            k0_sync <= 2'b00;
            k1_sync <= 2'b00;
            k2_sync <= 2'b00;
            k3_sync <= 2'b00;
        end else begin
            cp3_sync <= {cp3_sync[1:0], cp3};
            qd_sync <= {qd_sync[1:0], qd};
            pulse_sync <= {pulse_sync[1:0], pulse};
            k0_sync <= {k0_sync[0], k0};
            k1_sync <= {k1_sync[0], k1};
            k2_sync <= {k2_sync[0], k2};
            k3_sync <= {k3_sync[0], k3};

            alarm_check_pending <= 1'b0;

            if (!alarm_enable) begin
                alarm_active <= 1'b0;
            end else if (alarm_active) begin
                if (qd_rise && qd_control_allowed) begin
                    alarm_active <= 1'b0;
                end
            end else if (alarm_check_pending && alarm_time_matches) begin
                alarm_active <= 1'b1;
            end

            if (qd_rise && qd_control_allowed) begin
                if (alarm_active) begin
                    alarm_active <= 1'b0;
                end else begin
                    run_enable <= ~run_enable;
                end
            end

            if (run_enable) begin
                if (cp3_rise) begin
                    digits <= digits_next_tick;
                    // Split alarm matching from the BCD carry path by one CP2 cycle.
                    alarm_check_pending <= alarm_enable && !alarm_active && (digits_next_tick[7:0] == 8'h00);
                end
            end else if (!alarm_active && pulse_rise) begin
                if (show_alarm) begin
                    if (k0_level) begin
                        alarm_digits <= inc_alarm_hour(alarm_digits);
                    end else if (k1_level) begin
                        alarm_digits <= inc_alarm_minute(alarm_digits);
                    end
                end else if (k0_level) begin
                    digits <= inc_hour(digits);
                end else if (k1_level) begin
                    digits <= inc_minute(digits);
                end
            end
        end
    end

    always @(negedge clr_n or posedge cp1) begin
        if (!clr_n) begin
            alarm_active_cp1_sync <= 2'b00;
            alarm_tone_divider <= 7'h00;
        end else begin
            alarm_active_cp1_sync <= {alarm_active_cp1_sync[0], alarm_active};
            if (alarm_active_cp1_sync[1]) begin
                alarm_tone_divider <= alarm_tone_divider + 7'd1;
            end else begin
                alarm_tone_divider <= 7'h00;
            end
        end
    end

    assign lg1_d0 = lg1_segments[0];
    assign lg1_d1 = lg1_segments[1];
    assign lg1_d2 = lg1_segments[2];
    assign lg1_d3 = lg1_segments[3];
    assign lg1_d4 = lg1_segments[4];
    assign lg1_d5 = lg1_segments[5];
    assign lg1_d6 = lg1_segments[6];
    assign lg1_d7 = speaker_out;

    assign lg2_a = sec_tens[0];
    assign lg2_b = sec_tens[1];
    assign lg2_c = sec_tens[2];
    assign lg2_d = sec_tens[3];

    assign lg3_a = min_ones[0];
    assign lg3_b = min_ones[1];
    assign lg3_c = min_ones[2];
    assign lg3_d = min_ones[3];

    assign lg4_a = min_tens[0];
    assign lg4_b = min_tens[1];
    assign lg4_c = min_tens[2];
    assign lg4_d = min_tens[3];

    assign lg5_a = hour_ones[0];
    assign lg5_b = hour_ones[1];
    assign lg5_c = hour_ones[2];
    assign lg5_d = hour_ones[3];

    assign lg6_a = hour_tens[0];
    assign lg6_b = hour_tens[1];
    assign lg6_c = hour_tens[2];
    assign lg6_d = hour_tens[3];

endmodule
