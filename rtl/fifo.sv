module fifo #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter int unsigned DEPTH      = 8
) (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  full,
    output logic                  empty
);

    localparam int unsigned PTR_WIDTH =
        (DEPTH > 1) ? $clog2(DEPTH) : 1;

    localparam int unsigned COUNT_WIDTH = $clog2(DEPTH + 1);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;
    logic [COUNT_WIDTH-1:0] count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;
        end 
        else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= wr_data;

                if (wr_ptr == DEPTH - 1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            if (rd_en && !empty) begin
                rd_data <= mem[rd_ptr];

                if (rd_ptr == DEPTH - 1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            case ({(wr_en && !full), (rd_en && !empty)})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule