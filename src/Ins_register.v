module Ins_register (
  input  clk,
  input  rst,
  input  ce,
  input  [15:0] data,
  input  load_RI,
  output [2:0] code_op,
  output [5:0] ADR_RI
);
  reg [15:0] s_data; // Registre d'instruction

  assign code_op = s_data[15:13]; // Extraction du code opération
  assign ADR_RI  = s_data[5:0];   // Extraction de l'adresse

  always @(posedge clk or posedge rst)
    if (rst)
      s_data <= 16'b0;
    else if (load_RI & ce) 
      s_data <= data;

endmodule
