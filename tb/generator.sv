class fifo_generator #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) generator_mailbox;

    function new(
        mailbox #(transaction_t) generator_mailbox
    );
        this.generator_mailbox = generator_mailbox;
    endfunction

    task send_targeted(
        input bit wr_en,
        input bit rd_en,
        input logic [DATA_WIDTH-1:0] wr_data
    );
        transaction_t transaction;

        transaction = new();
        transaction.wr_en   = wr_en;
        transaction.rd_en   = rd_en;
        transaction.wr_data = wr_data;

        generator_mailbox.put(transaction);

        $display(
            "GENERATOR TARGETED: wr_en=%0b rd_en=%0b wr_data=%0h",
            transaction.wr_en,
            transaction.rd_en,
            transaction.wr_data
        );
    endtask

    task run_coverage_sequence();

        // Exercise all four requests while empty.
        send_targeted(0, 0, '0);
        send_targeted(0, 1, '0);
        send_targeted(1, 1, DATA_WIDTH'(8'hA1));

        // Return to empty.
        send_targeted(0, 1, '0);

        // Exercise all four requests while partially full.
        send_targeted(1, 0, DATA_WIDTH'(8'hA2));
        send_targeted(0, 0, '0);
        send_targeted(1, 1, DATA_WIDTH'(8'hA3));
        send_targeted(1, 0, DATA_WIDTH'(8'hA4));

        // Fill the remaining entries.
        for (int i = 2; i < DEPTH; i++)
            send_targeted(
                1,
                0,
                DATA_WIDTH'(8'hB0 + i)
            );

        // Exercise all four requests while full.
        send_targeted(0, 0, '0);
        send_targeted(1, 0, '1);
        send_targeted(1, 1, DATA_WIDTH'(8'hC1));

        // Refill after the simultaneous operation removed one item.
        send_targeted(1, 0, DATA_WIDTH'(8'hD1));

        // Read-only request while full.
        send_targeted(0, 1, '0);

        // Drain the remaining entries so random testing starts empty.
        for (int i = 0; i < DEPTH - 1; i++)
            send_targeted(0, 1, '0);
    endtask

    task run_random(input int transaction_count);
        transaction_t transaction;

        repeat (transaction_count) begin
            transaction = new();

            if (!transaction.randomize())
                $fatal(1, "Generator transaction randomization failed");

            generator_mailbox.put(transaction);

            $display(
                "GENERATOR RANDOM: wr_en=%0b rd_en=%0b wr_data=%0h",
                transaction.wr_en,
                transaction.rd_en,
                transaction.wr_data
            );
        end
    endtask

    task run(input int random_transaction_count);
        run_coverage_sequence();
        run_random(random_transaction_count);
    endtask

endclass