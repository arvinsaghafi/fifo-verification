# Synchronous FIFO Verification

A parameterized synchronous FIFO written in SystemVerilog, with a non-UVM verification environment developed step by step.

A FIFO (First In, First Out) stores data and returns it in the same order it was written.

## Goal

Practice RTL design and verification using directed tests, constrained-random stimulus, reference-model scoreboarding, SystemVerilog Assertions, and functional coverage.

## FIFO specification

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

Operation acceptance uses the FIFO state immediately before the rising clock edge.

When read and write are requested together:

* Empty: only the write succeeds.
* Full: only the read succeeds.
* Otherwise: both succeed, leaving occupancy unchanged.

## Project structure

* `rtl/fifo.sv`: Parameterized FIFO hardware implementation.
* `tb/fifo_if.sv`: Interface connecting the DUT and verification components.
* `tb/transaction.sv`: Parameterized FIFO transaction class.
* `tb/generator.sv`: Constrained-random transaction generator.
* `tb/driver.sv`: Applies generated transactions to the interface.
* `tb/monitor.sv`: Passively observes FIFO activity.
* `tb/scoreboard.sv`: Queue-based reference model and automatic checker.
* `tb/tb_top.sv`: Testbench construction and directed tests.
* `assertions/fifo_sva.sv`: SystemVerilog Assertions for FIFO properties.

## Verification architecture

* Interface: Groups the FIFO control, data, and status signals. Modports define access for the DUT, driver, and monitor.
* Transaction: Represents one cycle of requested and observed FIFO activity.
* Generator: Creates randomized transactions and sends them through a typed mailbox.
* Driver: Receives transactions and applies them through a virtual interface.
* Monitor: Samples requests, pre-edge status, and post-edge results before sending observations to the scoreboard.
* Scoreboard: Uses a SystemVerilog queue as an independent FIFO reference model and compares expected behavior against the DUT.
* Assertions: Continuously check reset, flags, occupancy, pointer behavior, and boundary conditions.
* Directed-test tasks: Drive specific write, read, and simultaneous operations while keeping signal driving separate from checking.

## Directed verification

The directed test suite covers:

* Reset behavior.
* Single write and read.
* Filling the FIFO until full.
* Draining the FIFO until empty.
* Writes attempted while full.
* Reads attempted while empty.
* Simultaneous read and write.
* Reset while read and write are requested.
* Write-pointer and read-pointer wraparound.
* Simultaneous read/write while empty.
* Simultaneous read/write while full.
* FIFO ordering and flag behavior throughout these cases.

The complete directed test suite passes for:

* `DATA_WIDTH = 8`, `DEPTH = 8`: Default configuration.
* `DATA_WIDTH = 8`, `DEPTH = 5`: Non-power-of-two depth.
* `DATA_WIDTH = 16`, `DEPTH = 5`: Wider data and non-power-of-two depth.
* `DATA_WIDTH = 8`, `DEPTH = 2`: Smallest currently supported depth.

## Constrained-random verification

The generator currently produces 100 transactions per test.

Operation selection is weighted as follows:

* Idle: 10%.
* Read only: 35%.
* Write only: 35%.
* Simultaneous read/write: 20%.

The scoreboard automatically checks:

* FIFO data ordering.
* Accepted and rejected operations.
* Read-output behavior.
* Occupancy.
* Full and empty flags.
* Simultaneous boundary behavior.

Seeds `12345` and `67890` passed. Repeating a seed produces the same transaction sequence, allowing failures to be reproduced.

A temporary read-data corruption was injected into the monitor to confirm that the scoreboard detects incorrect data. The original code was restored afterward.

## SystemVerilog assertions

Assertions currently verify:

* Reset clears the FIFO state.
* `full` and `empty` are never asserted together.
* `empty` agrees with an occupancy of zero.
* `full` agrees with an occupancy equal to `DEPTH`.
* Occupancy remains within its legal range.
* Blocked reads and writes preserve the required state.
* Writes from empty make the FIFO non-empty.
* Reads from full make the FIFO non-full.
* Occupancy increments, decrements, or holds as required.
* Read and write pointers remain within range.
* Accepted operations increment or wrap their corresponding pointers.
* Rejected or absent operations leave their corresponding pointers unchanged.

A temporary write-pointer wraparound bug was injected into the RTL. The write-pointer assertion detected the bug before the resulting data corruption caused the directed test to fail. The correct RTL was then restored and passed all tests.

## Simulator

Directed tests were initially verified with Aldec Riviera-PRO 2025.04.

Class-based randomization, constrained-random verification, scoreboarding, and assertions were verified with Siemens QuestaSim 2025.2 because the Riviera-PRO EDU license does not enable the required advanced verification features.

## Running the testbench

1. Open EDA Playground.
2. Select SystemVerilog/Verilog and Siemens Questa.
3. Paste `rtl/fifo.sv` into the Design pane.
4. Paste `tb/tb_top.sv` into the main Testbench pane.
5. Add these as separate testbench files:

   * `fifo_if.sv`
   * `transaction.sv`
   * `generator.sv`
   * `driver.sv`
   * `monitor.sv`
   * `scoreboard.sv`
   * `fifo_sva.sv`
6. Set the simulator seed, for example: `-sv_seed 67890`.
7. Click Run.

Expected final output:
```
DIRECTED FIFO TESTS PASSED
RANDOM SELF-CHECKING TEST PASSED
ALL FIFO TESTS PASSED
```
## Next milestone

Add functional coverage for FIFO occupancy, operations, boundary conditions, and important state transitions.