class fifo_scoreboard #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) input_mailbox;

    logic [DATA_WIDTH-1:0] expected_queue[$];
    logic [DATA_WIDTH-1:0] expected_rd_data;

    int checked_count;
    int error_count;

    function new(mailbox #(transaction_t) input_mailbox);
        this.input_mailbox = input_mailbox;

        expected_rd_data = '0;
        checked_count = 0;
        error_count = 0;
    endfunction

    task run(input int transaction_count);
        transaction_t observed;

        repeat (transaction_count) begin
            input_mailbox.get(observed);
            check(observed);
        end
    endtask

    function void check(transaction_t observed);
        bit expected_empty_before;
        bit expected_full_before;
        bit read_accepted;
        bit write_accepted;

        expected_empty_before = (expected_queue.size() == 0);
        expected_full_before  = (expected_queue.size() == DEPTH);

        read_accepted  = 1'b0;
        write_accepted = 1'b0;

        if (!observed.rst_n) begin
            expected_queue.delete();
            expected_rd_data = '0;
        end
        else begin
            if (observed.empty_before !== expected_empty_before) begin
                $error("SCOREBOARD: incorrect pre-edge empty flag");
                error_count++;
            end

            if (observed.full_before !== expected_full_before) begin
                $error("SCOREBOARD: incorrect pre-edge full flag");
                error_count++;
            end

            read_accepted =
                observed.rd_en && !expected_empty_before;

            write_accepted =
                observed.wr_en && !expected_full_before;

            if (read_accepted)
                expected_rd_data = expected_queue.pop_front();

            if (write_accepted)
                expected_queue.push_back(observed.wr_data);
        end

        if (observed.rd_data !== expected_rd_data) begin
            $error(
                "SCOREBOARD: expected rd_data=%0h, received=%0h",
                expected_rd_data,
                observed.rd_data
            );
            error_count++;
        end

        if (observed.empty_after !==
            (expected_queue.size() == 0)) begin
            $error("SCOREBOARD: incorrect post-edge empty flag");
            error_count++;
        end

        if (observed.full_after !==
            (expected_queue.size() == DEPTH)) begin
            $error("SCOREBOARD: incorrect post-edge full flag");
            error_count++;
        end

        checked_count++;

        $display(
            "SCOREBOARD: checked=%0d occupancy=%0d errors=%0d",
            checked_count,
            expected_queue.size(),
            error_count
        );
    endfunction

endclass