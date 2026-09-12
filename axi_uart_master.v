`timescale 1ns / 1ps

module axi_uart_master#(
    parameter  C_M_TARGET_SLAVE_BASE_ADDR = 32'h40600000,
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32
)
(
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN, 
	
    // Write Address Channel (AW)
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [2 : 0] M_AXI_AWPROT,
    output wire  M_AXI_AWVALID,
    input wire   M_AXI_AWREADY,

    // Write Data Channel (W)
    output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    output wire  M_AXI_WVALID,
    input wire   M_AXI_WREADY,

    // Write Response Channel (B)
    input wire [1 : 0] M_AXI_BRESP,
    input wire   M_AXI_BVALID,
    output wire  M_AXI_BREADY,

    // Read Address Channel (AR)
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [2 : 0] M_AXI_ARPROT,
    output wire  M_AXI_ARVALID,
    input wire   M_AXI_ARREADY,

    // Read Data Channel (R)
    input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0] M_AXI_RRESP,
    input wire   M_AXI_RVALID,
    output wire  M_AXI_RREADY,
    
    output reg uart_ack,

    input wire [31:0] uart_addr,
    input wire [31:0] uart_wdata_out,
    input wire        uart_req
);

    reg [C_M_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
    reg                             axi_awvalid;
    reg [C_M_AXI_DATA_WIDTH-1 : 0]  axi_wdata;
    reg                             axi_wvalid;
    reg                             axi_bready;
    reg [C_M_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
    reg                             axi_arvalid;
    reg                             axi_rready;

    reg write_in_progress;

    assign M_AXI_AWADDR  = axi_awaddr;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_AWVALID = axi_awvalid;
    assign M_AXI_WDATA   = axi_wdata;
    assign M_AXI_WSTRB   = 4'b1111;
    assign M_AXI_WVALID  = axi_wvalid;
    assign M_AXI_BREADY  = axi_bready;

    assign M_AXI_ARADDR  = 32'd0;
    assign M_AXI_ARPROT  = 3'b001;
    assign M_AXI_ARVALID = 1'b0;  
    assign M_AXI_RREADY  = 1'b0;  

    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            write_in_progress <= 1'b0;
            uart_ack       <= 1'b0;
        end else begin
            if (!uart_req) begin
                uart_ack <= 1'b0;
            end

            // write start
            if (uart_req && !write_in_progress && !uart_ack) begin
                write_in_progress <= 1'b1;
            end

            // write end
            if (write_in_progress && M_AXI_BVALID && axi_bready) begin
                write_in_progress <= 1'b0;
                uart_ack       <= 1'b1;
            end
        end
    end

    // Write Address Channel (AW)
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            axi_awaddr  <= 32'd0;
            axi_awvalid <= 1'b0;
        end else begin
            if (uart_req && !write_in_progress && !uart_ack) begin  
                axi_awaddr  <= C_M_TARGET_SLAVE_BASE_ADDR + 32'h00000004;   
                axi_awvalid <= 1'b1;
            end
            else if (axi_awvalid && M_AXI_AWREADY) begin
                axi_awvalid <= 1'b0;
            end
        end
    end

    // Write Data Channel (W)
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            axi_wdata  <= 32'd0;
            axi_wvalid <= 1'b0;
        end else begin
            if (uart_req && !write_in_progress && !uart_ack) begin
                axi_wdata  <= uart_wdata_out;   
                axi_wvalid <= 1'b1;
            end
            else if (axi_wvalid && M_AXI_WREADY) begin
                axi_wvalid <= 1'b0;
            end
        end
    end

    // Write Response Channel (B)
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            axi_bready <= 1'b0;
        end else begin
            if (write_in_progress && !axi_bready) begin
                axi_bready <= 1'b1;
            end
            else if (axi_bready && M_AXI_BVALID) begin
                axi_bready <= 1'b0;
            end
        end
    end

endmodule