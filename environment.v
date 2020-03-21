`timescale 1 ns / 1 ps
module env_slave;
    wire en;
    wire port;
    reg tsm = 1;
    reg reset;
    reg clk = 1;
    reg [9:0] cnt = 0;
    reg [7:0] data = 8'b10101010;
    wire [7:0] mem;
    
    master lord(en, port, clk, reset, mem);
    
    assign port = en ? 1'bz : data[0];
    
    always #5 clk = ~clk;
    
    always@(negedge en) begin
        tsm <= 0;
        cnt <= 0;
    end
    always@(posedge clk) begin
        if(~en) begin
            
            end
        else begin
            if (~tsm) begin
                tsm <= 1;
                data <= data >> 1; 
            end
        end 
    end  
    initial begin
        reset = 1;
        #5 reset = 0;    
    end

endmodule
