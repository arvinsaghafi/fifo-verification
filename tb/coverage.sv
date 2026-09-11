class fifo_coverage #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 8
);

    typedef fifo_transaction #(DATA_WIDTH) transaction_t;

    mailbox #(transaction_t) coverage_mailbox;

    int unsigned occupancy;
    int unsigned occupancy_before;
    int unsigned occupancy_after;
    int unsigned state_before;
    int unsigned sample_count;

    bit [1:0] requested_operation;
    bit [1:0] accepted_operation;

    localparam int STATE_EMPTY  = 0;
    localparam int STATE_MIDDLE = 1;
    localparam int STATE_FULL   = 2;
    localparam int ALMOST_FULL  = DEPTH - 1;

    covergroup fifo_cg;

        option.per_instance = 1;

        requested_operation_cp:
            coverpoint requested_operation {
                bins idle       = {2'b00};
                bins read_only  = {2'b01};
                bins write_only = {2'b10};
                bins read_write = {2'b11};
            }

        accepted_operation_cp:
            coverpoint accepted_operation {
                bins neither    = {2'b00};
                bins read_only  = {2'b01};
                bins write_only = {2'b10};
                bins both       = {2'b11};
            }

        occupancy_cp:
            coverpoint occupancy_after {
                bins every_level[] = {[0:DEPTH]};
                illegal_bins invalid = default;
            }

        state_before_cp:
            coverpoint state_before {
                bins empty  = {STATE_EMPTY};
                bins middle = {STATE_MIDDLE};
                bins full   = {STATE_FULL};
            }

        occupancy_transition_cp:
            coverpoint occupancy_after {
                bins empty_to_nonempty =
                    (0 => 1);

                bins nonempty_to_empty =
                    (1 => 0);

                bins almost_full_to_full =
                    (ALMOST_FULL => DEPTH);

                bins full_to_almost_full =
                    (DEPTH => ALMOST_FULL);
            }

        state_operation_cross:
            cross state_before_cp, requested_operation_cp;

    endgroup

    function new(
        mailbox #(transaction_t) coverage_mailbox
    );
        this.coverage_mailbox = coverage_mailbox;

        occupancy       = 0;
        occupancy_before = 0;
        occupancy_after  = 0;
        state_before     = STATE_EMPTY;
        sample_count     = 0;

        fifo_cg = new();
    endfunction

    function void sample_transaction(
        transaction_t transaction
    );
        bit write_accepted;
        bit read_accepted;

        occupancy_before = occupancy;

        if (occupancy_before == 0)
            state_before = STATE_EMPTY;
        else if (occupancy_before == DEPTH)
            state_before = STATE_FULL;
        else
            state_before = STATE_MIDDLE;

        requested_operation = {
            transaction.wr_en,
            transaction.rd_en
        };

        write_accepted =
            transaction.wr_en && (occupancy_before < DEPTH);

        read_accepted =
            transaction.rd_en && (occupancy_before > 0);

        accepted_operation = {
            write_accepted,
            read_accepted
        };

        if (!transaction.rst_n) begin
            occupancy = 0;
        end
        else begin
            case ({write_accepted, read_accepted})
                2'b10: occupancy++;
                2'b01: occupancy--;
                default: occupancy = occupancy;
            endcase
        end

        occupancy_after = occupancy;
        sample_count++;

        fifo_cg.sample();
    endfunction

    task run(input int transaction_count);
        transaction_t transaction;

        repeat (transaction_count) begin
            coverage_mailbox.get(transaction);
            sample_transaction(transaction);
        end

        $display(
            "COVERAGE: sampled=%0d overall=%0.2f%%",
            sample_count,
            fifo_cg.get_inst_coverage()
        );

        $display(
            "COVERAGE: requested operations=%0.2f%%",
            fifo_cg.requested_operation_cp.get_inst_coverage()
        );

        $display(
            "COVERAGE: accepted operations=%0.2f%%",
            fifo_cg.accepted_operation_cp.get_inst_coverage()
        );

        $display(
            "COVERAGE: occupancy levels=%0.2f%%",
            fifo_cg.occupancy_cp.get_inst_coverage()
        );

        $display(
            "COVERAGE: boundary states=%0.2f%%",
            fifo_cg.state_before_cp.get_inst_coverage()
        );

        $display(
            "COVERAGE: occupancy transitions=%0.2f%%",
            fifo_cg.occupancy_transition_cp.get_inst_coverage()
        );

        $display(
            "COVERAGE: state-operation cross=%0.2f%%",
            fifo_cg.state_operation_cross.get_inst_coverage()
        );
    endtask

endclass