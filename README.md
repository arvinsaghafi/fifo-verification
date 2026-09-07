# Synchronous FIFO Verification

A parameterized synchronous FIFO written in SystemVerilog, with a verification environment developed step by step.

A FIFO (First In, First Out) stores data and returns it in the same order it was written.

## Goal

Practice RTL design and verification through directed tests, a reference-model scoreboard, constrained-random stimulus, assertions, and functional coverage.

## Initial specification

- Default data width: 8 bits.
- Default depth: 8 entries.
- All operations occur on the rising clock edge.
- Reset is synchronous and active-low (`rst_n`).
- Reset empties the FIFO and sets `rd_data` to zero.
- A write is accepted when `wr_en` is high and the FIFO is not full.
- A read is accepted when `rd_en` is high and the FIFO is not empty.
- An accepted read updates `rd_data` after the clock edge. Otherwise, `rd_data` holds its value, except during reset.
- Reset takes priority over reads and writes.

Acceptance uses the FIFO state immediately before the clock edge.

When read and write are requested together:

- Empty: only the write succeeds.
- Full: only the read succeeds.
- Otherwise: both succeed, leaving occupancy unchanged.

## Project structure

- `rtl/fifo.sv`: FIFO hardware implementation.
- `tb/fifo_if.sv`: interface connecting the DUT and testbench.
- `tb/transaction.sv`: parameterized FIFO transaction class.
- `tb/tb_top.sv`: directed tests and top-level testbench.

## Testbench structure

A SystemVerilog interface groups the FIFO control, data, and status signals shared between the DUT and testbench. Modports describe the signal directions from the DUT and testbench perspectives.

Reusable tasks drive one-cycle write, read, and simultaneous read/write requests. Test checks remain separate from signal driving.

A parameterized transaction class represents one cycle of FIFO stimulus and observed results. Transaction randomization has been tested, but randomized transactions do not drive the DUT yet.

## Status

The FIFO RTL and directed testbench are implemented. The directed tests cover:

- Reset: empty asserted, full cleared, and read output zero.
- Single write/read: correct data returned.
- Fill: full asserts after the final available entry is written.
- Drain: stored values return in FIFO order.
- Empty asserts only after the final read.
- Write while full: flags remain correct and stored data is preserved.
- Read while empty: flags remain correct and read output holds its value.
- Simultaneous read/write: oldest data is returned, new data is stored, and occupancy remains unchanged.
- Active reset: reset overrides pending reads and writes, clears occupancy, resets both pointers, and clears the read output.
- Pointer wraparound: interleaved reads and writes force both pointers to wrap while preserving FIFO order.
- Simultaneous read/write while empty: only the write succeeds and the read output holds its previous value.
- Simultaneous read/write while full: only the read succeeds and the attempted write is rejected.

The complete directed test suite passes for:

- `DATA_WIDTH = 8`, `DEPTH = 8` - default configuration.
- `DATA_WIDTH = 8`, `DEPTH = 5` - non-power-of-two depth.
- `DATA_WIDTH = 16`, `DEPTH = 5` - wider data and non-power-of-two depth.
- `DATA_WIDTH = 8`, `DEPTH = 2` - smallest currently supported depth.

Directed tests were verified with Aldec Riviera-PRO 2025.04. Class-based randomization was verified with Siemens QuestaSim 2025.2 because the Riviera-PRO EDU license does not enable advanced verification features.

Next: create a generator that produces randomized FIFO transactions.

## Running the testbench

1. Open EDA Playground.
2. Select SystemVerilog/Verilog and Siemens Questa.
3. Paste `rtl/fifo.sv` into the Design pane.
4. Paste `tb/tb_top.sv` into the main Testbench pane.
5. Add `fifo_if.sv` and `transaction.sv` as separate testbench files.
6. Click Run.

Expected output:
```
RANDOM TRANSACTION: wr_en=<random> rd_en=<random> wr_data=<random>
DIRECTED FIFO TESTS PASSED
```