module R1_register (
    input wire clk,
    input wire rst,
    input wire ce,
    input wire load_R1,
    input wire [15:0] data_mem,
    output reg [15:0] data_UAL
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_UAL <= 16'b0;
    end else if (ce) begin
        if (load_R1) begin
            data_UAL <= data_mem;
        end
    end
end

endmodule
