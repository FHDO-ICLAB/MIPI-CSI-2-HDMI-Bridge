`timescale 1ns/1ns

`define IVERILOG 1

module buffer_tb();
//simulated 25MHz clk_pix_sim is normally generated by PLL and divider
    reg clk_pix_sim = 0;
    reg clk_csi_base = 0;
    reg clk_csi_EN = 0;
    reg clk_csi_sim = 0;
    reg rst_n_sim = 0;
    reg [15:0] data_in_sim;
    reg data_in_valid_sim;
    reg data_request = 0;   //initially 0
    wire RGB_out_valid;
    wire [23:0] RGB_out;

localparam RED = 8'h1F;
localparam GREEN = 8'h4F;
localparam BLUE = 8'h22;

    RAM_buffer dut1(
        .clk_a(clk_csi_sim),
        .clk_b(clk_pix_sim),
        .rst_n(rst_n_sim),
        .data_in(data_in_sim),
        .data_in_valid(data_in_valid_sim),
        .data_request(data_request),
        .data_out_valid(RGB_out_valid),
        .data_out(RGB_out)
    );

task send_frame;
    reg[8:0] i;
    begin
        for (i = 0; i<240; i = i +1) begin 
            send_line({GREEN, RED});
            send_line({BLUE, GREEN});
        end
    end
endtask

task send_line;
    input [15:0] data;
    begin
        #40;
        data_in_valid_sim = 1;
        data_in_sim = data;
        #6400;
        data_in_valid_sim = 0;
        #20;
        data_in_sim = 0;
    end
endtask

initial begin
    $dumpfile("buffer_tb.vcd");
    $dumpvars(0, buffer_tb);
end

always begin
    #20 clk_pix_sim <= ~clk_pix_sim;
end
always begin
    #10 clk_csi_base <= ~clk_csi_base;
    if (clk_csi_EN) clk_csi_sim <= clk_csi_base;
    else clk_csi_sim <= 0;
end
//simulate request signal from output
//exact timings are ignored. Should not matter
always @ (posedge clk_pix_sim) begin
    if(RGB_out_valid) data_request <= 1;
end

initial begin
    #30 rst_n_sim = 1;
    clk_csi_EN = 1;
    send_frame();
    #100;
    data_in_valid_sim = 1;
    data_in_sim = {GREEN, RED};
    #640;
//write reset test
    data_in_valid_sim = 0;
    data_in_sim = 0;
    clk_csi_EN = 0;
    #160;   //long pause to check write count reset thing
    clk_csi_EN = 1;
    //more time for the read to finish
    #9300000
    $finish;
end
endmodule