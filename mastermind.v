module mastermind(
    input clk,
    input rst,
    input enterA,
    input enterB,
    input [2:0] letterIn,
    output reg [7:0] LEDX,
    output reg [6:0] SSD3,
    output reg [6:0] SSD2,
    output reg [6:0] SSD1,
    output reg [6:0] SSD0
);// States

    reg [3:0] state;
    reg [3:0] next_state;
    
    parameter [3:0] S_START        = 4'd0;
    parameter [3:0] S_SHOW_SCORE   = 4'd1;
    parameter [3:0] S_SHOW_ACTIVE  = 4'd2;
    parameter [3:0] S_MAKER_IN     = 4'd3;
    parameter [3:0] S_SHOW_ACTIVE_B = 4'd4;
    parameter [3:0] S_SHOW_LIVES   = 4'd5;
    parameter [3:0] S_BREAKER_IN   = 4'd6;
    parameter [3:0] S_EVAL         = 4'd7;
    parameter [3:0] S_WAIT_NEXT    = 4'd8;
    parameter [3:0] S_SHOW_CODE    = 4'd9;
    parameter [3:0] S_SWAP_ROLES   = 4'd10;
    parameter [3:0] S_GAME_END     = 4'd11;
//SSD Patters
    parameter [6:0] SEG_BLANK = 7'b1111111;
    parameter [6:0] SEG_DASH  = 7'b0111111;  
    parameter [6:0] SEG_A     = 7'b0001000;
    parameter [6:0] SEG_b     = 7'b0000011;
    parameter [6:0] SEG_C     = 7'b1000110;
    parameter [6:0] SEG_E     = 7'b0000110;
    parameter [6:0] SEG_F     = 7'b0001110;
    parameter [6:0] SEG_H     = 7'b0001001;
    parameter [6:0] SEG_L     = 7'b1000111;
    parameter [6:0] SEG_U     = 7'b1000001;
    parameter [6:0] SEG_P     = 7'b0001100;
    parameter [6:0] SEG_0     = 7'b1000000;
    parameter [6:0] SEG_1     = 7'b1111001;
    parameter [6:0] SEG_2     = 7'b0100100;
    parameter [6:0] SEG_3     = 7'b0110000;
    
//Data Regs
    reg [2:0] code0, code1, code2, code3;
    reg [2:0] g0, g1, g2, g3;
    reg [1:0] idx;
    reg [1:0] lives;
    reg [1:0] scoreA, scoreB;
    reg makerIsA;

    // Control signals
    reg init_game;          
    reg load_code;          
    reg reset_idx_breaker;  
    reg clear_guess;        
    reg load_guess;         
    reg update_score_lives; 
    reg reset_idx_wait;     
    reg swap_roles;         
    
    reg [6:0] timer;
    reg ui_delay_done;
    reg timer_enable;
    
    // Timer runs independently based on enable signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer <= 7'd0;
        end
        else begin
            if (timer_enable) begin
                if (ui_delay_done) begin
                    timer <= 7'd0;
                end
                else begin
                    timer <= timer + 7'd1;
                end
            end
            else begin
                timer <= 7'd0;
            end
        end
    end
    
    // Timer completion flag
    always @(*) begin
        ui_delay_done = (timer == 7'd100);
    end
    
    // Timer enable based on current state
    always @(*) begin
        timer_enable = (state == S_SHOW_SCORE || state == S_SHOW_ACTIVE || 
                       state == S_SHOW_ACTIVE_B || state == S_SHOW_LIVES || 
                       state == S_SHOW_CODE || state == S_SWAP_ROLES || 
                       state == S_GAME_END);
    end
    
    // Button signals
    wire makerBTN, breakerBTN;
    reg makerBTN_reg, breakerBTN_reg;
    wire btn;
    
    assign btn = enterA | enterB;
    
    always @(*) begin
        if (makerIsA == 1'b1) begin
            makerBTN_reg = enterA;
            breakerBTN_reg = enterB;
        end
        else begin
            makerBTN_reg = enterB;
            breakerBTN_reg = enterA;
        end
    end
    
    assign makerBTN = makerBTN_reg;
    assign breakerBTN = breakerBTN_reg;

    // LED Evaluation
    reg [1:0] led_fb0, led_fb1, led_fb2, led_fb3;
    reg code_used_0, code_used_1, code_used_2, code_used_3;
    wire guess_correct;
    
    assign guess_correct = (g0 == code0) && (g1 == code1) && (g2 == code2) && (g3 == code3);
    
    always @(*) begin
        led_fb0 = 2'b00;
        led_fb1 = 2'b00;
        led_fb2 = 2'b00;
        led_fb3 = 2'b00;
        code_used_0 = 1'b0;
        code_used_1 = 1'b0;
        code_used_2 = 1'b0;
        code_used_3 = 1'b0;
        
        // Exact matches
        if (g0 == code0) begin
            led_fb0 = 2'b11;
            code_used_0 = 1'b1;
        end
        if (g1 == code1) begin
            led_fb1 = 2'b11;
            code_used_1 = 1'b1;
        end
        if (g2 == code2) begin
            led_fb2 = 2'b11;
            code_used_2 = 1'b1;
        end
        if (g3 == code3) begin
            led_fb3 = 2'b11;
            code_used_3 = 1'b1;
        end
        
        // Wrong position for g0
        if (led_fb0 == 2'b00) begin
            if (code_used_1 == 1'b0 && g0 == code1) begin
                led_fb0 = 2'b01;
                code_used_1 = 1'b1;
            end
            else if (code_used_2 == 1'b0 && g0 == code2) begin
                led_fb0 = 2'b01;
                code_used_2 = 1'b1;
            end
            else if (code_used_3 == 1'b0 && g0 == code3) begin
                led_fb0 = 2'b01;
                code_used_3 = 1'b1;
            end
        end
        
        // Wrong position for g1
        if (led_fb1 == 2'b00) begin
            if (code_used_0 == 1'b0 && g1 == code0) begin
                led_fb1 = 2'b01;
                code_used_0 = 1'b1;
            end
            else if (code_used_2 == 1'b0 && g1 == code2) begin
                led_fb1 = 2'b01;
                code_used_2 = 1'b1;
            end
            else if (code_used_3 == 1'b0 && g1 == code3) begin
                led_fb1 = 2'b01;
                code_used_3 = 1'b1;
            end
        end
        
        // Wrong position for g2
        if (led_fb2 == 2'b00) begin
            if (code_used_0 == 1'b0 && g2 == code0) begin
                led_fb2 = 2'b01;
                code_used_0 = 1'b1;
            end
            else if (code_used_1 == 1'b0 && g2 == code1) begin
                led_fb2 = 2'b01;
                code_used_1 = 1'b1;
            end
            else if (code_used_3 == 1'b0 && g2 == code3) begin
                led_fb2 = 2'b01;
                code_used_3 = 1'b1;
            end
        end
        
        // Wrong position for g3
        if (led_fb3 == 2'b00) begin
            if (code_used_0 == 1'b0 && g3 == code0) begin
                led_fb3 = 2'b01;
            end
            else if (code_used_1 == 1'b0 && g3 == code1) begin
                led_fb3 = 2'b01;
            end
            else if (code_used_2 == 1'b0 && g3 == code2) begin
                led_fb3 = 2'b01;
            end
        end
    end
    
    // SSD Conversion
    reg [6:0] letter_to_ssd;
    reg [6:0] code0_ssd, code1_ssd, code2_ssd, code3_ssd;
    reg [6:0] g0_ssd, g1_ssd, g2_ssd, g3_ssd;
    reg [6:0] scoreA_ssd, scoreB_ssd, lives_ssd;
    
    always @(*) begin
        case(letterIn)
            3'b000: letter_to_ssd = SEG_DASH;
            3'b001: letter_to_ssd = SEG_A;
            3'b010: letter_to_ssd = SEG_C;
            3'b011: letter_to_ssd = SEG_E;
            3'b100: letter_to_ssd = SEG_F;
            3'b101: letter_to_ssd = SEG_H;
            3'b110: letter_to_ssd = SEG_L;
            3'b111: letter_to_ssd = SEG_U;
            default: letter_to_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(code0)
            3'b000: code0_ssd = SEG_DASH;
            3'b001: code0_ssd = SEG_A;
            3'b010: code0_ssd = SEG_C;
            3'b011: code0_ssd = SEG_E;
            3'b100: code0_ssd = SEG_F;
            3'b101: code0_ssd = SEG_H;
            3'b110: code0_ssd = SEG_L;
            3'b111: code0_ssd = SEG_U;
            default: code0_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(code1)
            3'b000: code1_ssd = SEG_DASH;
            3'b001: code1_ssd = SEG_A;
            3'b010: code1_ssd = SEG_C;
            3'b011: code1_ssd = SEG_E;
            3'b100: code1_ssd = SEG_F;
            3'b101: code1_ssd = SEG_H;
            3'b110: code1_ssd = SEG_L;
            3'b111: code1_ssd = SEG_U;
            default: code1_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(code2)
            3'b000: code2_ssd = SEG_DASH;
            3'b001: code2_ssd = SEG_A;
            3'b010: code2_ssd = SEG_C;
            3'b011: code2_ssd = SEG_E;
            3'b100: code2_ssd = SEG_F;
            3'b101: code2_ssd = SEG_H;
            3'b110: code2_ssd = SEG_L;
            3'b111: code2_ssd = SEG_U;
            default: code2_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(code3)
            3'b000: code3_ssd = SEG_DASH;
            3'b001: code3_ssd = SEG_A;
            3'b010: code3_ssd = SEG_C;
            3'b011: code3_ssd = SEG_E;
            3'b100: code3_ssd = SEG_F;
            3'b101: code3_ssd = SEG_H;
            3'b110: code3_ssd = SEG_L;
            3'b111: code3_ssd = SEG_U;
            default: code3_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(g0)
            3'b000: g0_ssd = SEG_DASH;
            3'b001: g0_ssd = SEG_A;
            3'b010: g0_ssd = SEG_C;
            3'b011: g0_ssd = SEG_E;
            3'b100: g0_ssd = SEG_F;
            3'b101: g0_ssd = SEG_H;
            3'b110: g0_ssd = SEG_L;
            3'b111: g0_ssd = SEG_U;
            default: g0_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(g1)
            3'b000: g1_ssd = SEG_DASH;
            3'b001: g1_ssd = SEG_A;
            3'b010: g1_ssd = SEG_C;
            3'b011: g1_ssd = SEG_E;
            3'b100: g1_ssd = SEG_F;
            3'b101: g1_ssd = SEG_H;
            3'b110: g1_ssd = SEG_L;
            3'b111: g1_ssd = SEG_U;
            default: g1_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(g2)
            3'b000: g2_ssd = SEG_DASH;
            3'b001: g2_ssd = SEG_A;
            3'b010: g2_ssd = SEG_C;
            3'b011: g2_ssd = SEG_E;
            3'b100: g2_ssd = SEG_F;
            3'b101: g2_ssd = SEG_H;
            3'b110: g2_ssd = SEG_L;
            3'b111: g2_ssd = SEG_U;
            default: g2_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(g3)
            3'b000: g3_ssd = SEG_DASH;
            3'b001: g3_ssd = SEG_A;
            3'b010: g3_ssd = SEG_C;
            3'b011: g3_ssd = SEG_E;
            3'b100: g3_ssd = SEG_F;
            3'b101: g3_ssd = SEG_H;
            3'b110: g3_ssd = SEG_L;
            3'b111: g3_ssd = SEG_U;
            default: g3_ssd = SEG_BLANK;
        endcase
    end
    
    always @(*) begin
        case(scoreA)
            2'd0: scoreA_ssd = SEG_0;
            2'd1: scoreA_ssd = SEG_1;
            2'd2: scoreA_ssd = SEG_2;
            default: scoreA_ssd = SEG_0;
        endcase
    end
    
    always @(*) begin
        case(scoreB)
            2'd0: scoreB_ssd = SEG_0;
            2'd1: scoreB_ssd = SEG_1;
            2'd2: scoreB_ssd = SEG_2;
            default: scoreB_ssd = SEG_0;
        endcase
    end
    
    always @(*) begin
        case(lives)
            2'd1: lives_ssd = SEG_1;
            2'd2: lives_ssd = SEG_2;
            2'd3: lives_ssd = SEG_3;
            default: lives_ssd = SEG_3;
        endcase
    end
    
    // FSM STATE REGISTER
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_START;
        end
        else begin
            state <= next_state;
        end
    end
    
    // FSM Logic (generates control signals only)
    always @(*) begin
        // Default control signals
        init_game = 1'b0;
        load_code = 1'b0;
        reset_idx_breaker = 1'b0;
        clear_guess = 1'b0;
        load_guess = 1'b0;
        update_score_lives = 1'b0;
        reset_idx_wait = 1'b0;
        swap_roles = 1'b0;
        
        // Generate control signals based on current state
        case (state)
            S_START: begin
                if (next_state == S_SHOW_SCORE) begin
                    init_game = 1'b1;
                end
            end
            
            S_MAKER_IN: begin
                if (makerBTN == 1'b1 && letterIn != 3'b000) begin
                    load_code = 1'b1;
                end
            end
            
            S_SHOW_ACTIVE_B: begin
                if (next_state == S_SHOW_LIVES) begin
                    reset_idx_breaker = 1'b1;
                end
            end
            
            S_SHOW_LIVES: begin
                if (next_state == S_BREAKER_IN) begin
                    clear_guess = 1'b1;
                end
            end
            
            S_BREAKER_IN: begin
                if (breakerBTN == 1'b1 && letterIn != 3'b000) begin
                    load_guess = 1'b1;
                end
            end
            
            S_EVAL: begin
                if (breakerBTN == 1'b1) begin
                    update_score_lives = 1'b1;
                end
            end
            
            S_WAIT_NEXT: begin
                reset_idx_wait = 1'b1;
            end
            
            S_SWAP_ROLES: begin
                swap_roles = 1'b1;
            end
        endcase
    end
    
    // FSM nextstate logic checks ui_delay_done 
    always @(*) begin
        case (state)
            S_START: begin
                if (btn == 1'b1) begin
                    next_state = S_SHOW_SCORE;
                end
                else begin
                    next_state = S_START;
                end
            end
            
            S_SHOW_SCORE: begin
                if (ui_delay_done == 1'b1) begin
                    next_state = S_SHOW_ACTIVE;
                end
                else begin
                    next_state = S_SHOW_SCORE;
                end
            end
            
            S_SHOW_ACTIVE: begin
                if (ui_delay_done == 1'b1) begin
                    next_state = S_MAKER_IN;
                end
                else begin
                    next_state = S_SHOW_ACTIVE;
                end
            end
            
            S_MAKER_IN: begin
                if (makerBTN == 1'b1 && letterIn != 3'b000 && idx == 2'd3) begin
                    next_state = S_SHOW_ACTIVE_B;
                end
                else begin
                    next_state = S_MAKER_IN;
                end
            end
            
            S_SHOW_ACTIVE_B: begin
                if (ui_delay_done == 1'b1) begin
                    next_state = S_SHOW_LIVES;
                end
                else begin
                    next_state = S_SHOW_ACTIVE_B;
                end
            end
            
            S_SHOW_LIVES: begin
                if (ui_delay_done == 1'b1) begin
                    next_state = S_BREAKER_IN;
                end
                else begin
                    next_state = S_SHOW_LIVES;
                end
            end
            
            S_BREAKER_IN: begin
                if (breakerBTN == 1'b1 && letterIn != 3'b000 && idx == 2'd3) begin
                    next_state = S_EVAL;
                end
                else begin
                    next_state = S_BREAKER_IN;
                end
            end
            
            S_EVAL: begin
                if (breakerBTN == 1'b1) begin
                    if (guess_correct == 1'b1) begin
                        next_state = S_WAIT_NEXT;
                    end
                    else if (lives == 2'd1) begin
                        next_state = S_SHOW_CODE;
                    end
                    else begin
                        next_state = S_WAIT_NEXT;
                    end
                end
                else begin
                    next_state = S_EVAL;
                end
            end
            
            S_WAIT_NEXT: begin
                if (guess_correct == 1'b1) begin
                    next_state = S_SWAP_ROLES;
                end
                else begin
                    next_state = S_SHOW_LIVES;
                end
            end
            
            S_SHOW_CODE: begin
                if (ui_delay_done == 1'b1) begin
                    next_state = S_SWAP_ROLES;
                end
                else begin
                    next_state = S_SHOW_CODE;
                end
            end
            
            S_SWAP_ROLES: begin
                if (ui_delay_done == 1'b1) begin
                    if (scoreA == 2'd2 || scoreB == 2'd2) begin
                        next_state = S_GAME_END;
                    end
                    else begin
                        next_state = S_SHOW_SCORE;
                    end
                end
                else begin
                    next_state = S_SWAP_ROLES;
                end
            end
            
            S_GAME_END: begin
                if (btn == 1'b1) begin
                    next_state = S_START;
                end
                else begin
                    next_state = S_GAME_END;
                end
            end
            
            default: begin
                next_state = S_START;
            end
        endcase
    end
    
    // Datapatth respond to control signals only
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            idx <= 2'd0;
            lives <= 2'd3;
            scoreA <= 2'd0;
            scoreB <= 2'd0;
            makerIsA <= 1'b1;
            code0 <= 3'd0;
            code1 <= 3'd0;
            code2 <= 3'd0;
            code3 <= 3'd0;
            g0 <= 3'd0;
            g1 <= 3'd0;
            g2 <= 3'd0;
            g3 <= 3'd0;
        end
        else begin
            if (init_game) begin
                makerIsA <= ~enterB;
                scoreA <= 2'd0;
                scoreB <= 2'd0;
                idx <= 2'd0;
                lives <= 2'd3;
            end
            
            // Load code
            if (load_code) begin
                case (idx)
                    2'd0: code0 <= letterIn;
                    2'd1: code1 <= letterIn;
                    2'd2: code2 <= letterIn;
                    2'd3: code3 <= letterIn;
                endcase
                idx <= idx + 2'd1;
            end
            // Reset index for breaker phase
            if (reset_idx_breaker) begin
                idx <= 2'd0;
            end
            
            // Clear regs SSDs
            if (clear_guess) begin
                g0 <= 3'd0;
                g1 <= 3'd0;
                g2 <= 3'd0;
                g3 <= 3'd0;
            end
            
            // Load guess
            if (load_guess) begin
                case (idx)
                    2'd0: g0 <= letterIn;
                    2'd1: g1 <= letterIn;
                    2'd2: g2 <= letterIn;
                    2'd3: g3 <= letterIn;
                endcase
                idx <= idx + 2'd1;
            end
            
            // Update score or lives after evaluation
            if (update_score_lives) begin
                if (guess_correct == 1'b1) begin
                    if (makerIsA == 1'b1) begin
                        scoreB <= scoreB + 2'd1;
                    end
                    else begin
                        scoreA <= scoreA + 2'd1;
                    end
                end
                else if (lives == 2'd1) begin
                    if (makerIsA == 1'b1) begin
                        scoreA <= scoreA + 2'd1;
                    end
                    else begin
                        scoreB <= scoreB + 2'd1;
                    end
                end
                else begin
                    lives <= lives - 2'd1;
                end
            end
            
            // Reset index in wait state
            if (reset_idx_wait) begin
                idx <= 2'd0;
            end

            if (swap_roles) begin
                makerIsA <= ~makerIsA;
                idx <= 2'd0;
                lives <= 2'd3;
                code0 <= 3'd0;
                code1 <= 3'd0;
                code2 <= 3'd0;
                code3 <= 3'd0;
                g0 <= 3'd0;
                g1 <= 3'd0;
                g2 <= 3'd0;
                g3 <= 3'd0;
            end
        end
    end
    
    // Output Logic(combinational)
    always @(*) begin
        LEDX = 8'b00000000;
        SSD3 = SEG_BLANK;
        SSD2 = SEG_BLANK;
        SSD1 = SEG_BLANK;
        SSD0 = SEG_BLANK;
        
        case (state)
            S_START: begin
                SSD3 = SEG_A;
                SSD2 = SEG_DASH;
                SSD1 = SEG_b;
                SSD0 = SEG_BLANK;
            end
            
            S_SHOW_SCORE: begin
                SSD3 = scoreA_ssd;
                SSD2 = SEG_DASH;
                SSD1 = scoreB_ssd;
                SSD0 = SEG_BLANK;
            end
            
            S_SHOW_ACTIVE: begin
                SSD3 = SEG_P;
                SSD2 = SEG_DASH;
                if (makerIsA == 1'b1) begin
                    SSD1 = SEG_A;
                end
                else begin
                    SSD1 = SEG_b;
                end
                SSD0 = SEG_BLANK;
            end
            
            S_MAKER_IN: begin
                case (idx)
                    2'd0: begin
                        SSD3 = letter_to_ssd;
                    end
                    2'd1: begin
                        SSD3 = SEG_DASH;
                        SSD2 = letter_to_ssd;
                    end
                    2'd2: begin
                        SSD3 = SEG_DASH;
                        SSD2 = SEG_DASH;
                        SSD1 = letter_to_ssd;
                    end
                    2'd3: begin
                        SSD3 = SEG_DASH;
                        SSD2 = SEG_DASH;
                        SSD1 = SEG_DASH;
                        SSD0 = letter_to_ssd;
                    end
                endcase
            end
            
            S_SHOW_ACTIVE_B: begin
                SSD3 = SEG_P;
                SSD2 = SEG_DASH;
                if (makerIsA == 1'b1) begin
                    SSD1 = SEG_b;
                end
                else begin
                    SSD1 = SEG_A;
                end
                SSD0 = SEG_BLANK;
            end
            
            S_SHOW_LIVES: begin
                SSD3 = SEG_L;
                SSD2 = SEG_DASH;
                SSD1 = lives_ssd;
                SSD0 = SEG_BLANK;
            end
            
            S_BREAKER_IN: begin
                case (idx)
                    2'd0: begin
                        SSD3 = letter_to_ssd;
                    end
                    2'd1: begin
                        SSD3 = g0_ssd;
                        SSD2 = letter_to_ssd;
                    end
                    2'd2: begin
                        SSD3 = g0_ssd;
                        SSD2 = g1_ssd;
                        SSD1 = letter_to_ssd;
                    end
                    2'd3: begin
                        SSD3 = g0_ssd;
                        SSD2 = g1_ssd;
                        SSD1 = g2_ssd;
                        SSD0 = letter_to_ssd;
                    end
                endcase
            end
            
            S_EVAL: begin
                LEDX[7] = led_fb0[1];
                LEDX[6] = led_fb0[0];
                LEDX[5] = led_fb1[1];
                LEDX[4] = led_fb1[0];
                LEDX[3] = led_fb2[1];
                LEDX[2] = led_fb2[0];
                LEDX[1] = led_fb3[1];
                LEDX[0] = led_fb3[0];
                SSD3 = g0_ssd;
                SSD2 = g1_ssd;
                SSD1 = g2_ssd;
                SSD0 = g3_ssd;
            end
            
            S_WAIT_NEXT: begin
                LEDX[7] = led_fb0[1];
                LEDX[6] = led_fb0[0];
                LEDX[5] = led_fb1[1];
                LEDX[4] = led_fb1[0];
                LEDX[3] = led_fb2[1];
                LEDX[2] = led_fb2[0];
                LEDX[1] = led_fb3[1];
                LEDX[0] = led_fb3[0];
                SSD3 = g0_ssd;
                SSD2 = g1_ssd;
                SSD1 = g2_ssd;
                SSD0 = g3_ssd;
            end
            
            S_SHOW_CODE: begin
                SSD3 = code0_ssd;
                SSD2 = code1_ssd;
                SSD1 = code2_ssd;
                SSD0 = code3_ssd;
            end
            
            S_SWAP_ROLES: begin
                SSD3 = scoreA_ssd;
                SSD2 = SEG_DASH;
                SSD1 = scoreB_ssd;
                SSD0 = SEG_BLANK;
            end
            
            S_GAME_END: begin
                SSD3 = SEG_P;
                SSD2 = SEG_DASH;
                if (scoreA == 2'd2) begin
                    SSD1 = SEG_A;
                end
                else begin
                    SSD1 = SEG_b;
                end
                SSD0 = SEG_BLANK;
                if (timer[5] == 1'b1) begin
                    LEDX = 8'b11111111;
                end
                else begin
                    LEDX = 8'b00000000;
                end
            end
            
            default: begin
                SSD3 = SEG_A;
                SSD2 = SEG_DASH;
                SSD1 = SEG_b;
                SSD0 = SEG_BLANK;
            end
        endcase
    end

endmodule
