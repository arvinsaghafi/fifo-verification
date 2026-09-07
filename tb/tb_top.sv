`include "fifo_if.sv"
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "fifo_sva.sv"

module tb_top;
    timeunit 1ns;
    timeprecision 1ps;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH = 8;
    localparam int RANDOM_TRANSACTION_COUNT = 100;

    localparam logic [DATA_WIDTH-1:0] WIDTH_TEST_VALUE =
        (DATA_WIDTH'(1) << (DATA_WIDTH - 1))
        | DATA_WIDTH'(8'h5A);

    logic clk = 0;

    fifo_if #(
        .DATA_WIDTH(DATA_WIDTH)
    ) fifo_bus (
        .clk(clk)
    );

    logic [DATA_WIDTH-1:0] observed_data;

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) generator_mailbox;
    mailbox #(transaction_t) monitor_mailbox;

    fifo_generator  #(DATA_WIDTH) generator;
    fifo_driver     #(DATA_WIDTH) driver;
    fifo_monitor    #(DATA_WIDTH) monitor;
    fifo_scoreboard #(DATA_WIDTH, DEPTH) scoreboard;

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk     (clk),
        .rst_n   (fifo_bus.rst_n),
        .wr_en   (fifo_bus.wr_en),
        .rd_en   (fifo_bus.rd_en),
        .wr_data (fifo_bus.wr_data),
        .rd_data (fifo_bus.rd_data),
        .full    (fifo_bus.full),
        .empty   (fifo_bus.empty)
    );

    fifo_sva #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DEPTH)
    ) fifo_assertions (
        .clk     (clk),
        .rst_n   (fifo_bus.rst_n),
        .wr_en   (fifo_bus.wr_en),
        .rd_en   (fifo_bus.rd_en),
        .rd_data (fifo_bus.rd_data),
        .full    (fifo_bus.full),
        .empty   (fifo_bus.empty),
        .wr_ptr  (dut.wr_ptr),
        .rd_ptr  (dut.rd_ptr),
        .count   (dut.count)
    );

    always #5 clk = ~clk;

    task automatic write_item(
        input logic [DATA_WIDTH-1:0] data
    );
        @(negedge clk);
        fifo_bus.wr_en   = 1'b1;
        fifo_bus.wr_data = data;

        @(posedge clk);
        #1;
        fifo_bus.wr_en = 1'b0;
    endtask

    task automatic read_item(
        output logic [DATA_WIDTH-1:0] data
    );
        @(negedge clk);
        fifo_bus.rd_en = 1'b1;

        @(posedge clk);
        #1;
        fifo_bus.rd_en = 1'b0;
        data = fifo_bus.rd_data;
    endtask

    task automatic read_write_item(
        input  logic [DATA_WIDTH-1:0] write_data,
        output logic [DATA_WIDTH-1:0] read_data
    );
        @(negedge clk);
        fifo_bus.wr_en   = 1'b1;
        fifo_bus.rd_en   = 1'b1;
        fifo_bus.wr_data = write_data;

        @(posedge clk);
        #1;
        fifo_bus.wr_en = 1'b0;
        fifo_bus.rd_en = 1'b0;
        read_data = fifo_bus.rd_data;
    endtask

    initial begin
        generator_mailbox = new();
        monitor_mailbox   = new();

        generator  = new(generator_mailbox);
        driver     = new(generator_mailbox, fifo_bus);
        monitor    = new(monitor_mailbox, fifo_bus);
        scoreboard = new(monitor_mailbox);

        // Initialize signals driven by the testbench.
        fifo_bus.rst_n   = 1'b0;
        fifo_bus.wr_en   = 1'b0;
        fifo_bus.rd_en   = 1'b0;
        fifo_bus.wr_data = '0;

        // Hold reset active for two rising clock edges.
        repeat (2) @(posedge clk);
        #1;

        if (fifo_bus.empty !== 1'b1)
            $fatal(1, "FIFO should be empty after reset");

        if (fifo_bus.full !== 1'b0)
            $fatal(1, "FIFO should not be full after reset");

        if (fifo_bus.rd_data !== '0)
            $fatal(1, "rd_data should be zero after reset");

        // Release reset away from the rising edge.
        @(negedge clk);
        fifo_bus.rst_n = 1'b1;

        write_item(WIDTH_TEST_VALUE);

        if (fifo_bus.empty !== 1'b0)
            $fatal(1, "FIFO should not be empty after a write");

        read_item(observed_data);

        if (observed_data !== WIDTH_TEST_VALUE)
            $fatal(1, "Expected %h, received %h",
                   WIDTH_TEST_VALUE, observed_data);

        if (fifo_bus.empty !== 1'b1)
            $fatal(1, "FIFO should be empty after the read");

        // Fill the FIFO with values 1 through DEPTH.
        for (int i = 0; i < DEPTH; i++) begin
            write_item(DATA_WIDTH'(i + 1));

            if (fifo_bus.empty !== 1'b0)
                $fatal(1, "FIFO empty after write %0d", i + 1);

            if (fifo_bus.full !== (i == DEPTH - 1))
                $fatal(1, "Incorrect full flag after write %0d",
                       i + 1);
        end

        // Attempt one extra write while full.
        write_item('1);

        if (fifo_bus.full !== 1'b1)
            $fatal(1, "FIFO lost full status after a blocked write");

        if (fifo_bus.empty !== 1'b0)
            $fatal(1, "FIFO became empty after a blocked write");

        // Read every stored value.
        for (int i = 0; i < DEPTH; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(i + 1))
                $fatal(1, "Read %0d: expected %0h, got %0h",
                       i + 1, DATA_WIDTH'(i + 1), observed_data);

            if (fifo_bus.full !== 1'b0)
                $fatal(1, "FIFO still full after read %0d",
                       i + 1);

            if (fifo_bus.empty !== (i == DEPTH - 1))
                $fatal(1, "Incorrect empty flag after read %0d",
                       i + 1);
        end

        // Attempt one extra read while empty.
        read_item(observed_data);

        if (fifo_bus.empty !== 1'b1)
            $fatal(1, "FIFO lost empty status after a blocked read");

        if (fifo_bus.full !== 1'b0)
            $fatal(1, "FIFO became full after a blocked read");

        if (observed_data !== DATA_WIDTH'(DEPTH))
            $fatal(1, "rd_data changed after a blocked read");

        // Test simultaneous read and write.
        write_item(8'h11);
        read_write_item(8'h22, observed_data);

        if (observed_data !== 8'h11)
            $fatal(1,
                   "Simultaneous read returned %h, expected 11",
                   observed_data);

        if (fifo_bus.empty !== 1'b0 ||
            fifo_bus.full !== 1'b0)
            $fatal(1,
                   "Incorrect flags after simultaneous read/write");

        read_item(observed_data);

        if (observed_data !== 8'h22)
            $fatal(1,
                   "Expected remaining value 22, received %h",
                   observed_data);

        if (fifo_bus.empty !== 1'b1)
            $fatal(1, "FIFO should be empty after final read");

        // Store two values before resetting.
        for (int i = 0; i < 2; i++)
            write_item(DATA_WIDTH'(8'hD1 + i));

        if (fifo_bus.empty !== 1'b0)
            $fatal(1, "FIFO should contain data before active reset");

        // Assert reset while both operations are requested.
        @(negedge clk);
        fifo_bus.rst_n   = 1'b0;
        fifo_bus.wr_en   = 1'b1;
        fifo_bus.rd_en   = 1'b1;
        fifo_bus.wr_data = 8'hFF;

        @(posedge clk);
        #1;
        fifo_bus.wr_en = 1'b0;
        fifo_bus.rd_en = 1'b0;

        if (fifo_bus.empty !== 1'b1)
            $fatal(1, "FIFO should be empty after active reset");

        if (fifo_bus.full !== 1'b0)
            $fatal(1, "FIFO should not be full after active reset");

        if (fifo_bus.rd_data !== '0)
            $fatal(1, "rd_data should be zero after active reset");

        @(negedge clk);
        fifo_bus.rst_n = 1'b1;

        // Parameter-independent wraparound test.
        for (int i = 0; i < DEPTH - 1; i++)
            write_item(DATA_WIDTH'(8'hA0 + i));

        read_item(observed_data);

        if (observed_data !== DATA_WIDTH'(8'hA0))
            $fatal(1,
                   "Wrap setup: expected A0, received %h",
                   observed_data);

        // Write B0 and B1, forcing the write pointer to wrap.
        for (int i = 0; i < 2; i++) begin
            write_item(DATA_WIDTH'(8'hB0 + i));

            if (fifo_bus.full !== (i == 1))
                $fatal(1,
                       "Incorrect full flag during wraparound write %0d",
                       i + 1);
        end

        // Read the remaining A values.
        for (int i = 1; i < DEPTH - 1; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hA0 + i))
                $fatal(1,
                       "Wrap drain: expected %h, received %h",
                       DATA_WIDTH'(8'hA0 + i), observed_data);
        end

        // Read B0 and B1, forcing the read pointer to wrap.
        for (int i = 0; i < 2; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hB0 + i))
                $fatal(1,
                       "Wrap drain: expected %h, received %h",
                       DATA_WIDTH'(8'hB0 + i), observed_data);
        end

        if (fifo_bus.empty !== 1'b1 ||
            fifo_bus.full !== 1'b0)
            $fatal(1, "Incorrect flags after wraparound drain");

        // Simultaneous read/write while empty.
        read_write_item(8'hC1, observed_data);

        if (observed_data !== DATA_WIDTH'(8'hB1))
            $fatal(1,
                   "Empty simultaneous operation changed rd_data");

        if (fifo_bus.empty !== 1'b0 ||
            fifo_bus.full !== 1'b0)
            $fatal(1,
                   "Incorrect flags after empty simultaneous operation");

        read_item(observed_data);

        if (observed_data !== 8'hC1)
            $fatal(1, "Expected C1 after empty simultaneous operation");

        if (fifo_bus.empty !== 1'b1)
            $fatal(1, "FIFO should be empty after reading C1");

        // Fill the FIFO before testing simultaneous activity while full.
        for (int i = 0; i < DEPTH; i++)
            write_item(DATA_WIDTH'(8'hD0 + i));

        if (fifo_bus.full !== 1'b1)
            $fatal(1, "FIFO should be full before boundary test");

        read_write_item(8'hEE, observed_data);

        if (observed_data !== 8'hD0)
            $fatal(1,
                   "Full simultaneous operation expected D0, got %h",
                   observed_data);

        if (fifo_bus.full !== 1'b0 ||
            fifo_bus.empty !== 1'b0)
            $fatal(1,
                   "Incorrect flags after full simultaneous operation");

        // The rejected EE write must not appear.
        for (int i = 1; i < DEPTH; i++) begin
            read_item(observed_data);

            if (observed_data !== DATA_WIDTH'(8'hD0 + i))
                $fatal(1,
                       "Expected %h after full boundary operation, got %h",
                       DATA_WIDTH'(8'hD0 + i), observed_data);
        end

        if (fifo_bus.empty !== 1'b1 ||
            fifo_bus.full !== 1'b0)
            $fatal(1,
                   "Incorrect flags after full-boundary drain");

        $display("DIRECTED FIFO TESTS PASSED");

        // Reset before randomized testing so that the DUT and
        // scoreboard both start empty with rd_data equal to zero.
        @(negedge clk);
        fifo_bus.rst_n   = 1'b0;
        fifo_bus.wr_en   = 1'b0;
        fifo_bus.rd_en   = 1'b0;
        fifo_bus.wr_data = '0;

        @(posedge clk);
        #1;

        if (fifo_bus.empty !== 1'b1 ||
            fifo_bus.full !== 1'b0 ||
            fifo_bus.rd_data !== '0)
            $fatal(1, "Incorrect state before randomized test");

        // We are already one timestep after the reset clock edge.
        // Release reset now so the driver can use the upcoming negative edge.
        fifo_bus.rst_n = 1'b1;

        fork
            generator.run(RANDOM_TRANSACTION_COUNT);
            driver.run(RANDOM_TRANSACTION_COUNT);
            monitor.run(RANDOM_TRANSACTION_COUNT);
            scoreboard.run(RANDOM_TRANSACTION_COUNT);
        join

        if (generator_mailbox.num() != 0)
            $fatal(1, "Driver did not consume every transaction");

        if (monitor_mailbox.num() != 0)
            $fatal(1, "Scoreboard did not consume every observation");

        if (scoreboard.checked_count != RANDOM_TRANSACTION_COUNT)
            $fatal(1,
                   "Scoreboard checked %0d transactions, expected %0d",
                   scoreboard.checked_count,
                   RANDOM_TRANSACTION_COUNT);

        if (scoreboard.error_count != 0)
            $fatal(1,
                   "Random test failed with %0d scoreboard errors",
                   scoreboard.error_count);

        $display("RANDOM SELF-CHECKING TEST PASSED");
        $display("ALL FIFO TESTS PASSED");
        $finish;
    end

endmodule