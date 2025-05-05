module CPU_Bootloader (
    input clk,                
    input rst,                
    input ce,                
    input scan_memory,       
    input rx,                 
    output tx                 
);

    
    wire [15:0] boot_ram_in;  
    wire [5:0] sig_adr, boot_ram_adr;
    wire carry, clear_carry, enable_mem, load_R1, load_accu, load_carry, w_mem;
    wire [2:0] sel_UAL_UT, sel_UAL_UC;
    //wire [15:0] ram_data_in;
    wire [15:0] ram_data_out, UT_data_out;
    wire sig_rw, sig_ram_enable;
    wire [5:0] sig_ram_adr;
    wire [15:0] sig_ram_in;
    wire boot, boot_ram_rw, boot_ram_enable;
    
  
    Control_Unit UC (
        .clk(clk),
        .ce(ce),
        .rst(rst),
        .carry(carry),
        .boot(boot),
        .data_in(ram_data_out),  
        .adr(sig_adr),
        .clear_carry(clear_carry),
        .enable_mem(enable_mem),
        .load_R1(load_R1),
        .load_accu(load_accu),
        .load_carry(load_carry),
        .sel_UAL(sel_UAL_UC),
        .w_mem(w_mem)
    );
    
    assign sel_UAL_UT = sel_UAL_UC;

    UT UT1 (
        .data_in(ram_data_out),  
        .clk(clk),
        .ce(ce),
        .rst(rst),
        .load_R1(load_R1),
        .load_accu(load_accu),
        .load_carry(load_carry),
        .init_carry(clear_carry),
        .sel_UAL(sel_UAL_UT),
        .data_out(UT_data_out),
        .carry(carry)
    );

    boot_loader BL (
        .rst(rst),
        .clk(clk),
        .ce(ce),
        .rx(rx),
        .tx(tx),
        .boot(boot),
        .scan_memory(scan_memory),
        .ram_out(ram_data_out),
        .ram_rw(boot_ram_rw),
        .ram_enable(boot_ram_enable),
        .ram_adr(boot_ram_adr),
        .ram_in(boot_ram_in)
    );

   
    assign sig_rw = (boot == 1'b1) ? boot_ram_rw : w_mem;
    assign sig_ram_enable = (boot == 1'b1) ? boot_ram_enable : enable_mem;
    assign sig_ram_adr = (boot == 1'b1) ? boot_ram_adr : sig_adr;
    assign sig_ram_in = (boot == 1'b1) ? boot_ram_in : UT_data_out;

   
    RAM_SP_64_8 UM (
        .add(sig_ram_adr),
        .data_in(sig_ram_in),
        .r_w(sig_rw),
        .enable(sig_ram_enable),
        .clk(clk),
        .ce(ce),
        .data_out(ram_data_out)  
    );

endmodule
