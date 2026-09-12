`timescale 1ns / 1ps


module axi_uart_trans#
    (
        // Parameters of Axi Master Bus Interface M00_AXI
        parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR = 32'h40600000,
        parameter integer C_M00_AXI_ADDR_WIDTH  = 32,
        parameter integer C_M00_AXI_DATA_WIDTH  = 32,

        // Parameters of Axi Slave Bus Interface S02_AXI
        parameter integer C_S02_AXI_DATA_WIDTH  = 32,
        parameter integer C_S02_AXI_ADDR_WIDTH  = 4
    )
    (
        // Ports of Axi Master Bus Interface M00_AXI
        input wire  m00_axi_aclk,
        input wire  m00_axi_aresetn,
        output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
        output wire [2 : 0] m00_axi_awprot,
        output wire  m00_axi_awvalid,
        input wire  m00_axi_awready,
        output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
        output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
        output wire  m00_axi_wvalid,
        input wire  m00_axi_wready,
        input wire [1 : 0] m00_axi_bresp,
        input wire  m00_axi_bvalid,
        output wire  m00_axi_bready,
        output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
        output wire [2 : 0] m00_axi_arprot,
        output wire  m00_axi_arvalid,
        input wire  m00_axi_arready,
        input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
        input wire [1 : 0] m00_axi_rresp,
        input wire  m00_axi_rvalid,
        output wire  m00_axi_rready,

        // Ports of Axi Slave Bus Interface S02_AXI
        input wire  s02_axi_aclk,
        input wire  s02_axi_aresetn,
        input wire [C_S02_AXI_ADDR_WIDTH-1 : 0] s02_axi_awaddr,
        input wire [2 : 0] s02_axi_awprot,
        input wire  s02_axi_awvalid,
        output wire  s02_axi_awready,
        input wire [C_S02_AXI_DATA_WIDTH-1 : 0] s02_axi_wdata,
        input wire [(C_S02_AXI_DATA_WIDTH/8)-1 : 0] s02_axi_wstrb,
        input wire  s02_axi_wvalid,
        output wire  s02_axi_wready,
        output wire [1 : 0] s02_axi_bresp,
        output wire  s02_axi_bvalid,
        input wire  s02_axi_bready,
        input wire [C_S02_AXI_ADDR_WIDTH-1 : 0] s02_axi_araddr,
        input wire [2 : 0] s02_axi_arprot,
        input wire  s02_axi_arvalid,
        output wire  s02_axi_arready,
        output wire [C_S02_AXI_DATA_WIDTH-1 : 0] s02_axi_rdata,
        output wire [1 : 0] s02_axi_rresp,
        output wire  s02_axi_rvalid,
        input wire  s02_axi_rready
    );

    wire [31:0] w_uart_data_in;
    wire        w_uart_trigger;
    
    wire [31:0] w_uart_awaddr;
    wire [31:0] w_uart_wdata_out;
    wire        w_uart_req;
    wire        w_uart_ack;

    axi_uart_slave # ( 
        .C_S_AXI_DATA_WIDTH(C_S02_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S02_AXI_ADDR_WIDTH)
    ) axi_uart_slave_inst (
        .S_AXI_ACLK(s02_axi_aclk),
        .S_AXI_ARESETN(s02_axi_aresetn),
        .S_AXI_AWADDR(s02_axi_awaddr),
        //.S_AXI_AWPROT(s02_axi_awprot),
        .S_AXI_AWVALID(s02_axi_awvalid),
        .S_AXI_AWREADY(s02_axi_awready),
        .S_AXI_WDATA(s02_axi_wdata),
        .S_AXI_WSTRB(s02_axi_wstrb),
        .S_AXI_WVALID(s02_axi_wvalid),
        .S_AXI_WREADY(s02_axi_wready),
        .S_AXI_BRESP(s02_axi_bresp),
        .S_AXI_BVALID(s02_axi_bvalid),
        .S_AXI_BREADY(s02_axi_bready),
        .S_AXI_ARADDR(s02_axi_araddr),
        //.S_AXI_ARPROT(s02_axi_arprot),
        .S_AXI_ARVALID(s02_axi_arvalid),
        .S_AXI_ARREADY(s02_axi_arready),
        .S_AXI_RDATA(s02_axi_rdata),
        .S_AXI_RRESP(s02_axi_rresp),
        .S_AXI_RVALID(s02_axi_rvalid),
        .S_AXI_RREADY(s02_axi_rready),
        
        .uart_data(w_uart_data_in),
        .uart_trigger(w_uart_trigger)
    );

    // Add user logic here: UART Transform Module
    uart_transform #(
        .UART_TX_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR + 32'h00000004) // base addr
    ) uart_transform_inst (
        .clk(s02_axi_aclk),
        .resetn(s02_axi_aresetn),
        
        // From Slave
        .uart_wdata_in(w_uart_data_in),
        .uart_trigger(w_uart_trigger),
        
        // To Master
        .uart_awaddr(w_uart_awaddr),
        .uart_wdata_out(w_uart_wdata_out),
        .uart_req(w_uart_req),
        
        // From Master
        .uart_ready(w_uart_ack)
    );

   axi_uart_master # ( 
        .C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
        .C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
    ) axi_uart_master_inst (
        .M_AXI_ACLK(m00_axi_aclk),
        .M_AXI_ARESETN(m00_axi_aresetn),
        .M_AXI_AWADDR(m00_axi_awaddr),
        .M_AXI_AWPROT(m00_axi_awprot),
        .M_AXI_AWVALID(m00_axi_awvalid),
        .M_AXI_AWREADY(m00_axi_awready),
        .M_AXI_WDATA(m00_axi_wdata),
        .M_AXI_WSTRB(m00_axi_wstrb),
        .M_AXI_WVALID(m00_axi_wvalid),
        .M_AXI_WREADY(m00_axi_wready),
        .M_AXI_BRESP(m00_axi_bresp),
        .M_AXI_BVALID(m00_axi_bvalid),
        .M_AXI_BREADY(m00_axi_bready),
        .M_AXI_ARADDR(m00_axi_araddr),
        .M_AXI_ARPROT(m00_axi_arprot),
        .M_AXI_ARVALID(m00_axi_arvalid),
        .M_AXI_ARREADY(m00_axi_arready),
        .M_AXI_RDATA(m00_axi_rdata),
        .M_AXI_RRESP(m00_axi_rresp),
        .M_AXI_RVALID(m00_axi_rvalid),
        .M_AXI_RREADY(m00_axi_rready),
        
        // Custom Ports
        .uart_ack(w_uart_ack),
        .uart_addr(w_uart_awaddr),
        .uart_wdata_out(w_uart_wdata_out),
        .uart_req(w_uart_req)
    );

    // User logic ends

endmodule

