module RAM_SP_64_8 (
    input [5:0] add,        
    input [15:0] data_in,   
    input r_w,             
    input enable,           
    input clk,             
    input ce,               
    output reg [15:0] data_out 
);

    reg [15:0] memory [0:63];  // RAM de 64 mots de 16 bits

    always @(posedge clk) begin
        if (ce) begin
            if (enable) begin
                if (r_w == 1'b0) begin 
                    data_out <= memory[add];
                end else begin 
                    memory[add] <= data_in;
                end
            end
        end
    end

endmodule
