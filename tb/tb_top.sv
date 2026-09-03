module tb_top;
    timeunit 1ns;
    timeprecision 1ps;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH = 8;

    logic clk = 0;
    logic rst_n = 0;
    logic wr_en = 0;
    logic rd_en = 0;
    logic [DATA_WIDTH-1:0] wr_data = '0;

    logic [DATA_WIDTH-1:0] rd_data;
    logic full;
    logic empty;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        // Hold reset active for two rising clock edges.
        repeat (2) @(posedge clk);
        #1;

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after reset");

        if (full !== 1'b0)
            $fatal(1, "FIFO should not be full after reset");

        if (rd_data !== '0)
            $fatal(1, "rd_data should be zero after reset");

        // Release reset away from the rising edge.
        @(negedge clk);
        rst_n = 1'b1;

        // Write 8'hA5.
        @(negedge clk);
        wr_en  = 1'b1;
        wr_data = 8'hA5;

        @(posedge clk);
        #1;
        wr_en = 1'b0;

        if (empty !== 1'b0)
            $fatal(1, "FIFO should not be empty after a write");

        // Read the stored value.
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;
        rd_en = 1'b0;

        if (rd_data !== 8'hA5)
            $fatal(1, "Expected A5, received %h", rd_data);

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after the read");

        $display("BASIC TEST PASSED");
        $finish;
    end

endmodule