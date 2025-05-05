module Carry_register (
    input wire clk,
    input wire rst,
    input wire ce,
    input wire load_carry,
    input wire clear_carry,
    input wire carry_in,
    output reg carry_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        carry_out <= 1'b0;
    end else if (ce) begin
        if (load_carry) begin
            carry_out <= carry_in;
        end else if (clear_carry) begin
            carry_out <= 1'b0;
        end
    end
end

endmodule
