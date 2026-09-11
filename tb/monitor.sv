class fifo_monitor #(
    parameter int DATA_WIDTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) scoreboard_mailbox;
    mailbox #(transaction_t) coverage_mailbox;

    virtual fifo_if #(DATA_WIDTH).monitor vif;

    function new(
        mailbox #(transaction_t) scoreboard_mailbox,
        mailbox #(transaction_t) coverage_mailbox,
        virtual fifo_if #(DATA_WIDTH).monitor vif
    );
        this.scoreboard_mailbox = scoreboard_mailbox;
        this.coverage_mailbox   = coverage_mailbox;
        this.vif                = vif;
    endfunction

    task run(input int transaction_count);
        transaction_t transaction;

        repeat (transaction_count) begin
            transaction = new();

            @(posedge vif.clk);

            // Capture requests and FIFO state before the DUT updates.
            transaction.rst_n        = vif.rst_n;
            transaction.wr_en        = vif.wr_en;
            transaction.rd_en        = vif.rd_en;
            transaction.wr_data      = vif.wr_data;
            transaction.full_before  = vif.full;
            transaction.empty_before = vif.empty;

            // Wait until nonblocking assignments have updated the DUT.
            #1step;

            transaction.rd_data     = vif.rd_data;
            transaction.full_after  = vif.full;
            transaction.empty_after = vif.empty;

            $display(
                "MONITOR: wr=%0b rd=%0b data_in=%0h data_out=%0h",
                transaction.wr_en,
                transaction.rd_en,
                transaction.wr_data,
                transaction.rd_data
            );

            // Both consumers receive the same read-only observation.
            scoreboard_mailbox.put(transaction);
            coverage_mailbox.put(transaction);
        end
    endtask

endclass