# Synchronous FIFO Verification

A parameterized synchronous FIFO written in SystemVerilog, with a verification environment developed step by step.

A FIFO (First In, First Out) stores data and returns it in the same order it was written.

## Goal

Practice RTL design and verification through directed testing, constrained-random stimulus, transaction-based components, reference-model scoreboarding, assertions, and functional coverage.

## Initial specification

* Default data width: 8 bits.
* Default depth: 8 entries.
* All operations occur on the rising clock edge.
* Reset is synchronous and active-low (`rst_n`).
* Reset empties the FIFO and sets `rd_data` to zero.
* A write is accepted when `wr_en` is high and the FIFO is not full.
* A read is accepted when `rd_en` is high and the FIFO is not empty.
* An accepted read updates `rd_data` after the clock edge.
* Otherwise, `rd_data` holds its value, except during reset.
* Reset takes priority over reads and writes.

Operation acceptance uses the FIFO state immediately before the clock edge.

When read and write are requested together:

* Empty: only the write succeeds.
* Full: only the read succeeds.
* Otherwise: both succeed, leaving occupancy unchanged.

## Project structure

* `rtl/fifo.sv`: parameterized FIFO hardware implementation.
* `tb/fifo_if.sv`: interface and modports connecting verification components to the DUT.
* `tb/transaction.sv`: parameterized FIFO transaction class.
* `tb/generator.sv`: randomized transaction generator.
* `tb/driver.sv`: transaction-level driver.
* `tb/monitor.sv`: passive interface monitor.
* `tb/scoreboard.sv`: queue-based reference model and automatic checker.
* `tb/tb_top.sv`: DUT instantiation, component connections, and directed tests.

## Testbench structure

The verification environment is organized into reusable components:

* Interface: Groups the FIFO control, data, and status signals. Modports define how the DUT, driver, and monitor access these signals.
* Transaction: Represents one cycle of requested and observed FIFO activity.
* Generator: Creates randomized transactions and sends them through a typed mailbox.
* Driver: Receives generated transactions and applies them to the interface through a virtual interface.
* Monitor: Passively samples FIFO requests, pre-edge state, and post-edge results, then forwards its observations through a separate mailbox.
* Scoreboard: Maintains an independent SystemVerilog queue representing the expected FIFO contents. It checks read data, occupancy, and the full and empty flags.
* Directed-test tasks: Drive specific write, read, and simultaneous operations while keeping signal driving separate from result checking.

The generator, driver, monitor, and scoreboard run concurrently. Typed mailboxes connect the generator to the driver and the monitor to the scoreboard.

## Status

The FIFO RTL and directed testbench are implemented. The directed tests cover:

* Reset: empty asserted, full cleared, and read output zero.
* Single write/read: correct data returned.
* Fill: full asserts after the final available entry is written.
* Drain: stored values return in FIFO order.
* Empty asserts only after the final read.
* Write while full: flags remain correct and stored data is preserved.
* Read while empty: flags remain correct and read output holds its value.
* Simultaneous read/write: oldest data is returned, new data is stored, and occupancy remains unchanged.
* Active reset: reset overrides pending reads and writes, clears occupancy, resets both pointers, and clears the read output.
* Pointer wraparound: interleaved reads and writes force both pointers to wrap while preserving FIFO order.
* Simultaneous read/write while empty: only the write succeeds and the read output holds its previous value.
* Simultaneous read/write while full: only the read succeeds and the attempted write is rejected.

The complete directed test suite passes for:

* `DATA_WIDTH = 8`, `DEPTH = 8` - default configuration.
* `DATA_WIDTH = 8`, `DEPTH = 5` - non-power-of-two depth.
* `DATA_WIDTH = 16`, `DEPTH = 5` - wider data and non-power-of-two depth.
* `DATA_WIDTH = 8`, `DEPTH = 2` - smallest currently supported depth.

The transaction-based environment currently:

* Randomizes FIFO transaction objects.
* Transfers transactions from the generator to the driver.
* Drives randomized requests through a virtual interface.
* Captures requests and DUT results with a passive monitor.
* Sends observations to the scoreboard through a second mailbox.
* Models expected FIFO contents using an independent queue.
* Checks read data and pre-edge and post-edge status flags.
* Detects blocked reads and writes using the reference-model occupancy.
* Confirms that all generated and observed transactions are consumed.
* Reports the total checked transactions and detected errors.

A five-transaction self-checking random test passes with zero scoreboard errors. The scoreboard was also tested using deliberate data corruption and correctly detected every injected mismatch.

Directed tests were verified with Aldec Riviera-PRO 2025.04. Class-based randomization and transaction components were verified with Siemens QuestaSim 2025.2 because the Riviera-PRO EDU license does not enable advanced verification features.

Next: expand the randomized test, introduce stimulus constraints, and make failures reproducible using simulator seeds.

## Running the testbench

1. Open EDA Playground.
2. Select SystemVerilog/Verilog and Siemens Questa.
3. Paste `rtl/fifo.sv` into the Design pane.
4. Paste `tb/tb_top.sv` into the main Testbench pane.
5. Add the following as separate testbench files:
   * `fifo_if.sv`
   * `transaction.sv`
   * `generator.sv`
   * `driver.sv`
   * `monitor.sv`
   * `scoreboard.sv`
6. Ensure `tb_top.sv` includes those files in the same order.
7. Click Run.

Randomized values will vary between seeds. A successful run ends with:
```
DIRECTED FIFO TESTS PASSED
RANDOM SELF-CHECKING TEST PASSED
ALL FIFO TESTS PASSED
```