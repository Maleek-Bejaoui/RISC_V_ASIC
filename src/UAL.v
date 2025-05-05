module UAL (
    input wire [2:0] sel_UAL,
    input wire [15:0] DATA_R1,
    input wire [15:0] DATA_ACCU,
    output reg [15:0] DATA_OUT,
    output reg carry
);

reg signed [16:0] R1, ACCU;
reg signed [16:0] s_out;

always @(*) begin
    R1 = {1'b0, DATA_R1};  
    ACCU = {1'b0, DATA_ACCU}; 
    
    case (sel_UAL)
        3'b000: s_out = 17'b0;
        3'b010: s_out = R1 + ACCU;
        3'b011: s_out = ACCU - R1;
        default: s_out = 17'b0;
    endcase
end

always @(*) begin
    case (sel_UAL)
        3'b000: DATA_OUT = ~(DATA_R1 | DATA_ACCU);
        default: DATA_OUT = s_out[15:0];
    endcase
end

always @(*) begin
    case (sel_UAL)
        3'b000: carry = 1'b0;
        3'b010: carry = s_out[16];
        3'b011: carry = (ACCU < R1) ? 1'b1 : 1'b0;
        default: carry = 1'b0;
    endcase
end

endmodule
