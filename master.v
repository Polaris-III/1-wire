
module master(output reg en, inout port, input clk, reset);
    reg [9:0] cnt;
    reg [7:0] mem;
    reg init = 0;
    reg data = 0;
    
    assign port = en ? data : 1'bz;
    
    always@(posedge reset) begin
        en <= 1;       
        cnt <= 0;
        mem <= 0;
        data <= 0;
    end
    always@(posedge clk) begin
        cnt <= cnt + 1;
        if (en) begin
            if (cnt > 50) begin
                en <= 0;
                cnt <= 0;
            end
        end
        else if(cnt > 50) begin
            mem <= mem << 1;
            mem[0] <= port;
            en <= 1;
        end
    end

endmodule
