class fifo_monitor #(
    parameter int DATA_WIDTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) output_mailbox;
    virtual interface fifo_if #(DATA_WIDTH).monitor vif;

    function new(
        mailbox #(transaction_t) output_mailbox,
        virtual interface fifo_if #(DATA_WIDTH).monitor vif
    );
        this.output_mailbox = output_mailbox;
        this.vif = vif;
    endfunction

    task run(input int transaction_count);
        transaction_t observed;

        repeat (transaction_count) begin
            @(posedge vif.clk);

            observed = new();

            // Capture the request and pre-edge state.
            observed.rst_n       = vif.rst_n;
            observed.wr_en       = vif.wr_en;
            observed.rd_en       = vif.rd_en;
            observed.wr_data     = vif.wr_data;
            observed.full_before = vif.full;
            observed.empty_before = vif.empty;

            // Wait for sequential DUT updates.
            #1step;

            observed.rd_data    = vif.rd_data;
            observed.full_after = vif.full;
            observed.empty_after = vif.empty;

            output_mailbox.put(observed);

            $display(
                "MONITOR: wr=%0b rd=%0b data_in=%0h data_out=%0h",
                observed.wr_en,
                observed.rd_en,
                observed.wr_data,
                observed.rd_data
            );
        end
    endtask

endclass