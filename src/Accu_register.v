module Accu_register (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire load_accu,
    input wire [15:0] DATA_IN,
    output reg [15:0] DATA_OUT
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        DATA_OUT <= 16'b0;
    end else if (ce) begin
        if (load_accu) begin
            DATA_OUT <= DATA_IN;
        end
    end
end

endmodule

