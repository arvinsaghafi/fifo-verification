interface fifo_if #(
    parameter int DATA_WIDTH = 8
) (
    input logic clk
);

    logic rst_n;
    logic wr_en;
    logic rd_en;

    logic [DATA_WIDTH-1:0] wr_data;
    logic [DATA_WIDTH-1:0] rd_data;

    logic full;
    logic empty;

endinterface