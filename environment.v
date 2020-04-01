`timescale 1 ns / 1 ps
module env_slave;
    wire port;  
    wire [7:0] M_FLAGBYTE;
    wire [15:0] M_DWORD;
	
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
	
    master lord(port, clk, reset, M_FLAGBYTE, M_DWORD);
    
    assign port = FLAGBYTE[7] ? 1'bz : odata;
    
    always #5 clk = ~clk;
    
    always@(posedge clk) begin
        COUNTER <= COUNTER + 1;
        if (FLAGBYTE[7]) begin
            if (FLAGBYTE[6]) begin
                if (port) begin
                    if (COUNTER > 1000) begin
                        FLAGBYTE[5] <= 0;
                    end 
                end
                else begin
                    COUNTER <= 0;
                    FLAGBYTE[6] <= 0;
                end
            end
            else begin
                if (port) begin
                    if (COUNTER > 40000) begin
                        COUNTER <= 0;
                        CMD_BYTE <= 0;
                        OUT_CNT <= 0;
                        IN_CNT <= 0;
                        FLAGBYTE[6] <= 1;
                        FLAGBYTE[4] <= 1;
                    end
                    else begin
                        if (FLAGBYTE[5]) begin
                            if (COUNTER < 6000) begin
                                if (COUNTER == 4000) idata <= port;
                                if (COUNTER == 4050) begin
                                    CMD_BYTE[IN_CNT] <= idata;
                                    IN_CNT = IN_CNT + 1;
                                end
                            end
                            else begin
                                if (IN_CNT == 0) begin
                                    if (CMD_BYTE == 8'h44) begin
                                        FLAGBYTE[5] <= 1;
                                        RC_DWORD <= 16'hFFCE;    
                                    end
                                    if (CMD_BYTE == 8'hBE) begin 
                                        FLAGBYTE[5] <= 0; 
                                    end
                                end
                                FLAGBYTE[6] <= 1;
                                COUNTER <= 0;
                            end
                        end
                        else begin
                            FLAGBYTE[7] <= 0;
                            COUNTER <= 0;
                        end
                    end
                end
                else begin
                    if (FLAGBYTE[4]) FLAGBYTE[7] <= 0;
                    if (FLAGBYTE[5]) begin
                         if (COUNTER < 6000) begin
                            if (COUNTER == 4000) idata <= port;
                            if (COUNTER == 4050) begin
                                CMD_BYTE[IN_CNT] <= idata;
                                IN_CNT = IN_CNT + 1;
                            end
                        end
                        else begin
                           if (IN_CNT == 0) begin
                                if (CMD_BYTE == 8'h44) begin
                                    FLAGBYTE[5] <= 1;
                                    RC_DWORD <= 16'hABCD;    
                                end
                                if (CMD_BYTE == 8'hBE) begin 
                                    FLAGBYTE[5] <= 0;
                                end
                            end
                            FLAGBYTE[6] <= 1;
                            COUNTER <= 0;
                        end
                    end
                end
            end
        end
        else begin
            if (FLAGBYTE[4] == 1) begin
                if (COUNTER < 6000) begin
                    odata <= 0;
                end
                else begin
                    FLAGBYTE[4] <= 0;
                    FLAGBYTE[5] <= 1;
                    FLAGBYTE[6] <= 1;
                    FLAGBYTE[7] <= 1;
                    COUNTER <= 0;
                end
            end
            else begin
                if (~FLAGBYTE[5]) begin
                    if (COUNTER < 4500) begin
                        odata <= RC_DWORD[OUT_CNT];
                    end
                    else begin
                        FLAGBYTE[7] <= 1;
                        FLAGBYTE[6] <= 1;
                        COUNTER <= 0;
                        OUT_CNT <= OUT_CNT + 1;
                    end
                end
            end
        end
    end  
    initial begin
        COUNTER <= 0;
        reset = 1;
        #5 reset = 0;  
        #4_000_000 reset = 1;
        #5 reset = 0;
    end

endmodule
