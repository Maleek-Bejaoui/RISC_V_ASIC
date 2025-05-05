
module byte_2_word (
    input wire rst,            
    input wire clk,            
    input wire ce,             
    input wire byte_dv,        
    input wire [7:0] byteee,     
    output reg word_dv,        
    output reg [15:0] word     
);
    
    reg [7:0] byte_reg, byte_reg2;  // Registers to hold the bytes
    reg byte_dv_dly;                // Delayed byte valid signal
    reg [1:0] byte_count;           // Counter for byte count

    // Process for storing the byte values
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_reg <= 8'b0;
            byte_reg2 <= 8'b0;
        end else if (ce) begin
            if (byte_dv) begin
                byte_reg <= byteee;
                byte_reg2 <= byte_reg;
            end
        end
    end

    // Process for delaying the byte_dv signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_dv_dly <= 1'b0;
        end else if (ce) begin
            byte_dv_dly <= byte_dv;
        end
    end

    // Process for counting the number of bytes
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            byte_count <= 2'b00;
        end else if (ce) begin
            if (byte_dv) begin
                byte_count <= byte_count + 1;
            end
        end
    end

    // Word valid logic
    always @(*) begin
        if (byte_count[0] == 0 && byte_dv_dly == 1'b1) begin
            word_dv = 1'b1;
        end else begin
            word_dv = 1'b0;
        end
    end

    // Word formation
    always @(*) begin
        word = {byte_reg, byte_reg2};
    end

endmodule

