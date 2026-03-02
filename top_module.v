module top(
    input clk,
    input [3:0] btn,
    input [3:0] sw,
    
    output [7:0] led,
    output [7:0] seven,
    output [3:0] segment
);

    // Clock divider output
    wire clk_divided;
    
    // Debounced signals
    wire rst_debounced;
    wire enterA_debounced;
    wire enterB_debounced;
    
    // Letter Switches
    wire [2:0] letterIn;
    assign letterIn = sw[2:0];
    
    // SSD wires from main
    wire [7:0] led_from_mm;
    wire [6:0] ssd3_wire;
    wire [6:0] ssd2_wire;
    wire [6:0] ssd1_wire;
    wire [6:0] ssd0_wire;
    
    // SSD idx
    wire [7:0] disp0;
    wire [7:0] disp1;
    wire [7:0] disp2;
    wire [7:0] disp3;

    // raw reset from button
    wire rst_btn_raw;
    assign rst_btn_raw = ~btn[2];

    // Clock divider
    clk_divider u_clk_div (
        .clk_in(clk),
        .divided_clk(clk_divided)
    );

    debouncer debouncer_rst (
        .clk(clk_divided),
        .rst(1'b0),
        .noisy_in(rst_btn_raw),
        .clean_out(rst_debounced)
    );

    debouncer debouncer_enterB (
        .clk(clk_divided),
        .rst(rst_debounced),
        .noisy_in(~btn[0]),
        .clean_out(enterB_debounced)
    );

    debouncer debouncer_enterA (
        .clk(clk_divided),
        .rst(rst_debounced),
        .noisy_in(~btn[3]),
        .clean_out(enterA_debounced)
    );

    // Main module
    mastermind u_mastermind (
        .clk(clk_divided),
        .rst(rst_debounced),
        .enterA(enterA_debounced),
        .enterB(enterB_debounced),
        .letterIn(letterIn),
        .LEDX(led_from_mm),
        .SSD3(ssd3_wire),
        .SSD2(ssd2_wire),
        .SSD1(ssd1_wire),
        .SSD0(ssd0_wire)
    );

    // LED output
    assign led = led_from_mm;

    // 7-bit SSD to 8-bit expansion (bit 7 = decimal point, off)
    assign disp0 = ~{1'b1, ssd0_wire};
    assign disp1 = ~{1'b1, ssd1_wire};
    assign disp2 = ~{1'b1, ssd2_wire};
    assign disp3 = ~{1'b1, ssd3_wire};

    // SSD
    ssd u_ssd (
        .clk(clk),
        .disp0(disp0),
        .disp1(disp1),
        .disp2(disp2),
        .disp3(disp3),
        .seven(seven),
        .segment(segment)
    );

endmodule
