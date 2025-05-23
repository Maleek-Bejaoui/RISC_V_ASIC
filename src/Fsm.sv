// Generated by CIRCT firtool-1.62.0
module Fsm(
  input        clock,
               reset,
               io_i_bl,
  input  [1:0] io_i_seq,
  output       io_o_fetch,
               io_o_instr,
               io_o_decoder,
               io_o_alu,
               io_o_bru,
               io_o_mem_req,
               io_o_mem_ack,
               io_o_wb
);

  reg  [3:0] r_cstate;
  wire       _GEN = r_cstate == 4'h0;
  wire       _GEN_0 = r_cstate == 4'h1;
  wire       _GEN_1 = r_cstate == 4'h2;
  wire       _GEN_2 = r_cstate == 4'h3;
  wire       _GEN_3 = r_cstate == 4'h4;
  wire       _GEN_4 = r_cstate == 4'h6;
  wire       _GEN_5 = r_cstate == 4'h5;
  wire       _GEN_6 = _GEN_3 | _GEN_4;
  wire       _GEN_7 = r_cstate == 4'h7;
  wire       _GEN_8 = r_cstate == 4'h8;
  wire       _GEN_9 = r_cstate == 4'h9;
  always @(posedge clock) begin
    if (reset)
      r_cstate <= 4'h0;
    else if (_GEN)
      r_cstate <= {3'h0, ~io_i_bl};
    else if (_GEN_0)
      r_cstate <= 4'h2;
    else if (_GEN_1)
      r_cstate <= 4'h3;
    else if (_GEN_2)
      r_cstate <=
        io_i_seq == 2'h0
          ? 4'h4
          : io_i_seq == 2'h1 ? 4'h6 : {1'h0, io_i_seq == 2'h2, 2'h1};
    else if (_GEN_6)
      r_cstate <= 4'h9;
    else if (_GEN_5)
      r_cstate <= 4'h7;
    else if (_GEN_7)
      r_cstate <= 4'h8;
    else if (_GEN_8)
      r_cstate <= 4'h9;
    else
      r_cstate <= {3'h0, _GEN_9};
  end // always @(posedge)
  assign io_o_fetch = ~_GEN & _GEN_0;
  assign io_o_instr = ~(_GEN | _GEN_0) & _GEN_1;
  assign io_o_decoder = ~(_GEN | _GEN_0 | _GEN_1) & _GEN_2;
  assign io_o_alu = ~(_GEN | _GEN_0 | _GEN_1 | _GEN_2) & (_GEN_6 | _GEN_5);
  assign io_o_bru = ~(_GEN | _GEN_0 | _GEN_1 | _GEN_2 | _GEN_3) & _GEN_4;
  assign io_o_mem_req = ~(_GEN | _GEN_0 | _GEN_1 | _GEN_2 | _GEN_6) & (_GEN_5 | _GEN_7);
  assign io_o_mem_ack =
    ~(_GEN | _GEN_0 | _GEN_1 | _GEN_2 | _GEN_3 | _GEN_4 | _GEN_5 | _GEN_7) & _GEN_8;
  assign io_o_wb =
    ~(_GEN | _GEN_0 | _GEN_1 | _GEN_2 | _GEN_3 | _GEN_4 | _GEN_5 | _GEN_7 | _GEN_8)
    & _GEN_9;
endmodule

