class fifo_generator #(
    parameter int DATA_WIDTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) output_mailbox;

    function new(mailbox #(transaction_t) output_mailbox);
        this.output_mailbox = output_mailbox;
    endfunction

    task run(input int transaction_count);
        transaction_t transaction;

        repeat (transaction_count) begin
            transaction = new();

            if (!transaction.randomize())
                $fatal(1, "Transaction randomization failed");

            output_mailbox.put(transaction);

            $display(
                "GENERATOR: wr_en=%0b rd_en=%0b wr_data=%0h",
                transaction.wr_en,
                transaction.rd_en,
                transaction.wr_data
            );
        end
    endtask
    
endclass