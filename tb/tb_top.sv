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

        // The previous test left the FIFO empty.
        for (int i = 0; i < DEPTH; i++) begin
            @(negedge clk);
            wr_en   = 1'b1;
            wr_data = DATA_WIDTH'(i + 1);

            @(posedge clk);
            #1;
            wr_en = 1'b0;

            if (empty !== 1'b0)
                $fatal(1, "FIFO empty after write %0d", i + 1);

            if (full !== (i == DEPTH - 1))
                $fatal(1, "Incorrect full flag after write %0d",
                       i + 1);
        end

        // Attempt one extra write while the FIFO is full.
        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = '1;

        @(posedge clk);
        #1;
        wr_en = 1'b0;

        if (full !== 1'b1)
            $fatal(1, "FIFO lost full status after a blocked write");

        if (empty !== 1'b0)
            $fatal(1, "FIFO became empty after a blocked write");

        // Read every value from the full FIFO.
        for (int i = 0; i < DEPTH; i++) begin
            @(negedge clk);
            rd_en = 1'b1;

            @(posedge clk);
            #1;
            rd_en = 1'b0;

            if (rd_data !== DATA_WIDTH'(i + 1))
                $fatal(1, "Read %0d: expected %0h, got %0h",
                       i + 1, DATA_WIDTH'(i + 1), rd_data);

            if (full !== 1'b0)
                $fatal(1, "FIFO still full after read %0d",
                       i + 1);

            if (empty !== (i == DEPTH - 1))
                $fatal(1, "Incorrect empty flag after read %0d",
                       i + 1);
        end

        // Attempt one extra read while the FIFO is empty.
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;
        rd_en = 1'b0;

        if (empty !== 1'b1)
            $fatal(1, "FIFO lost empty status after a blocked read");

        if (full !== 1'b0)
            $fatal(1, "FIFO became full after a blocked read");

        if (rd_data !== DATA_WIDTH'(DEPTH))
            $fatal(1, "rd_data changed after a blocked read");

        // Put one value into the empty FIFO.
        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = 8'h11;

        @(posedge clk);
        #1;
        wr_en = 1'b0;

        // Read 11 and write 22 during the same clock edge.
        @(negedge clk);
        wr_en   = 1'b1;
        rd_en   = 1'b1;
        wr_data = 8'h22;

        @(posedge clk);
        #1;
        wr_en = 1'b0;
        rd_en = 1'b0;

        if (rd_data !== 8'h11)
            $fatal(1, "Simultaneous read returned %h, expected 11",
                   rd_data);

        if (empty !== 1'b0 || full !== 1'b0)
            $fatal(1, "Incorrect flags after simultaneous read/write");

        // Only 22 should remain.
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;
        rd_en = 1'b0;

        if (rd_data !== 8'h22)
            $fatal(1, "Expected remaining value 22, received %h",
                   rd_data);

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after final read");

        $display("DIRECTED FIFO TESTS PASSED");
        $finish;
    end

endmodule