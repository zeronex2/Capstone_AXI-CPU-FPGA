`timescale 1ns / 1ps

module cpu_core(
    input clk,
    input reset,

    output reg mem_req, //we vaild signal
    output reg we,
    output reg [11:0] mem_addr,
    output reg [15:0] mem_wdata,
    input  [15:0] mem_rdata,
    input  cpu_ready,
    
    output reg        io_req,
    output reg [31:0] io_addr,
    output reg [15:0] io_wdata
);

    reg [15:0] AC,DR,IR;
    reg [11:0] PC,AR;
    reg [3:0]  SC;
    reg [2:0]  op;
    reg        E,I,S;

    wire [7:0] D; //decoder °á°ú°ª

    parameter
    CLA = 16'h7800, CLE = 16'h7400, CMA = 16'h7200,
    CME = 16'h7100, CIR = 16'h7080, CIL = 16'h7040,
    INC = 16'h7020, SPA = 16'h7010, SNA = 16'h7008,
    SZA = 16'h7004, SZE = 16'h7002, MOV = 16'h7001;

    decoder decoder0(
        .in (op),
        .out (D)
    );

    always @ (posedge clk or negedge reset) begin
        if(!reset) begin
            AC <= 16'h0000;
            DR <= 16'h0000;
            IR <= 16'h0000;
            PC <= 12'h000;
            AR <= 12'h000;
            SC <= 4'h0;
            I <= 0;
            E <= 0;
            S <= 1;
            mem_req <= 0;
            we <= 0;
            mem_addr <= 12'h000;
            mem_wdata <= 16'h0000;
            io_req <= 1'b0;
            io_addr <= 32'h00000000;
            io_wdata <= 16'h0000;
        end
        else begin
            if(S == 0) // HALT
                SC <= SC;
            else begin
                case (SC)
                    4'h0 : begin // T0 : AR <= PC
                        AR <= PC;
                        SC <= SC + 4'h1;
                        mem_addr <= PC;
                        mem_req <= 1;
                        we <= 0;
                    end
                    4'h1 : begin //T1 : IR <= M[AR]
                        mem_req <= 0;
                        if(cpu_ready) begin
                            IR <= mem_rdata;
                            SC <= SC + 4'h1;
                            PC <= PC + 4'h1;
                        end
                        else
                            SC <= SC;
                    end
                    4'h2 : begin //instruction decode
                        AR <= IR[11:0];
                        op <= IR[14:12];
                        I  <= IR[15];
                        SC <= SC + 4'h1;
                    end
                    4'h3 : begin
                        if(D[7]==1) begin // T3 : register_reference
                            if (I == 0) begin
                                case (IR)
                                    CLA : begin AC <= 0; SC <= 0; end
                                    CLE : begin E <= 0; SC <= 0; end
                                    CMA : begin AC <= ~AC; SC <= 0; end
                                    CME : begin E <= ~E; SC <= 0; end
                                    CIR : begin AC <= AC >> 1; AC[15] <= E; E <= AC[0]; SC <= 0; end
                                    CIL : begin AC <= AC << 1; AC[0] <= E; E <= AC[15]; SC <= 0; end
                                    INC : begin AC <= AC + 16'h1; SC <= 0; end
                                    SPA : begin
                                        if (AC[15] == 0 ) begin
                                            PC <= PC + 12'h1;
                                            SC <= 0;
                                        end
                                        else
                                            SC <= 0;
                                    end
                                    SNA : begin
                                        if (AC[15] == 1 ) begin
                                            PC <= PC + 12'h1;
                                            SC <= 0;
                                        end
                                        else
                                            SC <= 0;
                                    end
                                    SZA : begin
                                        if (AC == 0 ) begin
                                            PC <= PC + 12'h1;
                                            SC <= 0;
                                        end
                                        else
                                            SC <= 0;
                                    end
                                    SZE : begin
                                        if (E == 0 ) begin
                                            PC <= PC + 12'h1;
                                            SC <= 0;
                                        end
                                        else
                                            SC <= 0;
                                    end
                                    MOV : begin S <= 0; SC <= 0; end
                                endcase
                                if (IR[15:8] == 8'h71) begin // LDC
                                    AC <= IR[7:0];
                                    SC <= 0;
                                end
                            end
                            if(I == 1) begin // io instruction
                                case(IR[11:0])
                                    12'h001 : begin //UART_tx_wirte
                                        io_req      <= 1'b1;
                                        io_addr     <= 32'h44A10000;
                                        io_wdata    <= AC;
                                        SC <= SC + 4'h1; 
                                    end
                                    12'h002 : begin // segment_write 
                                        io_req      <= 1'b1;
                                        io_addr     <= 32'h44A00000;
                                        io_wdata    <= AC;
                                        SC <= SC + 4'h1;
                                    end    
                                endcase
                            end    
                        end
                        else if (D[7] == 0) begin // T3 indirect ready
                            if(I == 1) begin
                                mem_req <= 1;
                                we <= 0;
                                mem_addr <= AR;
                                SC <= SC + 4'h1;
                            end
                            else
                                SC <= SC + 4'h1;
                        end
                    end
                    4'h4 : begin // T3 : indirect
                        if(D[7] == 0) begin
                            if(I == 1) begin
                                mem_req <= 0;
                                if(cpu_ready) begin
                                    AR <= mem_rdata;
                                    SC <= SC + 4'h1;
                                end
                                else begin
                                    SC <= SC; 
                                end
                            end
                            else
                                SC <= SC + 4'h1;
                        end
                        else if(D[7] && I == 1'b1) begin
                            io_req <= 1'b0;
                            if (cpu_ready) begin
                                SC <= 0;
                            end
                            else
                                SC <= SC;     
                        end    
                        else
                            SC <= SC + 4'h1;
                    end
                    4'h5 : begin // T4 ready
                        case (op)
                            3'h0,
                            3'h1,
                            3'h2,
                            3'h6 : begin
                                mem_addr <= AR;
                                mem_req <= 1;
                                we <= 0;
                                SC <= SC + 4'h1;
                            end
                            3'h3 : begin // STA1
                                mem_addr <= AR;
                                mem_wdata <= AC;
                                mem_req <= 1;
                                we <= 1;
                                SC <= SC + 4'h1;
                            end
                            3'h4 : begin //BUN
                                PC <= AR;
                                SC <= 4'h0;
                            end
                            3'h5 : begin // BSA1                                                       
                                mem_addr <= AR;
                                mem_wdata <= {4'h0,PC};
                                mem_req <= 1;
                                we <= 1;
                                SC <= SC + 4'h1;
                            end
                            default : SC <= 4'h0;
                        endcase
                    end
                    4'h6 : begin
                        case (op)
                            3'b000: begin // AR
                                mem_req <= 0;
                                if (cpu_ready) begin
                                    DR      <= mem_rdata;
                                    AC      <= AC & mem_rdata;
                                    SC      <= 4'h0;
                                end
                            end

                            3'b001: begin // ADD
                                mem_req <= 0;
                                if (cpu_ready) begin
                                    DR      <= mem_rdata;
                                    {E, AC} <= AC + mem_rdata;
                                    SC      <= 4'h0;
                                end
                            end

                            3'b010: begin // LDA
                                mem_req <= 0;
                                if (cpu_ready) begin
                                    DR      <= mem_rdata;
                                    AC      <= mem_rdata;
                                    SC      <= 4'h0;
                                end
                            end

                            3'b011: begin // STA
                                mem_req <= 0;
                                if (cpu_ready) begin
                                    we  <= 1'b0;
                                    SC      <= 4'h0;
                                end
                            end

                            3'b101: begin // BSA
                                mem_req <= 0;
                                if (cpu_ready) begin
                                    we  <= 1'b0;
                                    AR      <= AR + 12'h001;
                                    PC      <= AR + 12'h001;
                                    SC      <= 4'h0;
                                end
                            end

                            3'b110: begin // ISZ
                                mem_req <= 0;
                                if (cpu_ready) begin
                                    DR      <= mem_rdata + 16'h0001;
                                    SC      <= SC + 4'h1;
                                end
                            end

                            default: SC <= 4'h0;
                        endcase
                    end
                    4'h7 : begin
                        if(op == 3'h6) begin
                            mem_addr <= AR;
                            mem_wdata <= DR;
                            mem_req <= 1;
                            we <= 1;
                            SC <= SC + 4'h1;
                        end
                        else SC <= 4'h0;
                    end
                    4'h8 : begin
                        if(op == 3'h6) begin
                            mem_req <= 0;
                            if(cpu_ready) begin
                                we <= 0;
                                SC <= 4'h0;
                                if (DR == 16'h0000)
                                    PC <= PC + 12'h001;
                            end
                        end
                        else
                            SC <= 4'h0;
                    end
                    default : SC <= 4'h0;
                endcase
            end
        end
    end
endmodule
