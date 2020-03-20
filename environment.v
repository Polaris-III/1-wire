`timescale 1 ns / 1 ps
module env_slave;
    wire en;
    wire port;
    reg reset;
    reg clk = 1;
    reg [7:0] data = 8'b10101010;
    
    master lord(en, port, clk, reset);
    
    assign port = en ? 1'bz : data[0];
    
    always #5 clk = ~clk;
    
    always@(negedge en) begin
        data <= data >> 1;  
    end
      
    initial begin
        reset = 1;
        #5 reset = 0;    
    end

endmodule
