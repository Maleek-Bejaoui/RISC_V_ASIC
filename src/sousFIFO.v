module fifo_ram_4k (
    input wire clk,
    input wire we,
    input wire [11:0] addr_wr,
    input wire [11:0] addr_rd,
    input wire [7:0] din,
    output reg [7:0] dout
);
    reg [7:0] mem [0:7];

    always @(posedge clk) begin
        if (we) begin
            mem[addr_wr] <= din;
        end
        dout <= mem[addr_rd];
    end
endmodule
