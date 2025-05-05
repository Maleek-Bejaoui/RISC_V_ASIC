module UT (
    input wire clk,
    input wire rst,
    input wire ce,
    input wire [2:0] sel_UAL,
    output wire carry,
    input wire [15:0] data_in,
    output wire [15:0] data_out,
    input wire load_R1,
    input wire load_accu,
    input wire load_carry,
    input wire init_carry
);

    // Déclarations des signaux internes
    wire [15:0] R1_out, UAL_out, ACCU_out;
    wire carry_in;

    // Instanciation des composants
    R1_register uut3 (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .load_R1(load_R1),
        .data_mem(data_in),
        .data_UAL(R1_out)
    );

    UAL uut2 (
        .sel_UAL(sel_UAL),
        .DATA_R1(R1_out),
        .DATA_ACCU(ACCU_out),
        .DATA_OUT(UAL_out),
        .carry(carry_in)
    );

    Carry_register uut1 (
        .clk(clk),
        .rst(rst),
        .ce(ce),
        .load_carry(load_carry),
        .clear_carry(init_carry),
        .carry_in(carry_in),
        .carry_out(carry)
    );

    Accu_register uut0 (
        .clk(clk),
        .ce(ce),
        .rst(rst),
        .load_accu(load_accu),
        .DATA_IN(UAL_out),
        .DATA_OUT(ACCU_out)
    );

    // Processus assignant la sortie finale data_out
    assign data_out = ACCU_out;

endmodule
