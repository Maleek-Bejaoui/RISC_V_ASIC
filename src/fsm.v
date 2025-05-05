module fsm (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire [2:0] code_op,
    input wire carry,
    input wire boot,
    output reg clear_PC,
    output reg enable_PC,
    output reg load_PC,
    output reg load_RI,
    output reg sel_ADR,
    output reg load_R1,
    output reg load_ACCU,
    output reg [2:0] sel_UAL,
    output reg clear_carry,
    output reg load_carry,
    output reg enable_mem,
    output reg W_mem
);

    // State encoding
    localparam [3:0] 
        INIT = 4'd0,
        FETCH_INS = 4'd1,
        FETCH_INS_DLY = 4'd2,
        DECODE = 4'd3,
        FETCH_OP = 4'd4,
        FETCH_OP_DLY = 4'd5,
        EXE_NOR_ADD = 4'd6,
        EXE_JCC = 4'd7,
        STORE = 4'd8,
        STORE_DLY = 4'd9;

    reg [3:0] current_state, next_state;

    // State register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= INIT;
        end else if (ce) begin
            if (boot) begin
                current_state <= INIT;
            end else begin
                current_state <= next_state;
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            INIT: next_state = boot ? INIT : FETCH_INS;
            FETCH_INS: next_state = FETCH_INS_DLY;
            FETCH_INS_DLY: next_state = DECODE;
            DECODE: begin
                if (code_op == 3'b100) next_state = STORE;
                else if (code_op == 3'b110) next_state = EXE_JCC;
                else if (code_op == 3'b000 || code_op == 3'b010 || code_op == 3'b011) next_state = FETCH_OP;
                else next_state = DECODE; // Default case
            end
            STORE: next_state = STORE_DLY;
            STORE_DLY: next_state = FETCH_INS;
            EXE_JCC: next_state = FETCH_INS;
            FETCH_OP: next_state = FETCH_OP_DLY;
            FETCH_OP_DLY: next_state = EXE_NOR_ADD;
            EXE_NOR_ADD: next_state = FETCH_INS;
            default: next_state = INIT; // Default case
        endcase
    end

    // Output logic
    always @(*) begin
        case (current_state)
            INIT: begin
                clear_PC = 1'b1; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b0; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b1; load_carry = 1'b0; enable_mem = 1'b0; W_mem = 1'b0;
            end
            FETCH_INS: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b0; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b1; W_mem = 1'b0;
            end
            FETCH_INS_DLY: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b1;
                sel_ADR = 1'b0; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b1; W_mem = 1'b0;
            end
            DECODE: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b1; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b0; W_mem = 1'b0;
            end
            FETCH_OP: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b1; load_R1 = 1'b1; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b1; W_mem = 1'b0;
            end
            FETCH_OP_DLY: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b1; load_R1 = 1'b1; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b0; W_mem = 1'b0;
            end
            EXE_NOR_ADD: begin
                clear_PC = 1'b0; enable_PC = 1'b1; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b1; load_R1 = 1'b0; load_ACCU = 1'b1; sel_UAL = code_op;
                clear_carry = 1'b0; load_carry = code_op[1]; enable_mem = 1'b0; W_mem = 1'b0;
            end
            EXE_JCC: begin
                clear_PC = 1'b0; enable_PC = carry; load_PC = ~carry; load_RI = 1'b1;
                sel_ADR = 1'b1; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = carry; load_carry = 1'b0; enable_mem = 1'b0; W_mem = 1'b0;
            end
            STORE: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b1; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b1; W_mem = 1'b1;
            end
            STORE_DLY: begin
                clear_PC = 1'b0; enable_PC = 1'b1; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b1; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b1; W_mem = 1'b0;
            end
            default: begin
                clear_PC = 1'b0; enable_PC = 1'b0; load_PC = 1'b0; load_RI = 1'b0;
                sel_ADR = 1'b0; load_R1 = 1'b0; load_ACCU = 1'b0; sel_UAL = 3'b111;
                clear_carry = 1'b0; load_carry = 1'b0; enable_mem = 1'b0; W_mem = 1'b0;
            end
        endcase
    end

endmodule
