`timescale 1ns / 1ps

module axi_cpu_interface#
(
    parameter  C_M_BRAM_BASE_ADDR = 32'h40000000,

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
    
    // CPU Connect Signal
    input wire         mem_req,
    input wire         we,
    input wire [11:0]  mem_addr,
    input wire [15:0]  mem_wdata,
    output reg [15:0]  mem_rdata,
    
    // I/O Connect Signal
    input wire         io_req,
    input wire [31:0]  io_addr,
    input wire [15:0]  io_wdata,
    
    // CPU Contorl Signal
    output reg         cpu_ack
);

    reg [C_M_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
    reg                             axi_awvalid;
    reg [C_M_AXI_DATA_WIDTH-1 : 0]  axi_wdata;
    reg                             axi_wvalid;
    reg                             axi_bready;
    reg [C_M_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
    reg                             axi_arvalid;
    reg                             axi_rready;

    reg read_in_progress;
    reg write_in_progress;

    assign M_AXI_AWADDR  = axi_awaddr;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_AWVALID = axi_awvalid;
    assign M_AXI_WDATA   = axi_wdata;
    assign M_AXI_WSTRB   = 4'b1111;
    assign M_AXI_WVALID  = axi_wvalid;
    assign M_AXI_BREADY  = axi_bready;
    assign M_AXI_ARADDR  = axi_araddr;
    assign M_AXI_ARPROT  = 3'b001;
    assign M_AXI_ARVALID = axi_arvalid;
    assign M_AXI_RREADY  = axi_rready;


    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            read_in_progress  <= 1'b0;
            write_in_progress <= 1'b0;
            cpu_ack       <= 1'b0;
        end else begin
            // ready
            if (!mem_req) begin
                cpu_ack <= 1'b0;
            end            
            // read start
            if (mem_req && !we && !read_in_progress && !cpu_ack) begin
                read_in_progress <= 1'b1;
            end           
            // read end
            if (read_in_progress && M_AXI_RVALID && axi_rready) begin
                read_in_progress <= 1'b0;
                cpu_ack      <= 1'b1;
            end
            // write start
            if (((mem_req && we) || io_req) && !write_in_progress && !cpu_ack) begin
                write_in_progress <= 1'b1;
            end
            // write end
            if (write_in_progress && M_AXI_BVALID && axi_bready) begin
                write_in_progress <= 1'b0;
                cpu_ack       <= 1'b1;
            end
        end
    end

    // Read Address Channel (AR)
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            axi_araddr  <= 32'd0;
            axi_arvalid <= 1'b0;
        end else begin
            if (mem_req && !we && !read_in_progress && !cpu_ack) begin
                axi_araddr  <= C_M_BRAM_BASE_ADDR + {18'b0, mem_addr, 2'b00};
                axi_arvalid <= 1'b1;
            end
            else if (axi_arvalid && M_AXI_ARREADY) begin
                axi_arvalid <= 1'b0;
            end
        end
    end

    // Read Data Channel (R)
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            axi_rready <= 1'b0;
            mem_rdata  <= 16'd0;
        end else begin
            if (read_in_progress && !axi_rready) begin
                axi_rready <= 1'b1;
            end
            else if (axi_rready && M_AXI_RVALID) begin
                mem_rdata  <= M_AXI_RDATA[15:0];
                axi_rready <= 1'b0;
            end
        end
    end

    // Write Address Channel (AW)
    always @(posedge M_AXI_ACLK or negedge M_AXI_ARESETN) begin
        if (!M_AXI_ARESETN) begin
            axi_awaddr  <= 32'd0;
            axi_awvalid <= 1'b0;
        end else begin
            if (((mem_req && we) || io_req) && !write_in_progress && !cpu_ack) begin
                if (io_req) begin
                    axi_awaddr <= io_addr;
                end
                else begin    
                    axi_awaddr  <= C_M_BRAM_BASE_ADDR + {18'b0, mem_addr, 2'b00};
                end    
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
            if (((mem_req && we) || io_req) && !write_in_progress && !cpu_ack) begin
                if (io_req) begin
                    axi_wdata <= {16'd0, io_wdata};
                end
                else begin
                    axi_wdata  <= {16'd0, mem_wdata};
                end    
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
