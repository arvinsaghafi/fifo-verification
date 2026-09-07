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

    modport dut (
        input  clk,
        input  rst_n,
        input  wr_en,
        input  rd_en,
        input  wr_data,
        output rd_data,
        output full,
        output empty
    );

    modport tb (
        input  clk,
        input  rd_data,
        input  full,
        input  empty,
        output rst_n,
        output wr_en,
        output rd_en,
        output wr_data
    );

    modport monitor (
    input clk,
    input rst_n,
    input wr_en,
    input rd_en,
    input wr_data,
    input rd_data,
    input full,
    input empty
    );

endinterface