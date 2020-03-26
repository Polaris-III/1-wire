`timescale 1 ns / 1 ps
module env_slave;
    wire en;    // Pullup emulation wire
    wire port;  
    
    wire [7:0] master_mem;  // Master registry for received package
    wire [31:0] master_cnt; // Master counter
    wire master_init;       // Master init flag
    wire master_cycl;       // Master cycl flag
    wire master_rcvd;       // Master received flag
    wire master_idata;
       
    reg reset = 0; // Master will RESET when reset signal rise
    reg clk = 1;
    
    reg en_slv = 1;         // Slave enable flag(1 when listening)
    reg [31:0] cnt = 0;                                          // Internal counter
    reg [2:0] bitcnt = 0;
    reg [7:0] mem = 8'b10101010;//_11111111_00000000_11001100;   // Data dword for transfer
    reg [7:0] cmnd_mem = 0;     // Command registry
    
    reg odata = 1;  // Data for transfer
    reg idata;      // Data for receive
    reg pres = 0;   // Presence flag(1 when master RESET)
    reg trsm = 1;   // Transmition flag(0 when data bit transfered)
    reg rcvd = 0;   // Received flag(0 when data bit received)
    reg cycl = 1;   // 
    reg READ = 0;   // READ command 
    reg nullc = 1;  // NULL cnt
    reg COMMAND = 0;// COMMAND flag
    reg [7:0] COMMAND_BYTE = 8'b00000000; // Registry for received master command 
    reg [2:0] COMMAND_BYTE_CNT = 3'b000;
     
    master lord(en, port, clk, reset, master_mem, master_init, master_cnt, master_cycl, master_rcvd, master_idata);
    
    assign port = en_slv ? 1'bz : odata;
    
    always #5 clk = ~clk;
    
    always@(posedge clk) begin
        /*if (nullc) begin
            cnt <= 0;
            nullc <= 0;
        end*/
        cnt <= cnt + 1;
        if (en_slv) begin
            if (~port) begin
                if (cnt > 12000) begin 
                    cycl <= 1;
                    pres <= 1;
                end
                else if (cycl) cycl <= 0;
            end
            else begin
                cnt <= 0;
                if (~cycl) begin
                    if (~COMMAND)
                        en_slv <= 0;
                end
                else begin
                    if (cnt > 6000) begin
                        cnt <= 0;
                        cycl <= 1;
                    end
                    else begin
                        if ((cnt > 3000) && rcvd) begin
                            COMMAND_BYTE[COMMAND_BYTE_CNT] = port;
                            COMMAND_BYTE_CNT = COMMAND_BYTE_CNT + 1;
                            if (COMMAND_BYTE_CNT == 0) COMMAND <= 0;
                            rcvd <= 0;
                        end
                    end
                end
            end
        end
        else begin
            cycl <= 1;
            if (cnt < 4500) begin
                if (pres) begin
                    odata <= 0;
                    COMMAND <= 1;
                end
                else if (trsm) begin
                    trsm <= 0;
                    odata = mem[bitcnt];
                    bitcnt = bitcnt + 1;
                end
            end
            else begin
                pres <= 0;
                en_slv <= 1;
                trsm <= 1;
                cnt <= 0;
            end
        end
    end  
    initial begin
        cnt <= 0;
        reset = 1;
        #5 reset = 0;    
    end

endmodule
