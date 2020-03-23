`timescale 1 ns / 1 ps
module env_slave;
    wire en;    // Pullup emulation wire
    wire port;  
    
    wire [7:0] master_mem;  // Master registry for received package
    wire [9:0] master_cnt;  // Master counter
    wire master_init;       // Master init flag
    wire cycl;              // Master cycl flag
    wire rcvd;   // Master received flag
       
    reg reset = 0; // Master will RESET when reset signal rise
    reg clk = 1;
    
    reg [9:0] cnt = 0;                                          // Internal counter
    reg [31:0] mem = 32'b10101010_11111111_00000000_11001100;   // Data dword for transfer
    
    reg odata = 1;  // Data for transfer
    reg idata = 0;  // Data for receive
    reg pres = 0;   // Presence flag(1 when master RESET)
    reg trsm = 0;   // Transmition flag(0 when data bit transfered)
    
     
    master lord(en, port, clk, reset, master_mem, master_init, master_cnt, cycl, rcvd);
    
    assign port = en ? 1'bz : odata;
    
    always #5 clk = ~clk;
    
    always@(negedge en) begin
        cnt <= 0;
    end
    
    always@(posedge en) begin
        pres <= 0;
        trsm <= 1;
    end
    
    always@(posedge clk) begin
        cnt <= cnt + 1;
        if (en) begin               // Receive
            if (cnt > 40) begin     // RESET
                pres <= 1;
            end
        end
        else begin             // Transmit
            if (pres) begin    // PRESENCE
                odata <= 0;
            end
            else begin
                odata <= mem[0];
                if (trsm) mem <= mem >> 1;
                trsm <= 0;
            end
        end
    end  
    initial begin
        cnt <= 0;
        reset = 1;
        #5 reset = 0;    
    end

endmodule
