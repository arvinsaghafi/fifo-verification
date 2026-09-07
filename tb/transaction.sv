class fifo_transaction #(
    parameter int DATA_WIDTH = 8
);
    // Stimulus generated for the DUT.
    rand bit wr_en;
    rand bit rd_en;
    rand logic [DATA_WIDTH-1:0] wr_data;

    // Results observed from the DUT.
    logic [DATA_WIDTH-1:0] rd_data;
    logic full;
    logic empty;

endclass