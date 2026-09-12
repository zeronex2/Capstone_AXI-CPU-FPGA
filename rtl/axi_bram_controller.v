`timescale 1ns / 1ps

module axi_bram_controller #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32
)
(
    // Global Clock and Reset
    input  wire                                S_AXI_ACLK,
    input  wire                                S_AXI_ARESETN,

    // 1. Write Address Channel (AW)
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input  wire [2 : 0]                        S_AXI_AWPROT,
    input  wire                                S_AXI_AWVALID,
    output wire                                S_AXI_AWREADY,

    // 2. Write Data Channel (W)
    input  wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input  wire                                S_AXI_WVALID,
    output wire                                S_AXI_WREADY,

    // 3. Write Response Channel (B)
    output wire [1 : 0]                        S_AXI_BRESP,
    output wire                                S_AXI_BVALID,
    input  wire                                S_AXI_BREADY,

    // 4. Read Address Channel (AR)
    input  wire [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input  wire [2 : 0]                        S_AXI_ARPROT,
    input  wire                                S_AXI_ARVALID,
    output wire                                S_AXI_ARREADY,

    // 5. Read Data Channel (R)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output wire [1 : 0]                        S_AXI_RRESP,
    output wire                                S_AXI_RVALID,
    input  wire                                S_AXI_RREADY,

                
    output wire       bram_clka,      
    output reg        ena,     
    output reg        wea,  	
    output reg [11:0] mem_addra,      
    output reg [15:0] mem_wdata,
    output wire       bram_clkb,     
    output reg        enb,  
    output reg [11:0] mem_addrb,  
    input wire [15:0] mem_rdata
);
    
    reg axi_awready;
    reg axi_wready;
    reg axi_bvalid;
    reg axi_arready;
    reg axi_rvalid;
    reg [15:0] axi_rdata;

    reg [C_S_AXI_ADDR_WIDTH-1 : 0] reg_awaddr;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] reg_wdata;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] reg_araddr;

    reg aw_has_data;
    reg w_has_data;
    reg ar_has_data;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = 2'b00; // OKAY
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = {16'h0000, axi_rdata};
    assign S_AXI_RRESP   = 2'b00; // OKAY
    assign S_AXI_RVALID  = axi_rvalid;
    
    assign bram_clka = S_AXI_ACLK;
    assign bram_clkb = S_AXI_ACLK;

    wire bram_write_run = aw_has_data && w_has_data;
    wire bram_read_run  = ar_has_data && !axi_rvalid;

    // Write Address Channel (AW) 
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            reg_awaddr  <= 0;
            aw_has_data <= 1'b0;
        end else begin
            if (S_AXI_AWVALID && !axi_awready && !aw_has_data) begin
                axi_awready <= 1'b1;
                reg_awaddr  <= S_AXI_AWADDR;
                aw_has_data <= 1'b1;
            end 
            else begin
                axi_awready <= 1'b0;
                if (bram_write_run) begin
                    aw_has_data <= 1'b0;
                end
            end
        end
    end

    // Write Data Channel (W) 
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_wready <= 1'b0;
            reg_wdata  <= 0;
            w_has_data <= 1'b0;
        end else begin
            if (S_AXI_WVALID && !axi_wready && !w_has_data) begin
                axi_wready <= 1'b1;
                reg_wdata  <= S_AXI_WDATA;
                w_has_data <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
                if (bram_write_run) begin
                    w_has_data <= 1'b0;
                end
            end
        end
    end

    // BRAM Port A Control
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            ena       <= 1'b0;
            wea       <= 1'b0;
            mem_addra <= 12'd0;
            mem_wdata <= 16'd0;
        end else begin
            if (bram_write_run) begin
                ena       <= 1'b1;
                wea       <= 1'b1;
                mem_addra <= reg_awaddr[13:2];
                mem_wdata <= reg_wdata[15:0];
            end else begin
                ena <= 1'b0;
                wea <= 1'b0;
            end
        end
    end

    // Write Response Channel (B)
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (bram_write_run) begin
                axi_bvalid <= 1'b1;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // Read Address Channel (AR) 
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            reg_araddr  <= 0;
            ar_has_data <= 1'b0;
        end else begin
            if (S_AXI_ARVALID && !axi_arready && !ar_has_data) begin
                axi_arready <= 1'b1;
                reg_araddr  <= S_AXI_ARADDR;
                ar_has_data <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
                if (bram_read_run) begin
                    ar_has_data <= 1'b0;
                end
            end
        end
    end

    // BRAM Port B Control
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            enb       <= 1'b0;
            mem_addrb <= 12'd0;
        end else begin
            if (bram_read_run) begin
                enb       <= 1'b1;
                mem_addrb <= reg_araddr[13:2];
            end else begin
                enb <= 1'b0;
            end
        end
    end

    // Read Data Channel (R) 
    reg enb_d1;
    always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 1'b0;
            axi_rdata  <= 16'd0;
            enb_d1     <= 1'b0;
        end else begin
            enb_d1 <= enb; //latency 1
            if (enb_d1) begin
                axi_rvalid <= 1'b1;
                axi_rdata  <= mem_rdata; 
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
