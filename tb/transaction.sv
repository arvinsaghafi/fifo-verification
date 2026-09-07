class fifo_transaction #(
    parameter int DATA_WIDTH = 8
);
    // Requested operation.
    rand bit wr_en;
    rand bit rd_en;
    rand logic [DATA_WIDTH-1:0] wr_data;

    // State observed around the clock edge.
    logic rst_n;
    logic full_before;
    logic empty_before;

    logic [DATA_WIDTH-1:0] rd_data;
    logic full_after;
    logic empty_after;

endclass