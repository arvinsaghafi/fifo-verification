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

```
fifo-verification/
├── rtl/
│   └── fifo.sv          Parameterized FIFO hardware implementation
├── tb/
│   ├── fifo_if.sv       Interface connecting the DUT and verification components
│   ├── transaction.sv   Parameterized FIFO transaction class
│   ├── generator.sv     Targeted and constrained-random transaction generator
│   ├── driver.sv        Applies generated transactions to the interface
│   ├── monitor.sv       Passively observes FIFO activity
│   ├── scoreboard.sv    Queue-based reference model and automatic checker
│   ├── coverage.sv      Functional coverage collector
│   └── tb_top.sv        Testbench construction and directed tests
├── assertions/
│   └── fifo_sva.sv      SystemVerilog Assertions for FIFO properties
├── .gitignore
└── README.md
```

## Verification architecture

* **Interface:** Groups the FIFO control, data, and status signals. Modports define access for the DUT, driver, and monitor.
* **Transaction:** Represents one cycle of requested and observed FIFO activity.
* **Generator:** Produces targeted coverage stimulus followed by constrained-random transactions.
* **Driver:** Receives transactions through a typed mailbox and applies them using a virtual interface.
* **Monitor:** Samples requests, pre-edge status, and post-edge results.
* **Scoreboard:** Uses a SystemVerilog queue as an independent FIFO reference model and checks every monitored transaction.
* **Coverage collector:** Maintains a separate expected occupancy and samples user-defined coverage bins.
* **Assertions:** Continuously check reset, flags, occupancy, pointer movement, and boundary behavior.
* **Directed-test tasks:** Exercise specific FIFO operations while keeping signal driving separate from checking.

The monitor broadcasts every observation through two mailboxes. One copy goes to the scoreboard for correctness checking, while the other goes to the coverage collector for completeness measurement.

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

The directed suite passes for:

* `DATA_WIDTH = 8`, `DEPTH = 8`: Default configuration.
* `DATA_WIDTH = 8`, `DEPTH = 5`: Non-power-of-two depth.
* `DATA_WIDTH = 16`, `DEPTH = 5`: Wider data and non-power-of-two depth.
* `DATA_WIDTH = 8`, `DEPTH = 2`: Smallest currently supported depth.

## Self-checking verification

The scoreboard automatically checks:

* FIFO data ordering.
* Accepted and rejected operations.
* Read-output behavior.
* Expected occupancy.
* Full and empty flags.
* Simultaneous boundary behavior.

Every monitored transaction is compared against the independent queue-based reference model. The test fails automatically if the DUT produces an unexpected result.

## Constrained-random stimulus

The generator produces 100 constrained-random transactions per test.

Requested operations are weighted as follows:

* Idle: 10%.
* Read only: 35%.
* Write only: 35%.
* Simultaneous read/write: 20%.

Seeds `12345` and `67890` passed. Repeating a seed produces the same randomized transaction sequence, allowing failures to be reproduced.

## SystemVerilog Assertions

Assertions verify:

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

## Functional coverage

Functional coverage measures whether the testbench exercised every scenario defined in the verification plan.

The coverage model includes:

* All four requested operations: idle, read, write, and simultaneous read/write.
* All four accepted-operation outcomes: neither, read only, write only, and both.
* Every occupancy level from zero through `DEPTH`.
* Empty, partially full, and full states.
* Empty-to-non-empty and non-empty-to-empty transitions.
* Almost-full-to-full and full-to-almost-full transitions.
* A cross of FIFO state against requested operation.

A parameterized targeted sequence exercises:

* All four operations while empty.
* All four operations while partially full.
* Every occupancy level while filling.
* All four operations while full.
* Every occupancy level while draining.

The targeted sequence length is: `(2 × DEPTH) + 10`

The targeted sequence ensures that the planned coverage bins are exercised. Constrained-random traffic follows the targeted sequence to provide additional sequence and data variation.

## Verification results

| Data width | Depth | Targeted transactions | Random transactions | Total | Functional coverage |
| ---------: | ----: | --------------------: | ------------------: | ----: | ------------------: |
|          8 |     8 |                    26 |                 100 |   126 |                100% |
|         16 |     5 |                    20 |                 100 |   120 |                100% |
|          8 |     2 |                    14 |                 100 |   114 |                100% |

All listed configurations passed the scoreboard and SystemVerilog Assertions with zero errors.

Reaching 100% functional coverage means that every currently defined coverage bin was hit. It does not account for scenarios that are not included in the coverage model.

## Simulator

Directed tests were verified with Aldec Riviera-PRO 2025.04.

The complete class-based verification environment, including constrained randomization, scoreboarding, assertions, and functional coverage, was verified with Siemens QuestaSim 2025.2.

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
   * `coverage.sv`
   * `fifo_sva.sv`
6. Set the simulator seed, for example `-sv_seed 67890`.
7. Click Run.

Expected final output for the default configuration:

```text
DIRECTED FIFO TESTS PASSED
COVERAGE: sampled=126 overall=100.00%
COVERAGE: requested operations=100.00%
COVERAGE: accepted operations=100.00%
COVERAGE: occupancy levels=100.00%
COVERAGE: boundary states=100.00%
COVERAGE: occupancy transitions=100.00%
COVERAGE: state-operation cross=100.00%
TARGETED AND RANDOM SELF-CHECKING TEST PASSED
ALL FIFO TESTS PASSED
```

## Next milestone

Automate regression testing across multiple FIFO configurations and random seeds.