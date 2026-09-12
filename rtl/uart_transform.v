`timescale 1ns / 1ps

module uart_transform#(
    parameter integer UART_TX_ADDR = 32'h40600004
)
(
    input wire clk,
    input wire resetn,
    
    output reg [31:0] uart_awaddr,
    output reg [31:0] uart_wdata_out,
    output reg        uart_req,
    
    input uart_ready,  
    
    input wire [31:0] uart_wdata_in,
    input wire        uart_trigger
    
);
    // Hex to ASCII
    function [7:0] hex2ascii;
        input [3:0] hex_val;
        begin
            if (hex_val <= 4'h9) 
                hex2ascii = hex_val + 8'h30; // 0~9 -> '0'~'9'
            else 
                hex2ascii = hex_val + 8'h37; // A~F -> 'A'~'F'
        end
    endfunction

    // FSM
    reg [7:0] tx_buffer [0:5];
    reg [2:0] tx_index;
    reg [2:0] uart_state;

    localparam U_IDLE  = 3'd0,
               U_AW    = 3'd1,
               U_W     = 3'd2,
               U_NEXT  = 3'd3;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            uart_state <= U_IDLE;
            tx_index  <= 3'd0;
            uart_req       <= 1'b0;
            uart_awaddr    <= 32'd0;
            uart_wdata_out <= 32'd0;
        end else begin
            case (uart_state)
                U_IDLE: begin
                    if (uart_trigger) begin 
                        tx_buffer[0] <= hex2ascii(uart_wdata_in[15:12]);
                        tx_buffer[1] <= hex2ascii(uart_wdata_in[11:8]);
                        tx_buffer[2] <= hex2ascii(uart_wdata_in[7:4]);
                        tx_buffer[3] <= hex2ascii(uart_wdata_in[3:0]);
                        tx_buffer[4] <= 8'h0D; // '\r' (Carriage Return)
                        tx_buffer[5] <= 8'h0A; // '\n' (Line Feed)
                        tx_index <= 3'd0;
                        uart_state <= U_AW;
                    end
                end
                
                U_AW: begin
                    uart_req       <= 1'b1;
                    uart_awaddr    <= UART_TX_ADDR;
                    uart_wdata_out <= {24'd0, tx_buffer[tx_index]};
                    uart_state     <= U_W;
                end
                
                U_W: begin
                    uart_req <= 1'b0;
                    if (uart_ready) begin 
                        uart_state <= U_NEXT;
                    end
                end
                
                U_NEXT: begin
                    if (tx_index == 3'd5) begin 
                        uart_state <= U_IDLE;   
                    end else begin
                        tx_index <= tx_index + 3'd1;
                        uart_state <= U_AW;         
                    end
                end
            endcase
        end
    end
    
endmodule
