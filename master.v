
module master(output reg en, inout port, input clk, reset, output reg [7:0] mem);
    reg [9:0] cnt = 0;
    //reg [7:0] mem = 0;
    reg init = 0;
    reg data = 1;
    reg rd = 0;
    assign port = en ? data : 1'bz;
    
    always@(posedge reset) begin
        rd <= 0;
        en <= 1;       
        cnt <= 0;
        //mem <= 0;
        data <= 1;
        init <= 0;
    end
    always@(posedge clk) begin
        cnt <= cnt + 1;
        if (en) begin
            //rd <= 0;
            /*if (~init) begin
                if (cnt > 480) begin
                    en <= 0;
                    cnt <= 0;
                end
            end*/
            if (cnt > 15) begin
                en <= 0;
            end
            else data <= 0;
        end
        else begin
            if((cnt > 30) && ~rd) begin
                mem <= mem << 1;
                mem[0] <= port;
                rd <= 1;
            end
            if (cnt > 45) begin
                data <= 1;
                en <= 1;
                cnt <= 0;
                rd <= 0;
            end
        end
    end

endmodule
