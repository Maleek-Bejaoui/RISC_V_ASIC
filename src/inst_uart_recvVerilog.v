
module UART_recv (
    input  wire       clk,
    input  wire       reset,
    input  wire       rx,
    output reg  [7:0] dat,
    output reg        dat_en
);

    //---------------------------------------------
    // Définition des états (traduction de t_fsm)
    //---------------------------------------------
    
    localparam [2:0]
        IDLE            = 3'd0,
        ZERO_AS_INPUT   = 3'd1,
        WAIT_NEXT_BIT   = 3'd2,
        BIT_SAMPLE      = 3'd3,
        BIT_RECEIVED    = 3'd4,
        WAIT_STOP_BIT   = 3'd5,
        LAST_BIT_IS_ZERO= 3'd6;
    
    // (pour un horloge ~100 MHz et un baud rate 115200)
    
    localparam [9:0] QUARTER        = 10'd216;  // ~1/4 de la période bit
    localparam [9:0] HALF           = 10'd433;  // ~1/2
    localparam [9:0] THREE_QUARTERS = 10'd643;  // ~3/4
    localparam [9:0] FULL           = 10'd867;  // ~1 période entière
    
    //---------------------------------------------
    // Registres internes
    //---------------------------------------------
    
    reg [2:0] current_state, next_state; // registre d'état
    reg [3:0] nbbits;                    // compte le nombre de bits reçus (0..8)
    reg [9:0] cnt;                       // compteur pour les timings
    reg       rxi;                       // échantillonnage du signal rx
    reg       ref_bit;                   // bit de référence utilisé pendant BIT_SAMPLE
    reg [7:0] shift;                     // registre de décalage pour construire l'octet reçu
    
    //---------------------------------------------
    // 1) Échantillonnage de l'entrée rx
    //    (comme dans le code VHDL, pour éviter le glitch)
    //---------------------------------------------
    always @(posedge clk) begin
        rxi <= rx;
    end
    
    //---------------------------------------------
    // 2) Registre d'état (synchronisé sur clk + reset)
    //---------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    //---------------------------------------------
    // 3) Logique combinatoire de changement d’état
    //    (traduction directe des conditions du code VHDL)
    //---------------------------------------------
    always @(*) begin
        // Par défaut, on reste dans le même état
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                // VHDL : if rxi='0' then state <= zero_as_input;
                if (rxi == 1'b0)
                    next_state = ZERO_AS_INPUT;
                // sinon on reste en IDLE
            end
            
            ZERO_AS_INPUT: begin
                // if rxi='1' then state <= idle; elsif cnt=0 then state <= wait_next_bit;
                if (rxi == 1'b1)
                    next_state = IDLE;
                else if (cnt == 0)
                    next_state = WAIT_NEXT_BIT;
            end
            
            WAIT_NEXT_BIT: begin
                // if cnt=0 then state <= bit_sample;
                if (cnt == 0)
                    next_state = BIT_SAMPLE;
            end
            
            BIT_SAMPLE: begin
                // if cnt=0 then state <= bit_received;
                if (cnt == 0)
                    next_state = BIT_RECEIVED;
            end
            
            BIT_RECEIVED: begin
                // if nbbits<8 then wait_next_bit
                // else if ref_bit=1 => wait_stop_bit
                // else => last_bit_is_zero
                if (nbbits < 8)
                    next_state = WAIT_NEXT_BIT;
                else if (ref_bit == 1'b1)
                    next_state = WAIT_STOP_BIT;
                else
                    next_state = LAST_BIT_IS_ZERO;
            end
            
            WAIT_STOP_BIT: begin
                // if rxi=0 => last_bit_is_zero
                // elsif cnt=0 => idle
                if (rxi == 1'b0)
                    next_state = LAST_BIT_IS_ZERO;
                else if (cnt == 0)
                    next_state = IDLE;
            end
            
            LAST_BIT_IS_ZERO: begin
                // if cnt=0 => idle
                if (cnt == 0)
                    next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE; // Sécurité
            end
        endcase
    end

    //---------------------------------------------
    // 4) Logique séquentielle : compteur, registre
    //    de décalage, nbbits, et signaux de sortie
    //---------------------------------------------
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset asynchrone
            cnt     <= QUARTER;
            nbbits  <= 4'd0;
            shift   <= 8'd0;
            dat     <= 8'd0;
            dat_en  <= 1'b0;
            ref_bit <= 1'b1;
        end else begin
            // Par défaut, dat_en = 0 à chaque cycle
            dat_en <= 1'b0;
            
            case (current_state)
                //---------------------------------
                // IDLE
                //---------------------------------
                IDLE: begin
                    // cnt <= quarter; nbbits=0
                    cnt    <= QUARTER;
                    nbbits <= 4'd0;
                end
                
                //---------------------------------
                // ZERO_AS_INPUT
                //---------------------------------
                ZERO_AS_INPUT: begin
                    // if (rxi=1) => next=IDLE
                    // else if cnt=0 => WAIT_NEXT_BIT => cnt=three_quarters
                    // else cnt=cnt-1
                    if (rxi == 1'b0) begin
                        if (cnt == 0)
                            cnt <= THREE_QUARTERS;
                        else
                            cnt <= cnt - 1;
                    end
                    // si (rxi==1) => on va en IDLE au cycle suivant (cf. next_state), 
                    //   pas de modif de cnt ici (on le réinitialisera en IDLE)
                end
                
                //---------------------------------
                // WAIT_NEXT_BIT
                //---------------------------------
                WAIT_NEXT_BIT: begin
                    // if cnt=0 => BIT_SAMPLE => cnt=quarter
                    // else cnt=cnt-1
                    if (cnt == 0)
                        cnt <= QUARTER;
                    else
                        cnt <= cnt - 1;
                end
                
                //---------------------------------
                // BIT_SAMPLE
                //---------------------------------
                BIT_SAMPLE: begin
                    // if ref_bit != rxi => cnt=quarter
                    // else cnt=cnt-1
                    if (ref_bit != rxi)
                        cnt <= QUARTER;
                    else
                        cnt <= cnt - 1;
                end
                
                //---------------------------------
                // BIT_RECEIVED
                //---------------------------------
                BIT_RECEIVED: begin
                    // if nbbits<8 => cnt=three_quarters
                    // else if ref_bit=0 => cnt=full
                    // else => cnt=half
                    // => nbbits <= nbbits+1
                    if (nbbits < 8) begin
                        cnt <= THREE_QUARTERS;
                    end else if (ref_bit == 1'b0) begin
                        cnt <= FULL;
                    end else begin
                        cnt <= HALF;
                    end
                    nbbits <= nbbits + 1;
                end
                
                //---------------------------------
                // WAIT_STOP_BIT
                //---------------------------------
                WAIT_STOP_BIT: begin
                    // cnt <= cnt-1
                    // si cnt=0 => next_state=IDLE => on déclenche dat_en et on sort dat=shift
                    cnt <= cnt - 1;
                    
                    // En VHDL : "ELSIF state = wait_stop_bit AND cnt=0 THEN dat_en <= '1'; dat <= shift;"
                    // On anticipe le cycle où cnt va passer à 0
                    if (cnt == 1) begin
                        dat_en <= 1'b1;
                        dat    <= shift;
                    end
                end
                
                //---------------------------------
                // LAST_BIT_IS_ZERO
                //---------------------------------
                LAST_BIT_IS_ZERO: begin
                    // if rxi=0 => cnt=full
                    // else cnt=cnt-1
                    // if cnt=0 => idle
                    if (rxi == 1'b0) begin
                        cnt <= FULL;
                    end else begin
                        cnt <= cnt - 1;
                    end
                end
                
                default: begin
                    // Sécurité
                end
            endcase
            
            // Mise à jour de ref_bit
            // (Comme en VHDL : si on est dans WAIT_NEXT_BIT ou BIT_SAMPLE, on capture rxi)
            if ((current_state == WAIT_NEXT_BIT) || (current_state == BIT_SAMPLE)) begin
                ref_bit <= rxi;
            end
            
            // Chargement du bit reçu dans le shift
            // VHDL : 
            //   IF state=bit_sample AND cnt=0 AND nbbits<8 THEN
            //       shift <= ref_bit & shift(7 DOWNTO 1);
            //   END IF;
            if ((current_state == BIT_SAMPLE) && (cnt == 0) && (nbbits < 8)) begin
                // Décalage à gauche : le bit ref_bit devient le LSB ou MSB ?
                // Dans le code VHDL : shift <= ref_bit & shift(7 DOWNTO 1);
                // Cela place `ref_bit` en bit [7], et décale shift[7..1] vers shift[6..0].
                // => On peut écrire en Verilog :
                shift <= {ref_bit, shift[7:1]};
            end
        end
    end

endmodule

