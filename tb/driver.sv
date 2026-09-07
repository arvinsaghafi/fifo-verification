class fifo_driver #(
    parameter int DATA_WIDTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) input_mailbox;
    virtual interface fifo_if #(DATA_WIDTH).tb vif;

    function new(
        mailbox #(transaction_t) input_mailbox,
        virtual interface fifo_if #(DATA_WIDTH).tb vif
    );
        this.input_mailbox = input_mailbox;
        this.vif = vif;
    endfunction

    task run(input int transaction_count);
        transaction_t transaction;

        repeat (transaction_count) begin
            // Wait until the generator provides a transaction.
            input_mailbox.get(transaction);

            // Drive it before the next rising edge.
            @(negedge vif.clk);
            vif.wr_en   = transaction.wr_en;
            vif.rd_en   = transaction.rd_en;
            vif.wr_data = transaction.wr_data;

            // The DUT accepts or rejects it here.
            @(posedge vif.clk);

            $display(
                "DRIVER: wr_en=%0b rd_en=%0b wr_data=%0h",
                transaction.wr_en,
                transaction.rd_en,
                transaction.wr_data
            );
        end

        // Return the interface to an idle state.
        @(negedge vif.clk);
        vif.wr_en   = 1'b0;
        vif.rd_en   = 1'b0;
        vif.wr_data = '0;
    endtask

endclass