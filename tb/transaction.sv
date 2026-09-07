class fifo_transaction #(
    parameter int DATA_WIDTH = 8
);
    // Requested operation.
    rand bit wr_en;
    rand bit rd_en;
    rand logic [DATA_WIDTH-1:0] wr_data;

    constraint operation_distribution {
        {wr_en, rd_en} dist {
            2'b00 := 10,  // Idle
            2'b01 := 35,  // Read
            2'b10 := 35,  // Write
            2'b11 := 20   // Simultaneous read/write
        };
    }

    // State observed around the clock edge.
    logic rst_n;
    logic full_before;
    logic empty_before;

    logic [DATA_WIDTH-1:0] rd_data;
    logic full_after;
    logic empty_after;

endclass