
module master(output reg en, inout port, input clk, reset, output reg [7:0] mem, output reg init, output reg [31:0] cnt, output reg cycl, output reg rcvd, output reg idata);
    //output reg [9:0] cnt = 0;// Time counter
    //reg [31:0] mem = 0;      // Registry for received package
    //reg init = 0;            // Init flag(1 when no slave)
    reg [7:0] COMMAND_BYTE;      // Command registry for transfer
    reg [2:0] bitcnt = 0;   // Bit counter
    reg odata = 1;          // Data bit for transfer 
    //reg idata = 1;          // Data bit for receive
    //reg rcvd = 0;           // Receive flag(1 when bit received)
    //reg cycl = 1;           // Time package flag(1 for pullup)
    reg pres = 1;           // Presence flag(1 when no slave)
    reg READ = 0;           // READ command transfered(1 for reading)
    reg COMMAND = 0;        // COMMAND flag(1 for writing)
    reg trsd = 1;      // Transfered flag()
    //reg [2:0] COMMAND_BYTE_CNT = 3'b000;
     
    assign port = en ? odata : 1'bz;
    
    always@(posedge reset) begin
        en <= 1;
        cnt <= 0;
        rcvd <= 0;
        init <= 1;
        pres <= 1;
        idata <= 1;
        cycl <= 1;
        trsd <= 1;
        bitcnt <= 0;
        COMMAND <= 0;
        COMMAND_BYTE <= 8'b00110011;
    end
   
    always@(posedge clk) begin
        cnt <= cnt + 1;
        if (en) begin               // Transmit
            rcvd <= 0;
            if (cycl) begin         // Space between cycles
                odata <= 1;
                if (cnt > 2000) begin 
                    cycl <= 0;
                    trsd <= 1;
                    odata <= 0;
                    cnt <= 0;
                end
            end
            else if (init) begin     // RESET
                odata <= 0;
                if (cnt > 48000) begin
                    cnt <= 0;
                    cycl <= 1;
                    init <= 0;
                    odata <= 1;
                end
            end
            else begin              // Normal mode(Receive/Transmit data bit)
                if (cnt > 6000) begin
                    cycl <= 1;
                    cnt <= 0;
                end
                else begin 
                    if (cnt < 1500) odata <= 0;
                    else if (~COMMAND) begin
                        odata <= 1;
                        en <= 0;
                        cnt <= 0;
                    end
                    else begin
                        if (trsd) begin
                            odata = COMMAND_BYTE[bitcnt];
                            bitcnt = bitcnt + 1;
                            trsd <= 0;
                            //if (bitcnt == 0) COMMAND = 0;
                        end
                    end
                end
            end
        end 
        else begin                  // Receive
            if (pres) begin         // PRESENCE after RESET
                if ((cnt > 4000) && ~rcvd) begin
                    idata <= port;
                    rcvd <= 1;
                end
                if (cnt > 4500) begin
                    if (port == 0) begin
                        pres <= 0;
                    end
                    else init <= 1;
                    cnt <= 0;
                    en <= 1;
                    rcvd <= 0;
                    cycl <= 1;
                    odata <= 1;
                    COMMAND <= 1;
                end
            end
            else begin              // Normal mode(Receive data bit)
                if ((cnt > 1500) && ~rcvd) begin
                    mem[bitcnt] = port;
                    bitcnt = bitcnt + 1;
                    if (~bitcnt) COMMAND <= 1;
                    rcvd <= 1;
                end
                if (cnt > 4500) begin
                    en <= 1;
                    cnt <= 0;
                    cycl <= 1;
                    odata <= 1;
                end
            end
        end
    end
endmodule
