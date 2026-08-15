# Experiment Protocol — GB10 Hardware Probe

## Objective
Implement and run a secure CUDA C++ program (`probe.cu`) that queries the DGX Spark's GB10 GPU and cross-checks CUDA-reported memory against Linux-reported memory to demonstrate the UMA behavior.

## Primary outcome
A successful run produces:
- `probe` binary
- `probe.ptx` containing `probe_kernel`
- `results/probe_output.txt` with complete device properties and UMA cross-check

## Conditions
- Single device: GPU 0 (GB10)
- Compile target: `sm_121`
- PTX target: `compute_121`
- No shell execution inside `probe` (security constraint)

## Controls and ablations
- All CUDA calls are checked and reported; the program does not abort on non-fatal errors.
- `/proc/meminfo` is read with bounded `fgets` and `sscanf`.
- A small `probe_kernel` is launched to confirm the GPU can execute kernels and to provide a PTX symbol.

## Hardware
- DGX Spark (GB10 Grace Blackwell Superchip)
- 128 GiB LPDDR5X unified memory
- CUDA 13.0, driver 580.142

## Data
- Runtime queries from `cudaGetDeviceProperties`, `cudaDeviceGetAttribute`, `cudaMemGetInfo`.
- OS memory accounting from `/proc/meminfo`.

## Analysis plan
- Print all queried values in a readable table.
- Compare `cudaMemGetInfo` free/total with `MemAvailable`, `Buffers+Cached`, `SwapFree`.
- Explain why `cudaMemGetInfo` underreports free memory on UMA.

## Stopping rules
- Stop if `probe` fails to compile or if `probe_kernel` fails to launch.
- Stop if `probe_output.txt` is missing or does not contain the UMA cross-check.

## Pre-registration status
- [x] Protocol written before execution.
- [x] Security design reviewed (no popen/system, bounded buffers, literal format strings).
- [x] Build and run targets defined.
