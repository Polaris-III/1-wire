
module master(output reg en, inout port, input clk, reset, output reg [7:0] mem, output reg init, output reg [31:0] cnt, output reg cycl, output reg rcvd, output reg idata);
    //output reg [9:0] cnt = 0;// Time counter
    //reg [31:0] mem = 0;      // Registry for received package
    //reg init = 0;            // Init flag(1 when no slave)
    reg [7:0] command;      // Command registry for transfer
    reg [2:0] bitcnt = 0;   // Bit counter
    reg odata = 1;          // Data bit for transfer 
    //reg idata = 1;          // Data bit for receive
    //reg rcvd = 0;           // Receive flag(1 when bit received)
    //reg cycl = 1;           // Time package flag(1 for pullup)
    reg pres = 1;           // Presence flag(1 when no slave)
    reg READ = 0;           // READ command transfered(1 for reading)
     
    assign port = en ? odata : 1'bz;
    
    always@(posedge reset) begin
        en <= 1;
        cnt <= 0;
        rcvd <= 0;
        init <= 1;
        pres <= 1;
        idata <= 1;
        cycl <= 1;
        bitcnt <= 0;
    end
   
    always@(posedge clk) begin
        cnt <= cnt + 1;
        if (en) begin               // Transmit
            rcvd <= 0;
            if (cycl) begin         // Space between cycles
                odata <= 1;
                if (cnt > 2000) begin 
                    cycl <= 0;
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
            else begin              // Normal mode(Receive data bit)
                if (cnt > 1500) begin
                    odata <= 1;
                    en <= 0;
                    cnt <= 0;
                end
                else odata <= 0;
            end
        end 
        else begin                  // Receive
            if (pres) begin         // PRESENCE after RESET
                if ((cnt > 4000) && ~rcvd) begin
                    idata <= port;
                    rcvd <= 1;
                end
                if (cnt > 4500) begin
                    if (idata == 0) pres <= 0;
                    else init <= 1;
                    cnt <= 0;
                    en <= 1;
                    rcvd <= 0;
                    cycl <= 1;
                    odata <= 1;
                end
            end
            else begin              // Normal mode(Receive data bit)
                if ((cnt > 1500) && ~rcvd) begin
                    mem[bitcnt] <= port;
                    bitcnt <= bitcnt + 1;
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
