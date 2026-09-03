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

Project setup in progress. RTL and tests are not implemented yet.