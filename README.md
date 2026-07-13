 
# SparseFlow — Sparse-Aware AI Compute Engine

> Full RTL-to-GDS2 ASIC accelerator for sparse matrix multiply

---

## What is SparseFlow?

SparseFlow is a custom hardware accelerator that skips zero operands
in matrix multiply at the hardware level. In pruned deep learning
models, 50-90% of weights are zero. Dense hardware wastes energy
multiplying by them. SparseFlow detects zeros via a 64-bit sparsity
bitmap and clock-gates individual MAC cells, saving switching power
proportionally to sparsity.

## Key numbers

| Parameter       | Value                  |
|-----------------|------------------------|
| Array size      | 8x8 = 64 MACs          |
| Peak throughput | 12.8 GMAC/s at 200 MHz |
| Operand width   | INT16 (16-bit)         |
| Accumulator     | 32-bit saturating      |
| Power reduction | ~3.4x at 70% sparsity  |
| Technology      | Nangate 45nm FreePDK   |
| Final output    | Real GDS2 layout file  |

## Toolchain

| Phase               | Tool                  | Machine   |
|---------------------|-----------------------|-----------|
| RTL writing         | VS Code               | Windows   |
| RTL simulation      | Vivado Xsim           | Windows   |
| UVM testbench       | Vivado Xsim (UVM 1.2) | Windows   |
| Formal verification | SymbiYosys            | Ubuntu VM |
| Synthesis           | Yosys via OpenROAD    | Ubuntu VM |
| Static timing       | OpenSTA via OpenROAD  | Ubuntu VM |
| Place and route     | OpenROAD              | Ubuntu VM |
| GDS viewer          | KLayout               | Ubuntu VM |

## Build status

- [x] Week 1 — Architecture spec + parameter package
- [x] Week 2 — Full RTL (5 modules)
- [x] Week 3 — UVM environment skeleton
- [ ] Week 4 — Scoreboard + coverage closure
- [ ] Week 5 — Formal verification
- [ ] Week 6 — Synthesis + static timing
- [ ] Week 7 — Place and route to GDS2
- [ ] Week 8 — Sign-off + benchmarks + report

## Repository structure


SparseFlow/

├── rtl/          <- all SystemVerilog RTL modules

├── tb/uvm/       <- UVM testbench components

├── tb/directed/  <- directed simulation tests

├── formal/       <- SymbiYosys SVA properties

├── syn/          <- Yosys synthesis scripts + SDC

├── pnr/          <- OpenROAD place and route config

├── results/      <- GDS2, timing reports, area reports

├── docs/         <- architecture spec + final report

└── scripts/      <- helper automation scripts

## Architecture — 5 RTL modules

| Module | File | Purpose |
|--------|------|---------|
| Parameter package | sparseflow_pkg.sv | Global parameters, FSM type, register map |
| MAC cell | sparse_mac.sv | Single multiply-accumulate with clock gating |
| Sparsity control | sparsity_ctrl.sv | Bitmap decoder, drives mac_en[63:0] |
| Input buffer | input_buffer.sv | Dual-port FIFO, holds input rows |
| Output buffer | output_buffer.sv | Accumulator bank, writeback control |
| Top level | sparseflow_top.sv | AXI4-Lite slave + top-level FSM |
EOF
