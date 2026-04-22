`timescale 1ns / 1ps

module clock(
    input  wire cp3,
    input  wire clr_n,
    input  wire qd,
    input  wire pulse,
    input  wire k0,
    input  wire k1,
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
    reg [23:0] digits;

    wire [3:0] sec_ones = digits[3:0];
    wire [3:0] sec_tens = digits[7:4];
    wire [3:0] min_ones = digits[11:8];
    wire [3:0] min_tens = digits[15:12];
    wire [3:0] hour_ones = digits[19:16];
    wire [3:0] hour_tens = digits[23:20];

    wire [6:0] lg1_segments = seg7_cc(sec_ones);

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

    function [23:0] inc_hour;
        input [23:0] current;
        reg [3:0] h_tens;
        reg [3:0] h_ones;
        reg [3:0] m_tens;
        reg [3:0] m_ones;
        reg [7:0] next_hour;
        begin
            h_tens = current[23:20];
            h_ones = current[19:16];
            m_tens = current[15:12];
            m_ones = current[11:8];
            next_hour = 8'h00;

            next_hour = inc_hour_pair({h_tens, h_ones});
            h_tens = next_hour[7:4];
            h_ones = next_hour[3:0];

            inc_hour = {h_tens, h_ones, m_tens, m_ones, 4'd0, 4'd0};
        end
    endfunction

    function [23:0] inc_minute;
        input [23:0] current;
        reg [3:0] h_tens;
        reg [3:0] h_ones;
        reg [3:0] m_tens;
        reg [3:0] m_ones;
        reg [7:0] next_hour;
        begin
            h_tens = current[23:20];
            h_ones = current[19:16];
            m_tens = current[15:12];
            m_ones = current[11:8];
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

            inc_minute = {h_tens, h_ones, m_tens, m_ones, 4'd0, 4'd0};
        end
    endfunction

    function [23:0] inc_second;
        input [23:0] current;
        reg [3:0] h_tens;
        reg [3:0] h_ones;
        reg [3:0] m_tens;
        reg [3:0] m_ones;
        reg [3:0] s_tens;
        reg [3:0] s_ones;
        reg [7:0] next_hour;
        begin
            h_tens = current[23:20];
            h_ones = current[19:16];
            m_tens = current[15:12];
            m_ones = current[11:8];
            s_tens = current[7:4];
            s_ones = current[3:0];
            next_hour = 8'h00;

            if (s_ones == 4'd9) begin
                s_ones = 4'd0;
                if (s_tens == 4'd5) begin
                    s_tens = 4'd0;
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
                end else begin
                    s_tens = s_tens + 4'd1;
                end
            end else begin
                s_ones = s_ones + 4'd1;
            end

            inc_second = {h_tens, h_ones, m_tens, m_ones, s_tens, s_ones};
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

    always @(negedge clr_n or posedge qd) begin
        if (!clr_n) begin
            run_enable <= 1'b1;
        end else begin
            run_enable <= ~run_enable;
        end
    end

    always @(negedge clr_n or posedge cp3 or posedge pulse) begin
        if (!clr_n) begin
            digits <= 24'h000000;
        end else if (pulse) begin
            if (!run_enable) begin
                if (k0) begin
                    digits <= inc_hour(digits);
                end else if (k1) begin
                    digits <= inc_minute(digits);
                end else begin
                    digits <= digits;
                end
            end
        end else if (cp3) begin
            if (run_enable) begin
                digits <= inc_second(digits);
            end else begin
                digits <= digits;
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
    assign lg1_d7 = 1'b0;

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
