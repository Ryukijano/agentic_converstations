# Project 1 — GB10 Hardware Probe

This directory contains the implementation of the first CUDA Blackwell Labs project.

## Files

| File | Purpose |
|------|---------|
| `probe.cu` | CUDA C++ hardware probe |
| `Makefile` | Build `probe`, generate `probe.ptx`, and run |
| `protocol.md` | Experiment protocol for this project |
| `results/probe_output.txt` | Output from a successful run |

## Build and run

```bash
make all
make run
make verify
```

- `make all` compiles `probe` and generates `probe.ptx`.
- `make run` runs `probe` and appends `free -h`, `nvidia-smi`, and `numactl` output to `results/probe_output.txt`.
- `make verify` checks that all artifacts exist and that `probe.ptx` contains the `probe_kernel` symbol.

## Security notes

- `probe.cu` does not use `popen()`, `system()`, or any shell execution.
- All `printf`/`fprintf` calls use literal format strings.
- `/proc/meminfo` is read with bounded buffers and `sscanf`.
- The optional log-path argument is validated (no leading `-`, no `..`).

## UMA summary

The GB10 on DGX Spark shares 128 GiB of LPDDR5X between the CPU and GPU. `cudaMemGetInfo()` returns only the memory the CUDA driver currently considers free, which is smaller than the OS-reported allocatable memory because the OS can reclaim page cache, buffers, and swap-backed pages. This project captures both numbers and explains the difference.
