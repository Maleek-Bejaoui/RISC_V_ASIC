//by nous
module uart_fifoed_send (
    input wire clk_100MHz,
    input wire reset,
    input wire dat_en,
    input wire [7:0] dat,
    output wire TX,
    output wire fifo_empty,
    output wire fifo_afull,
    output wire fifo_full
);

    reg [11:0] cnt;
    wire top;
    reg [8:0] shift;
    reg [3:0] nbbits;
    reg [11:0] read_index, write_index, n_elements;

    assign top = (cnt == 0);
    assign TX = shift[0];
    assign fifo_empty = (n_elements == 0);
    assign fifo_afull = (n_elements >= 2);
    assign fifo_full = (n_elements == 8) || 
                       (dat_en && nbbits < 12 && n_elements == 7);

    wire [7:0] fifo_dout;
    reg fifo_we;
    reg [7:0] fifo_din;

    // RAM-based FIFO instance
    fifo_ram_4k fifo_mem (
        .clk(clk_100MHz),
        .we(fifo_we),
        .addr_wr(write_index),
        .addr_rd(read_index),
        .din(fifo_din),
        .dout(fifo_dout)
    );

    always @(posedge clk_100MHz) begin
        if (reset) begin
            cnt <= 0;
        end else if (nbbits >= 12 || cnt == 0) begin
            cnt <= 867;
        end else begin
            cnt <= cnt - 1;
        end
    end

    always @(posedge clk_100MHz) begin
        if (reset) begin
            shift <= 9'b111111111;
            nbbits <= 12;
        end else if (nbbits >= 12) begin
            if (n_elements > 0) begin
                shift <= {fifo_dout, 1'b0}; // Start bit
                nbbits <= 9; // 8 data bits + stop bit
            end
        end else if (top) begin
            shift <= {1'b1, shift[8:1]}; // shift right with stop bit
            if (nbbits == 0)
                nbbits <= 15;
            else
                nbbits <= nbbits - 1;
        end
    end

    // FIFO read pointer
    always @(posedge clk_100MHz) begin
        if (reset) begin
            read_index <= 0;
        end else if ((n_elements > 0) && (nbbits >= 12)) begin
            read_index <= (read_index == 4095) ? 0 : read_index + 1;
        end
    end

    // FIFO element count
    always @(posedge clk_100MHz) begin
        if (reset) begin
            n_elements <= 0;
        end else if (dat_en && (n_elements < 8)) begin
            if (nbbits < 12 || n_elements == 0)
                n_elements <= n_elements + 1;
        end else if ((n_elements > 0) && (nbbits >= 12)) begin
            n_elements <= n_elements - 1;
        end
    end

    // FIFO write logic
    always @(posedge clk_100MHz) begin
        if (reset) begin
            write_index <= 0;
            fifo_we <= 0;
            fifo_din <= 8'd0;
        end else begin
            fifo_we <= 0;
            if (dat_en && (n_elements < 8)) begin
                fifo_din <= dat;
                fifo_we <= 1;
                write_index <= (write_index == 7) ? 0 : write_index + 1;
            end
        end
    end
endmodule
