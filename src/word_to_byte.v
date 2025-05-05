
module word_2_byte (
    input wire rst,
    input wire clk,
    input wire word_dv,
    input wire [15:0] word,
    output wire byte_dv,
    output wire [7:0] byteee
);

    reg word_dv_dly, word_dv_dly2;
    reg [15:0] word_reg;
    
    reg [7:0] s_byte;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            word_dv_dly <= 1'b0;
            word_dv_dly2 <= 1'b0;
            word_reg <= 16'b0;
        end 
        else 
        begin
            word_dv_dly <= word_dv;
            word_dv_dly2 <= word_dv_dly;
            word_reg <= word;
        end
    end

    always @(*) begin
        if (word_dv_dly) begin
            s_byte = word_reg[7:0];
        end 
        else if (word_dv_dly2) begin
            s_byte = word_reg[15:8];
        end
         else begin
            s_byte = 8'b0;
        end
    end
   
      assign byte_dv = word_dv_dly | word_dv_dly2;
      assign byteee = s_byte;
      
endmodule

