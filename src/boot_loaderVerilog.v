
module boot_loader (
    input  wire          rst,
    input  wire          clk,
    input  wire          ce,
    input  wire          rx,
    output wire          tx,
    output reg           boot,
    input  wire          scan_memory,
    input  wire [15:0]   ram_out,
    output reg           ram_rw,
    output reg           ram_enable,
    output reg  [5:0]    ram_adr,
    output reg  [15:0]   ram_in
);

    wire [7:0] rx_byte;
    wire       rx_data_valid;       // dat_en venant du UART_recv
    wire [7:0] tx_byte;
    wire       tx_word_valid;       // sortie de word_2_byte
    wire       rx_word_valid;       // sortie de byte_2_word -> mot complet reçu
    reg  [5:0] rx_byte_count;       // compteur d'adresse RAM pour l'écriture
    reg        enable_rx_byte_counter;
    reg        init_byte_counter;
    
    // ram_in doit recevoir le mot complet en provenance du byte_2_word
    wire [15:0] rx_word;

    // Pour le cycle d’attente 8K
    reg  [14:0] tx_cycle_count;
    reg         init_tx_cycle_count;
    reg         tx_cycle_count_over;  // indique la fin de 8K cycles

    reg         tx_data_valid;  // signal interne, piloté par la FSM

 
    UART_recv inst_uart_recv (
        .clk   (clk),
        .reset (rst),
        .rx    (rx),
        .dat   (rx_byte),
        .dat_en(rx_data_valid)
    );

    /* verilator lint_off PINCONNECTEMPTY */
    uart_fifoed_send inst_uart_send (
        .clk_100MHz (clk),
        .reset      (rst),
        .dat_en     (tx_word_valid),  // mot converti en bytes (word_2_byte)
        .dat        (tx_byte),
        .TX         (tx),
        .fifo_empty (),
        .fifo_afull (),
        .fifo_full  ()
    );
/* verilator lint_off PINCONNECTEMPTY */
    byte_2_word b2w (
        .rst      (rst),
        .clk      (clk),
        .ce       (ce),
        .byte_dv  (rx_data_valid),
        .byteee     (rx_byte),
        .word_dv  (rx_word_valid),
        .word     (rx_word)
    );

    word_2_byte w2b (
        .rst      (rst),
        .clk      (clk),
        .word_dv  (tx_data_valid),
        .word     (ram_out),
        .byte_dv  (tx_word_valid),
        .byteee     (tx_byte)
    );

    //----------------------------------------------------------
    // Affectations directes (ram_adr, ram_in)
    // On indexe la RAM par rx_byte_count en écriture
    //----------------------------------------------------------
    always @(*) begin
        ram_adr = rx_byte_count;    
        ram_in  = rx_word;         
    end

    // rx_byte_count : compteur 0..63
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_byte_count <= 6'd0;
        end else if (ce) begin
            if (init_byte_counter) begin
                rx_byte_count <= 6'd0;
            end else if (enable_rx_byte_counter) begin
                if (rx_byte_count == 6'd63)
                    rx_byte_count <= 6'd0;
                else
                    rx_byte_count <= rx_byte_count + 1'b1;
            end
        end
    end

    //----------------------------------------------------------
    // tx_cycle_count : compteur 0..18000
    // Signale tx_cycle_count_over = 1 quand on dépasse 18000
    //----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_cycle_count     <= 15'd0;
            tx_cycle_count_over <= 1'b0;
        end else if (ce) begin
            if (init_tx_cycle_count) begin
                tx_cycle_count     <= 15'd0;
                tx_cycle_count_over <= 1'b0;
            end else if (tx_cycle_count == 15'd18000) begin
                // On reset le compteur, signale qu'on a atteint 8K cycle (ici 18000)
                tx_cycle_count     <= 15'd0;
                tx_cycle_count_over <= 1'b1;
            end else begin
                tx_cycle_count     <= tx_cycle_count + 1'b1;
                tx_cycle_count_over <= 1'b0;
            end
        end
    end

    //----------------------------------------------------------
    // Déclaration de la FSM
    //----------------------------------------------------------
    // 10 états (0 à 9)
    localparam [3:0]
        INIT                = 4'd0,
        WAIT_RX_BYTE        = 4'd1,
        INCR_RX_BYTE_COUNTER= 4'd2,
        WRITE_RX_BYTE       = 4'd3,
        WAIT_SCAN_MEM       = 4'd4,
        READ_TX_BYTE        = 4'd5,
        INCR_TX_BYTE_COUNTER= 4'd6,
        ENABLE_TX           = 4'd7,
        WAIT_8K_CYCLE       = 4'd8,
        OVER                = 4'd9;

    reg [3:0] current_state, next_state;

    //----------------------------------------------------------
    // Registre d’état (state_register)
    //----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= INIT;
        end else if (ce) begin
            current_state <= next_state;
        end
    end

    //----------------------------------------------------------
    // Logique combinatoire du prochain état
    // (équivalent de next_state_compute)
    //----------------------------------------------------------
    always @(current_state, rx_word_valid, rx_byte_count, scan_memory, tx_cycle_count_over) begin
        // Par défaut, on reste dans le même état
        next_state = current_state;

        case (current_state)
            INIT: begin
                // => WAIT_RX_BYTE directement
                next_state = WAIT_RX_BYTE;
            end

            WAIT_RX_BYTE: begin
                // if rx_word_valid=1 => WRITE_RX_BYTE
                // else remain in WAIT_RX_BYTE
                if (rx_word_valid == 1'b1)
                    next_state = WRITE_RX_BYTE;
            end

            WRITE_RX_BYTE: begin
                // if rx_byte_count=63 => WAIT_SCAN_MEM
                // else => INCR_RX_BYTE_COUNTER
                if (rx_byte_count == 6'd63)
                    next_state = WAIT_SCAN_MEM;
                else
                    next_state = INCR_RX_BYTE_COUNTER;
            end

            INCR_RX_BYTE_COUNTER: begin
                // => WAIT_RX_BYTE
                next_state = WAIT_RX_BYTE;
            end

            WAIT_SCAN_MEM: begin
                // if scan_memory=1 => READ_TX_BYTE
                // else => WAIT_SCAN_MEM
                if (scan_memory == 1'b1)
                    next_state = READ_TX_BYTE;
            end

            READ_TX_BYTE: begin
                // => ENABLE_TX
                next_state = ENABLE_TX;
            end

            ENABLE_TX: begin
                // if rx_byte_count=63 => OVER
                // else => INCR_TX_BYTE_COUNTER
                if (rx_byte_count == 6'd63)
                    next_state = OVER;
                else
                    next_state = INCR_TX_BYTE_COUNTER;
            end

            INCR_TX_BYTE_COUNTER: begin
                // => WAIT_8K_CYCLE
                next_state = WAIT_8K_CYCLE;
            end

            WAIT_8K_CYCLE: begin
                // if tx_cycle_count_over=0 => WAIT_8K_CYCLE
                // else => READ_TX_BYTE
                if (tx_cycle_count_over == 1'b1)
                    next_state = READ_TX_BYTE;
            end

            OVER: begin
                // Reste dans OVER
                next_state = OVER;
            end

            default: begin
                next_state = INIT;
            end
        endcase
    end

    //----------------------------------------------------------
    // Logique des sorties (et signaux internes) en fonction
    // de l'état courant (équivalent de output_compute)
    //----------------------------------------------------------
    always @(current_state) begin
        // Valeurs par défaut (pour éviter les latches)
        ram_rw                = 1'b0;
        ram_enable            = 1'b1;   // on semble l'activer dans tous les états
        tx_data_valid         = 1'b0;
        enable_rx_byte_counter= 1'b0;
        boot                  = 1'b1;
        init_byte_counter     = 1'b0;
        init_tx_cycle_count   = 1'b1;   // souvent mis à 1, sauf dans WAIT_8K_CYCLE=0 ?

        case (current_state)
            INIT: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b1; // reset du compteur
                init_tx_cycle_count   = 1'b1;
            end

            WAIT_RX_BYTE: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            WRITE_RX_BYTE: begin
                ram_rw                = 1'b1; // on écrit dans la RAM
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            INCR_RX_BYTE_COUNTER: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b1; // incrément
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            WAIT_SCAN_MEM: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b0; // <= '0'
                init_byte_counter     = 1'b1; // <= '1'
                init_tx_cycle_count   = 1'b1;
            end

            READ_TX_BYTE: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            ENABLE_TX: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b1;  // on valide la sortie vers word_2_byte
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            INCR_TX_BYTE_COUNTER: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b1; // on réutilise le même compteur (rx_byte_count) ?
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            WAIT_8K_CYCLE: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b0; // ici c’est '0'
            end

            OVER: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b0;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end

            default: begin
                ram_rw                = 1'b0;
                ram_enable            = 1'b1;
                tx_data_valid         = 1'b0;
                enable_rx_byte_counter= 1'b0;
                boot                  = 1'b1;
                init_byte_counter     = 1'b0;
                init_tx_cycle_count   = 1'b1;
            end
        endcase
    end

endmodule

