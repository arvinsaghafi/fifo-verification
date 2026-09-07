module fifo_sva #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 8,
    parameter int PTR_WIDTH =
        (DEPTH > 1) ? $clog2(DEPTH) : 1,
    parameter int COUNT_WIDTH =
        $clog2(DEPTH + 1)
) (
    input logic                   clk,
    input logic                   rst_n,
    input logic                   wr_en,
    input logic                   rd_en,
    input logic [DATA_WIDTH-1:0]  rd_data,
    input logic                   full,
    input logic                   empty,
    input logic [PTR_WIDTH-1:0]   wr_ptr,
    input logic [PTR_WIDTH-1:0]   rd_ptr,
    input logic [COUNT_WIDTH-1:0] count
);

    logic write_accepted;
    logic read_accepted;

    assign write_accepted = wr_en && !full;
    assign read_accepted  = rd_en && !empty;

    default clocking cb @(posedge clk);
    endclocking

    // Reset behavior

    property reset_clears_fifo;
        !rst_n |=> (
            empty &&
            !full &&
            rd_data == '0 &&
            count == '0 &&
            wr_ptr == '0 &&
            rd_ptr == '0
        );
    endproperty

    // Flag behavior

    property flags_never_overlap;
        disable iff (!rst_n)
        !(full && empty);
    endproperty

    property empty_matches_count;
        disable iff (!rst_n)
        empty == (count == 0);
    endproperty

    property full_matches_count;
        disable iff (!rst_n)
        full == (count == DEPTH);
    endproperty

    // Boundary behavior

    property empty_read_holds_data;
        disable iff (!rst_n)
        (empty && rd_en) |=> $stable(rd_data);
    endproperty

    property empty_read_only_stays_empty;
        disable iff (!rst_n)
        (empty && rd_en && !wr_en) |=> empty;
    endproperty

    property full_write_only_stays_full;
        disable iff (!rst_n)
        (full && wr_en && !rd_en) |=> full;
    endproperty

    property write_from_empty_makes_nonempty;
        disable iff (!rst_n)
        (empty && wr_en) |=> !empty;
    endproperty

    property read_from_full_makes_nonfull;
        disable iff (!rst_n)
        (full && rd_en) |=> !full;
    endproperty

    // Internal state ranges

    property count_within_bounds;
        disable iff (!rst_n)
        $unsigned(count) <= DEPTH;
    endproperty

    property write_pointer_within_bounds;
        disable iff (!rst_n)
        $unsigned(wr_ptr) < DEPTH;
    endproperty

    property read_pointer_within_bounds;
        disable iff (!rst_n)
        $unsigned(rd_ptr) < DEPTH;
    endproperty

    // Occupancy transitions

    property count_increments;
        disable iff (!rst_n)
        (write_accepted && !read_accepted)
        |=> count == ($past(count) + 1'b1);
    endproperty

    property count_decrements;
        disable iff (!rst_n)
        (!write_accepted && read_accepted)
        |=> count == ($past(count) - 1'b1);
    endproperty

    property count_holds;
        disable iff (!rst_n)
        (write_accepted == read_accepted)
        |=> $stable(count);
    endproperty

    // Write-pointer transitions

    property write_pointer_wraps;
        disable iff (!rst_n)
        (write_accepted &&
         ($unsigned(wr_ptr) == DEPTH - 1))
        |=> wr_ptr == '0;
    endproperty

    property write_pointer_increments;
        disable iff (!rst_n)
        (write_accepted &&
         ($unsigned(wr_ptr) != DEPTH - 1))
        |=> wr_ptr == ($past(wr_ptr) + 1'b1);
    endproperty

    property write_pointer_holds;
        disable iff (!rst_n)
        !write_accepted |=> $stable(wr_ptr);
    endproperty

    // Read-pointer transitions

    property read_pointer_wraps;
        disable iff (!rst_n)
        (read_accepted &&
         ($unsigned(rd_ptr) == DEPTH - 1))
        |=> rd_ptr == '0;
    endproperty

    property read_pointer_increments;
        disable iff (!rst_n)
        (read_accepted &&
         ($unsigned(rd_ptr) != DEPTH - 1))
        |=> rd_ptr == ($past(rd_ptr) + 1'b1);
    endproperty

    property read_pointer_holds;
        disable iff (!rst_n)
        !read_accepted |=> $stable(rd_ptr);
    endproperty

    // Assertion statements

    assert_reset_clears_fifo:
        assert property (reset_clears_fifo)
        else $error("ASSERTION: reset did not clear FIFO state");

    assert_flags_never_overlap:
        assert property (flags_never_overlap)
        else $error("ASSERTION: full and empty were both asserted");

    assert_empty_matches_count:
        assert property (empty_matches_count)
        else $error("ASSERTION: empty does not match count");

    assert_full_matches_count:
        assert property (full_matches_count)
        else $error("ASSERTION: full does not match count");

    assert_empty_read_holds_data:
        assert property (empty_read_holds_data)
        else $error("ASSERTION: empty read changed rd_data");

    assert_empty_read_only_stays_empty:
        assert property (empty_read_only_stays_empty)
        else $error("ASSERTION: read-only request changed empty FIFO");

    assert_full_write_only_stays_full:
        assert property (full_write_only_stays_full)
        else $error("ASSERTION: write-only request changed full FIFO");

    assert_write_from_empty_makes_nonempty:
        assert property (write_from_empty_makes_nonempty)
        else $error("ASSERTION: accepted write left FIFO empty");

    assert_read_from_full_makes_nonfull:
        assert property (read_from_full_makes_nonfull)
        else $error("ASSERTION: accepted read left FIFO full");

    assert_count_within_bounds:
        assert property (count_within_bounds)
        else $error("ASSERTION: count exceeded DEPTH");

    assert_write_pointer_within_bounds:
        assert property (write_pointer_within_bounds)
        else $error("ASSERTION: write pointer exceeded its range");

    assert_read_pointer_within_bounds:
        assert property (read_pointer_within_bounds)
        else $error("ASSERTION: read pointer exceeded its range");

    assert_count_increments:
        assert property (count_increments)
        else $error("ASSERTION: count did not increment correctly");

    assert_count_decrements:
        assert property (count_decrements)
        else $error("ASSERTION: count did not decrement correctly");

    assert_count_holds:
        assert property (count_holds)
        else $error("ASSERTION: count changed when it should hold");

    assert_write_pointer_wraps:
        assert property (write_pointer_wraps)
        else $error("ASSERTION: write pointer did not wrap to zero");

    assert_write_pointer_increments:
        assert property (write_pointer_increments)
        else $error("ASSERTION: write pointer did not increment correctly");

    assert_write_pointer_holds:
        assert property (write_pointer_holds)
        else $error(
            "ASSERTION: write pointer changed without an accepted write"
        );

    assert_read_pointer_wraps:
        assert property (read_pointer_wraps)
        else $error("ASSERTION: read pointer did not wrap to zero");

    assert_read_pointer_increments:
        assert property (read_pointer_increments)
        else $error("ASSERTION: read pointer did not increment correctly");

    assert_read_pointer_holds:
        assert property (read_pointer_holds)
        else $error(
            "ASSERTION: read pointer changed without an accepted read"
        );

endmodule