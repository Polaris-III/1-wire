`timescale 1 ns / 1 ps
module env_slave;
    wire port;  
    wire [7:0] MASTER_FLAGBYTE;
	wire M_IDATA;
	
    reg reset = 0; // Master will RESET when reset signal rise
    reg clk = 1;
    
    reg [7:0]  FLAGBYTE = 8'b1100_0000; // 7-EN, 6-CYCL, 5-COM, 4-INIT, 3-PRES, 2-RCVD, 1-TRNS, 0-LAST
	reg [31:0] COUNTER  = 0;
    reg [7:0]  CMD_BYTE = 0;
	reg [15:0] RC_DWORD = 0;
	reg [3:0]  OUT_CNT  = 0;
	reg [2:0]  IN_CNT   = 0;
	reg odata = 0;
	reg idata = 0;
	
    master lord(port, clk, reset, MASTER_FLAGBYTE, M_IDATA);
    
    assign port = FLAGBYTE[7] ? 1'bz : odata;
    
    always #5 clk = ~clk;
    
    always@(posedge clk) begin
        COUNTER <= COUNTER + 1;
        if (FLAGBYTE[7]) begin
            case (FLAGBYTE)
                8'b1100_0000 : begin
                    if (port) COUNTER <= 0;
                    else FLAGBYTE[6] <= 0;
                end
                8'b1000_0000 : begin
                    if (port) begin
                        FLAGBYTE[1] <= 1;
                        FLAGBYTE[7] <= 0;
                    end
                    else begin
                        if (COUNTER > 40000) begin
                            FLAGBYTE[4] <= 1;
                        end
                    end
                end
                8'b1001_0000 : begin
                    if (port) begin
                        FLAGBYTE[6] <= 1;
                        FLAGBYTE[4] <= 0;
                        FLAGBYTE[3] <= 1;
                    end
                end
                8'b1100_1000 : begin
                    if (port) COUNTER <= 0;
                    else begin
                        FLAGBYTE[7] <= 0;
                        FLAGBYTE[6] <= 0;
                    end
                end
                8'b1110_0000 : begin
                    if (port) COUNTER <= 0;
                    else begin
                        FLAGBYTE[6] <= 0;
                        FLAGBYTE[2] <= 1;
                    end
                end
                8'b1010_0100 : begin
                    if (COUNTER < 6000) begin
                        if (COUNTER == 2000) begin
                            idata <= port;
                        end
                    end
                    else begin
                        CMD_BYTE[IN_CNT] <= idata;
                        IN_CNT <= IN_CNT + 1;
                        FLAGBYTE[2] <= 0;
                        FLAGBYTE[6] <= 0;
                    end
                end
            endcase
        end
        else begin
            case (FLAGBYTE)
                8'b0000_0010 : begin
                    if (COUNTER < 6000) begin
                        odata <= RC_DWORD[OUT_CNT];
                    end
                    else begin
                        FLAGBYTE[7] <= 1;
                        FLAGBYTE[6] <= 1;
                        FLAGBYTE[1] <= 0;
                    end
                end
                8'b0000_1000 : begin
                    if (COUNTER < 4000) begin
                        odata <= 0;
                    end
                    else begin
                        FLAGBYTE[7] <= 1;
                        FLAGBYTE[6] <= 1;
                        FLAGBYTE[5] <= 1;
                        FLAGBYTE[3] <= 0;
                    end
                end
            endcase
        end
    end  
    initial begin
        COUNTER <= 0;
        reset = 1;
        #5 reset = 0;    
    end

endmodule
