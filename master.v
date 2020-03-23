
module master(output reg en, inout port, input clk, reset, output reg [31:0] mem, output reg init, output reg [9:0] cnt, output reg cycl, output reg rcvd);
    //output reg [9:0] cnt = 0;// Time counter
    //reg [31:0] mem = 0;      // Registry for received package
    //reg init = 0;            // Init flag(1 when no slave)
    reg [7:0] command;      // Command registry for transfer
    reg odata = 1;          // Data bit for transfer 
    reg idata = 1;          // Data bit for receive
    //reg rcvd = 0;           // Receive flag(1 when bit received)
    //reg cycl = 1;           // Time package flag(1 for pullup)
    reg pres = 1;           // Presence flag(1 when no slave)
    
    assign port = en ? odata : 1'bz;
    
    always@(posedge reset) begin
        en <= 1;
        cnt <= 0;
        rcvd <= 0;
        init <= 1;
        pres <= 1;
        idata <= 1;
        cycl = 1;
    end
   
    always@(posedge clk) begin
        cnt <= cnt + 1;
        if (en) begin               // Transmit
            if (cycl) begin         // Space between cycles
                odata <= 1;
                if (cnt > 4) begin 
                    cycl <= 0;
                    odata <= 0;
                    cnt <= 0;
                end
            end
            else if (init) begin     // RESET
                odata <= 0;
                if (cnt > 48) begin
                    cnt <= 0;
                    cycl <= 1;
                    init <= 0;
                    odata <= 1;
                end
            end
            else begin              // Normal mode(Receive data bit)
                if (cnt > 2) begin
                    en <= 0;
                    cnt <= 0;
                end
                else odata <= 0;
            end
        end 
        else begin                  // Receive
            if (pres) begin         // PRESENCE after RESET
                if ((cnt > 4) && ~rcvd) begin
                    idata <= port;
                    rcvd <= 1;
                end
                if (cnt > 6) begin
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
                if (cnt > 2) begin
                    idata <= port;
                end
                if (cnt > 4) begin
                    mem[0] <= idata;
                    mem <= mem << 1;
                    en <= 1;
                    cnt <= 0;
                    cycl <= 1;
                    odata <= 1;
                end
            end
        end
    end
endmodule
