
 module master(inout port, input clk, reset, output reg [7:0] FLAGBYTE, output reg idata);
	reg [15:0] RC_DWORD = 0;			//	FLAGBYTE legend
	reg [7:0]  CMD_BYTE = 8'h44;	    //	7 EN
	reg [31:0] COUNTER  = 0;			//	6 CYCL
    //reg [7:0]  FLAGBYTE = 8'b11111000;//	5 COMMAND
	reg [3:0]  IN_CNT   = 0;			//	4 INIT
	reg [2:0]  OUT_CNT  = 0;			//	3 <RESERVED>
	reg odata;							//	2 RECEIVED
	//reg idata;						//	1 TRANSMITTED
										//	0 <RESERVED>
    reg [2:0] CMD_SEL = 111;            //  COMMAND SELECTOR
                                        //  111 44h
                                        //  110 BEh
    assign port = FLAGBYTE[7] ? odata : 1'bz;
    
    always@(posedge reset) begin
        FLAGBYTE <= 8'b1111_0000;
		COUNTER <= 0;
		OUT_CNT <= 0;
		IN_CNT <= 0;
		odata <= 1;
		idata <= 1;
    end
   
    always@(posedge clk) begin
        COUNTER <= COUNTER + 1;
		if (FLAGBYTE[7]) begin
			case (FLAGBYTE)
				8'b1111_0000 : begin			// Cycl, reset
					if (COUNTER < 100) begin
						odata <= 1;
					end
					else begin
						COUNTER <= 0;
						FLAGBYTE[6] <= 0;
						idata <= 1;
						odata <= 0;
					end
				end
				8'b1111_1000 : begin			// Cycl after reset
					if (COUNTER < 100) begin
						odata <= 1;
					end
					else begin
					    FLAGBYTE[2] <= 1;
					    FLAGBYTE[4] <= 0;
					    FLAGBYTE[5] <= 0;
						FLAGBYTE[6] <= 0;
						FLAGBYTE[7] <= 0;
						COUNTER <= 0;
						odata <= 0;
					end
				end
				8'b1100_0000 : begin            // Cycl before receiving
				    if (COUNTER < 100) begin
						odata <= 1;
					end
					else FLAGBYTE[6] <= 0;
				end
				8'b1110_0000 : begin            // Normal cycl before transmitting
				    if (COUNTER < 100) begin
						odata <= 1;
					end
					else FLAGBYTE[6] <= 0;
				end
				8'b1011_0000 : begin			// Cycl ended, reset
					if (COUNTER < 48000) odata <= 0;
					else begin
						FLAGBYTE[6] <= 1;
						FLAGBYTE[3] <= 1;
						COUNTER <= 0;
					end
				end
				8'b1010_0000 : begin			// Fall before transmitting
					if (COUNTER < 1500) odata <= 0;
					else begin
						FLAGBYTE[1] <= 1;
						COUNTER <= 0;
					end
				end
				8'b1000_0000 : begin			// Fall before receiving
					if (COUNTER < 1500) odata <= 0;
					else begin
						odata <= 1;
						COUNTER <= 0;
						FLAGBYTE[7] <= 0;
						FLAGBYTE[2] <= 1;
					end
				end
				8'b1010_0010 : begin			// Transmit after cycl
					if (COUNTER < 4500) odata <= CMD_BYTE[OUT_CNT];
					else begin
						FLAGBYTE[1] <= 0;
						FLAGBYTE[6] <= 1;
						COUNTER <= 0;
						OUT_CNT = OUT_CNT + 1;
						if (OUT_CNT == 0) begin
						    if (CMD_SEL == 3'b110) begin
						        CMD_BYTE <= 8'h44;
						        CMD_SEL <= 3'b111;
						        FLAGBYTE[5] <= 0;
						    end
						    else begin 
						        CMD_BYTE <= 8'hBE;
						        CMD_SEL <= 3'b110;
						    end
						end
					end
				end
				8'b1111_1111 : begin
					COUNTER <= 0;
				end
				default : FLAGBYTE <= 8'b1111_1000;
			endcase
		end
		else begin
			case (FLAGBYTE)
				8'b0000_0100 : begin			// Receiving		
					if (COUNTER < 4500) idata <= port;
					else begin
					    FLAGBYTE[2] <= 0;
						FLAGBYTE[6] <= 1;
						FLAGBYTE[7] <= 1;
						COUNTER <= 0;
						RC_DWORD[IN_CNT] <= idata;
						IN_CNT = IN_CNT + 1;
						if (IN_CNT == 0) FLAGBYTE <= 8'b1111_1111;
					end
				end
				8'b0000_1100 : begin			// PRESENCE searching
					if (COUNTER > 6000) begin
						FLAGBYTE[7] <= 1;
						FLAGBYTE[6] <= 1;
						FLAGBYTE[5] <= 1;
						if (idata) begin
						    FLAGBYTE[4] <= 1;
						end
						FLAGBYTE[3] <= 0;
						FLAGBYTE[2] <= 0;
						COUNTER <= 0;
					end
					else if (COUNTER == 2000) begin
					   idata <= port;
					end
				end
			endcase
		end
    end
endmodule
