module Prog_counter (
  input  [5:0] ADR_IN,
  input  clk,
  input  ce,
  input  rst,
  input carry,
  input  clear_PC,
  input  load_PC,
  input  enable_PC,
  output [5:0] ADR_OUT
);
  reg [5:0] s_adr_in;
  
  assign ADR_OUT = s_adr_in;

  always @(posedge clk or posedge rst)
    
    if (rst)
      s_adr_in <= 6'b000000;  // Reset immediat
    else if (ce) begin
      if (load_PC)
        s_adr_in <= ADR_IN;    // Chargement d'une adresse
      else if (enable_PC)
        s_adr_in <= clear_PC ? 6'b000000 : s_adr_in + 1;  // Effacement ou incrémentation
    end

endmodule

