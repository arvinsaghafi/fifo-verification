# Synchronous FIFO Verification

A parameterized synchronous FIFO written in SystemVerilog,
with a verification environment developed step by step.

A FIFO (First In, First Out) stores data and returns it in
the same order it was written.

## Goal

Practice RTL design and verification through directed tests,
a reference-model scoreboard, constrained-random stimulus,
assertions, and functional coverage.

## Initial specification

- Default data width: 8 bits.
- Default depth: 8 entries.
- All operations occur on the rising clock edge.
- Reset is synchronous and active-low (`rst_n`).
- Reset empties the FIFO and sets `rd_data` to zero.
- A write is accepted when `wr_en` is high and the FIFO is not full.
- A read is accepted when `rd_en` is high and the FIFO is not empty.
- An accepted read updates `rd_data` after the clock edge.
  Otherwise, `rd_data` holds its value, except during reset.
- Reset takes priority over reads and writes.

Acceptance uses the FIFO state immediately before the clock edge.
When read and write are requested together:
- Empty: only the write succeeds.
- Full: only the read succeeds.
- Otherwise: both succeed, leaving occupancy unchanged.

## Project structure

- `rtl/`: FIFO hardware implementation.
- `tb/`: testbench and verification components.

## Status

FIFO RTL implemented. Directed tests pass with DATA_WIDTH = 8
and DEPTH = 8 for:

- Reset: empty asserted, full cleared, and read output zero.
- Single write/read: correct data returned.
- Fill: full asserts only after the eighth write.
- Drain: all eight values return in the correct order.
- Empty asserts only after the final read.
- Write while full: flags remain correct and stored data is preserved.
- Read while empty: flags remain correct and read output holds its value.
- Simultaneous read/write: oldest data is returned, new data is stored, and occupancy remains unchanged.

Verified using Aldec Riviera-PRO 2025.04 on EDA Playground.

Next: test reset while the FIFO contains active data.

## Running the basic test

1. Open EDA Playground.
2. Select SystemVerilog/Verilog and Aldec Riviera-Pro.
3. Paste `rtl/fifo.sv` into the Design pane.
4. Paste `tb/tb_top.sv` into the Testbench pane.
5. Click Run.

Expected result: `DIRECTED FIFO TESTS PASSED`.