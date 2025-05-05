


module Control_Unit (
    input wire clk,
    input wire ce,
    input wire rst,
    input wire carry,
    input wire boot,
    input wire [15:0] data_in,
    output wire [5:0] adr,
    output wire clear_carry,
    output wire enable_mem,
    output wire load_R1,
    output wire load_accu,
    output wire load_carry,
    output wire [2:0] sel_UAL,
    output wire w_mem
);

    wire [2:0] code_op;
    wire clear_PC;
    wire enable_PC;
    wire load_PC;
    wire load_RI;
    wire sel_ADR;
    wire [5:0] ADR_RI;
    wire [5:0] ADR_OUT;
    wire [5:0] sig_adr;

    fsm P_FSM (
        .clk(clk),
        .ce(ce),
        .rst(rst),
        .code_op(code_op),
        .carry(carry),
        .boot(boot),
        .clear_PC(clear_PC),
        .enable_PC(enable_PC),
        .load_PC(load_PC),
        .load_RI(load_RI),
        .sel_ADR(sel_ADR),
        .load_R1(load_R1),
        .load_ACCU(load_accu),
        .sel_UAL(sel_UAL),
        .clear_carry(clear_carry),
        .load_carry(load_carry),
        .enable_mem(enable_mem),
        .W_mem(w_mem)
    );

    Prog_counter PC (
        .ADR_IN(ADR_RI),
        .ADR_OUT(ADR_OUT),
        .clk(clk),
        .ce(ce),
        .carry(carry),
        .rst(rst),
        .clear_PC(clear_PC),
        .load_PC(load_PC),
        .enable_PC(enable_PC)
    );

    Ins_register RI (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .data(data_in),
        .load_RI(load_RI),
        .code_op(code_op),
        .ADR_RI(ADR_RI)
    );

    assign sig_adr = sel_ADR ? ADR_RI : ADR_OUT;
    assign adr = sig_adr;

endmodule
