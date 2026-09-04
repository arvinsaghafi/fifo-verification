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

    logic [DATA_WIDTH-1:0] observed_data;

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

    task automatic write_item(
        input logic [DATA_WIDTH-1:0] data
    );
        @(negedge clk);
        wr_en   = 1'b1;
        wr_data = data;

        @(posedge clk);
        #1;
        wr_en = 1'b0;
    endtask
    
    task automatic read_item(
        output logic [DATA_WIDTH-1:0] data
    );
        @(negedge clk);
        rd_en = 1'b1;

        @(posedge clk);
        #1;
        rd_en = 1'b0;
        data  = rd_data;
    endtask

    task automatic read_write_item(
        input  logic [DATA_WIDTH-1:0] write_data,
        output logic [DATA_WIDTH-1:0] read_data
    );
        @(negedge clk);
        wr_en   = 1'b1;
        rd_en   = 1'b1;
        wr_data = write_data;

        @(posedge clk);
        #1;
        wr_en     = 1'b0;
        rd_en     = 1'b0;
        read_data = rd_data;
    endtask

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
        write_item(8'hA5);

        if (empty !== 1'b0)
            $fatal(1, "FIFO should not be empty after a write");

        read_item(observed_data);

        if (observed_data !== 8'hA5)
            $fatal(1, "Expected A5, received %h", observed_data);

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after the read");
            
        // The previous test left the FIFO empty.
        // Fill the FIFO with values 1 through DEPTH.
        for (int i = 0; i < DEPTH; i++) begin
            write_item(DATA_WIDTH'(i + 1));

            if (empty !== 1'b0)
                $fatal(1, "FIFO empty after write %0d", i + 1);

            if (full !== (i == DEPTH - 1))
                $fatal(1, "Incorrect full flag after write %0d",
                       i + 1);
        end

        // Attempt one extra write while full.
        write_item('1);

        if (full !== 1'b1)
            $fatal(1, "FIFO lost full status after a blocked write");

        if (empty !== 1'b0)
            $fatal(1, "FIFO became empty after a blocked write");

        // Read every stored value.
        for (int i = 0; i < DEPTH; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(i + 1))
                $fatal(1, "Read %0d: expected %0h, got %0h",
                       i + 1, DATA_WIDTH'(i + 1), observed_data);

            if (full !== 1'b0)
                $fatal(1, "FIFO still full after read %0d",
                       i + 1);

            if (empty !== (i == DEPTH - 1))
                $fatal(1, "Incorrect empty flag after read %0d",
                       i + 1);
        end

        // Attempt one extra read while empty.
        read_item(observed_data);

        if (empty !== 1'b1)
            $fatal(1, "FIFO lost empty status after a blocked read");

        if (full !== 1'b0)
            $fatal(1, "FIFO became full after a blocked read");

        if (observed_data !== DATA_WIDTH'(DEPTH))
            $fatal(1, "rd_data changed after a blocked read");

        // Put one value into the empty FIFO.
        write_item(8'h11);

        // Read 11 and write 22 during the same clock edge.
        read_write_item(8'h22, observed_data);

        if (observed_data !== 8'h11)
            $fatal(1,
                   "Simultaneous read returned %h, expected 11",
                   observed_data);

        if (empty !== 1'b0 || full !== 1'b0)
            $fatal(1,
                   "Incorrect flags after simultaneous read/write");

        // Only 22 should remain.
        read_item(observed_data);

        if (observed_data !== 8'h22)
            $fatal(1,
                   "Expected remaining value 22, received %h",
                   observed_data);

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after final read");

        // Store two values before resetting.
        for (int i = 0; i < 2; i++)
            write_item(DATA_WIDTH'(8'hD1 + i));

        if (empty !== 1'b0)
            $fatal(1, "FIFO should contain data before active reset");

        // Assert reset while both operations are requested.
        @(negedge clk);
        rst_n   = 1'b0;
        wr_en   = 1'b1;
        rd_en   = 1'b1;
        wr_data = 8'hFF;

        @(posedge clk);
        #1;
        wr_en = 1'b0;
        rd_en = 1'b0;

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after active reset");

        if (full !== 1'b0)
            $fatal(1, "FIFO should not be full after active reset");

        if (rd_data !== '0)
            $fatal(1, "rd_data should be zero after active reset");

        // Release reset for future tests.
        @(negedge clk);
        rst_n = 1'b1;

        // FIFO is empty and both pointers are zero after reset.

        // Write A0 through A5.
        for (int i = 0; i < 6; i++)
            write_item(DATA_WIDTH'(8'hA0 + i));

        // Read A0 through A3, leaving A4 and A5.
        for (int i = 0; i < 4; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hA0 + i))
                $fatal(1,
                       "Wrap setup: expected %h, received %h",
                       DATA_WIDTH'(8'hA0 + i), observed_data);
        end

        if (empty !== 1'b0 || full !== 1'b0)
            $fatal(1, "Incorrect flags during wraparound setup");

        // Write B0 through B5, forcing the write pointer to wrap.
        for (int i = 0; i < 6; i++) begin
            write_item(DATA_WIDTH'(8'hB0 + i));

            if (full !== (i == 5))
                $fatal(1,
                       "Incorrect full flag during wraparound write %0d",
                       i + 1);
        end

        // FIFO now contains:
        // A4, A5, B0, B1, B2, B3, B4, B5

        // Read A4 and A5.
        for (int i = 0; i < 2; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hA4 + i))
                $fatal(1,
                       "Wrap drain: expected %h, received %h",
                       DATA_WIDTH'(8'hA4 + i), observed_data);
        end

        // Read B0 through B5, forcing the read pointer to wrap.
        for (int i = 0; i < 6; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hB0 + i))
                $fatal(1,
                       "Wrap drain: expected %h, received %h",
                       DATA_WIDTH'(8'hB0 + i), observed_data);
        end

        if (empty !== 1'b1 || full !== 1'b0)
            $fatal(1, "Incorrect flags after wraparound drain");

        // Simultaneous read/write while empty.
        // Read rejected; write of C1 accepted.
        read_write_item(8'hC1, observed_data);

        if (observed_data !== 8'hB5)
            $fatal(1,
                   "Empty simultaneous operation changed rd_data");

        if (empty !== 1'b0 || full !== 1'b0)
            $fatal(1,
                   "Incorrect flags after empty simultaneous operation");

        // Confirm that C1 was stored.
        read_item(observed_data);

        if (observed_data !== 8'hC1)
            $fatal(1, "Expected C1 after empty simultaneous operation");

        if (empty !== 1'b1)
            $fatal(1, "FIFO should be empty after reading C1");

        // Fill the FIFO with D0 through D7.
        for (int i = 0; i < DEPTH; i++)
            write_item(DATA_WIDTH'(8'hD0 + i));

        if (full !== 1'b1)
            $fatal(1, "FIFO should be full before boundary test");

        // Simultaneous read/write while full.
        // Read D0; reject the write of EE.
        read_write_item(8'hEE, observed_data);

        if (observed_data !== 8'hD0)
            $fatal(1,
                   "Full simultaneous operation expected D0, got %h",
                   observed_data);

        if (full !== 1'b0 || empty !== 1'b0)
            $fatal(1,
                   "Incorrect flags after full simultaneous operation");

        // D1 through D7 should remain. EE must not appear.
        for (int i = 1; i < DEPTH; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hD0 + i))
                $fatal(1,
                       "Expected %h after full boundary operation, got %h",
                       DATA_WIDTH'(8'hD0 + i), observed_data);
        end

        if (empty !== 1'b1 || full !== 1'b0)
            $fatal(1,
                   "Incorrect flags after full-boundary drain");

        $display("DIRECTED FIFO TESTS PASSED");
        $finish;
    end

endmodule