`timescale 1ns / 1ps


module axi_uart_slave#
	(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    
    // Write Address Channel (AW)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire  S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    
    // Write Data Channel (W)
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB, 
    input wire  S_AXI_WVALID,
    output wire S_AXI_WREADY,
    
    // Write Response Channel (B)
    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    
    // Other Channels
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire  S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire  S_AXI_RREADY,
    
    //uart signal
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] uart_data,
    output reg uart_trigger
);

    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    
    reg aw_done;
    reg w_done;
    
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg; 
    
    assign uart_data = slv_reg;
    
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = 2'b00; 
    assign S_AXI_BVALID  = axi_bvalid;
    
    assign S_AXI_ARREADY = 1'b0; 
    assign S_AXI_RDATA   = slv_reg;
    assign S_AXI_RRESP   = 2'b00;
    assign S_AXI_RVALID  = 1'b0;

    // Write Address Channel (AW) 
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            aw_done     <= 1'b0;
        end else begin
            if (S_AXI_AWVALID && !axi_awready && !aw_done) begin
                axi_awready <= 1'b1;
                aw_done     <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end

            if (axi_bvalid && S_AXI_BREADY) begin
                aw_done <= 1'b0;
            end
        end
    end

    // Write Data Channel (W)
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_wready    <= 1'b0;
            w_done        <= 1'b0;
            slv_reg       <= 32'h00000000;
            uart_trigger  <= 1'b0;
        end else begin
            if (S_AXI_WVALID && !axi_wready && !w_done) begin
                axi_wready    <= 1'b1;
                w_done        <= 1'b1; 
                slv_reg       <= S_AXI_WDATA;
                uart_trigger  <= 1'b1;
            end 
            else begin
                axi_wready    <= 1'b0;
                uart_trigger  <= 1'b0;
            end

            if (axi_bvalid && S_AXI_BREADY) begin
                w_done <= 1'b0;
            end
        end
    end

    // Write Response Channel (B) 
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (aw_done && w_done && !axi_bvalid) begin
                axi_bvalid <= 1'b1;
            end 
            else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

endmodule
