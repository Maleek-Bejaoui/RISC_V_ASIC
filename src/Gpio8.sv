module Gpio8 (
    input logic clk,
    input logic rst,

    input logic        i_mem_valid,
    input logic [1:0]  i_mem_addr,  // N_GPIO8_BIT = 2 → 2 bits
    input logic        i_mem_wen,   // un seul bit d'écriture suffisant
    input logic [31:0] i_mem_wdata, // N_DATA_BYTE = 4 → 32 bits

    output logic        o_mem_ready,
    output logic [31:0] o_mem_rdata,

    output logic [7:0] o_gpio_eno,
    input  logic [7:0] i_gpio_in,
    output logic [7:0] o_gpio_out
);

    // Adresse mappée en dur
    localparam int C_GPIO8_ENO = 0;
    localparam int C_GPIO8_IN  = 1;
    localparam int C_GPIO8_OUT = 2;

    logic [7:0] r_eno, r_in, r_out;
    logic [7:0] r_rdata;
    logic [7:0] s_rdata, s_eno, s_out;

    assign o_mem_ready = 1'b1;
    assign o_mem_rdata = {24'b0, r_rdata}; // 8 bits de données utiles

    assign o_gpio_eno  = r_eno;
    assign o_gpio_out  = r_out;

    // Lecture combinatoire
    always_comb begin
        case (i_mem_addr)
            C_GPIO8_ENO: s_rdata = r_eno;
            C_GPIO8_IN:  s_rdata = r_in;
            C_GPIO8_OUT: s_rdata = r_out;
            default:     s_rdata = r_rdata;
        endcase
    end

    // Écriture combinatoire
    always_comb begin
        if (i_mem_valid && i_mem_wen) begin
            case (i_mem_addr)
                C_GPIO8_ENO: begin
                    s_eno = i_mem_wdata[7:0];
                    s_out = r_out;
                end
                C_GPIO8_OUT: begin
                    s_eno = r_eno;
                    s_out = i_mem_wdata[7:0];
                end
                default: begin
                    s_eno = r_eno;
                    s_out = r_out;
                end
            endcase
        end else begin
            s_eno = r_eno;
            s_out = r_out;
        end
    end

    // Processus séquentiel
    always_ff @(posedge clk) begin
        if (rst) begin
            r_eno   <= 8'b0;
            r_in    <= 8'b0;
            r_out   <= 8'b0;
            r_rdata <= 8'b0;
        end else begin
            r_eno   <= s_eno;
            r_out   <= s_out;
            r_in    <= i_gpio_in;
            r_rdata <= s_rdata;
        end
    end

endmodule
