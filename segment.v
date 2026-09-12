`timescale 1ns / 1ps


module segment(
    input wire clk,          
    input wire reset_n,      
    input wire calc_done,    
    input wire [15:0] data, 
    output reg [7:0] dig,   
    output reg [5:0] sel    
);

    // Binary to BCD (Double Dabble)

    reg [19:0] bcd;
    reg [35:0] shift_reg;
    integer i;

    always @(*) begin
        shift_reg = {20'd0, data}; 
        
        for (i = 0; i < 16; i = i + 1) begin
            // Shift-and-Add-3
            if (shift_reg[19:16] >= 5) shift_reg[19:16] = shift_reg[19:16] + 3;
            if (shift_reg[23:20] >= 5) shift_reg[23:20] = shift_reg[23:20] + 3;
            if (shift_reg[27:24] >= 5) shift_reg[27:24] = shift_reg[27:24] + 3;
            if (shift_reg[31:28] >= 5) shift_reg[31:28] = shift_reg[31:28] + 3;
            if (shift_reg[35:32] >= 5) shift_reg[35:32] = shift_reg[35:32] + 3;
            
            shift_reg = shift_reg << 1;
        end
        bcd = shift_reg[35:16]; 
    end

    // Timer(period : 1ms)
    reg [15:0] clk_div;
    wire scan_tick = (clk_div == 16'd50000); 

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) clk_div <= 0;
        else if (scan_tick) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end

    // Scanning Counter
    reg [2:0] scan_cnt;
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) scan_cnt <= 0;
        else if (scan_tick) begin
            if (scan_cnt == 3'd5) scan_cnt <= 0;
            else scan_cnt <= scan_cnt + 1;
        end
    end

    // sel, dig Mapping
    reg [3:0] current_digit_val;
    
    always @(*) begin
        sel = 6'b111111; 
        current_digit_val = 4'h0;

        case(scan_cnt)
            3'd0: begin
                sel = 6'b111110; 
                current_digit_val = bcd[3:0];
            end
            3'd1: begin
                sel = 6'b111101; 
                current_digit_val = bcd[7:4];
            end
            3'd2: begin
                sel = 6'b111011; 
                current_digit_val = bcd[11:8];
            end
            3'd3: begin
                sel = 6'b110111; 
                current_digit_val = bcd[15:12];
            end
            3'd4: begin
                sel = 6'b101111; 
                current_digit_val = bcd[19:16];
            end
            3'd5: begin
                sel = 6'b011111; 
                current_digit_val = 4'hF; 
            end
        endcase
    end

    // 7-Segment Decoder
    always @(*) begin
        if (!calc_done) begin
            dig = 8'b1011_1111; 
        end else begin
            case(current_digit_val)
                4'h0: dig = 8'hc0;
                4'h1: dig = 8'hf9;
                4'h2: dig = 8'ha4;
                4'h3: dig = 8'hb0;
                4'h4: dig = 8'h99;
                4'h5: dig = 8'h92;
                4'h6: dig = 8'h82;
                4'h7: dig = 8'hf8;
                4'h8: dig = 8'h80;
                4'h9: dig = 8'h90;
                4'hF: dig = 8'hff; 
                default: dig = 8'hff;
            endcase
        end
    end

endmodule