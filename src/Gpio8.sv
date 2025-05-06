// Compatible with Yosys and TinyTapeout
module Gpio8(
  input         clock,
  input         reset,
  input         io_b_mem_valid,
  input  [3:0]  io_b_mem_addr,
  input  [3:0]  io_b_mem_wen,
  input  [31:0] io_b_mem_wdata,
  output [31:0] io_b_mem_rdata,
  output [7:0]  io_b_gpio_eno,
  input  [7:0]  io_b_gpio_in,
  output [7:0]  io_b_gpio_out
);

  // Internal registers
  reg [7:0] r_eno;
  reg [7:0] r_in;
  reg [7:0] r_out;
  reg [7:0] r_rdata;

  // Constants (memory-mapped register addresses)
  localparam C_GPIO8_ENO = 4'h0;
  localparam C_GPIO8_IN  = 4'h4;
  localparam C_GPIO8_OUT = 4'h8;

  wire write_en = io_b_mem_valid && io_b_mem_wen[0];
  wire is_write_eno  = io_b_mem_addr == C_GPIO8_ENO;
  wire is_write_out  = io_b_mem_addr == C_GPIO8_OUT;

  // Sequential logic
  always @(posedge clock) begin
    if (reset) begin
      r_eno   <= 8'h00;
      r_out   <= 8'h00;
      r_in    <= 8'h00;
      r_rdata <= 8'h00;
    end else begin
      // Write
      if (write_en) begin
        if (is_write_eno)
          r_eno <= io_b_mem_wdata[7:0];
        else if (is_write_out)
          r_out <= io_b_mem_wdata[7:0];
      end

      // Read input
      r_in <= io_b_gpio_in;

      // Read logic (captured)
      case (io_b_mem_addr)
        C_GPIO8_ENO: r_rdata <= r_eno;
        C_GPIO8_IN:  r_rdata <= r_in;
        C_GPIO8_OUT: r_rdata <= r_out;
        default:     r_rdata <= 8'h00;
      endcase
    end
  end

  // Outputs
  assign io_b_mem_rdata = {24'h000000, r_rdata};  // padded to 32 bits
  assign io_b_gpio_eno  = r_eno;
  assign io_b_gpio_out  = r_out;

endmodule
