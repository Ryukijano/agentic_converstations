# Task 01: GB10 Hardware Probe

**Phase:** 1 — Hardware and Memory Literacy
**Prerequisites:** None (this is the first project)
**Estimated sessions:** 1-2

---

## Objective

Write a C++/CUDA program that interrogates your DGX Spark's GB10 GPU and reports every relevant hardware property. Then compare CUDA-reported memory against Linux-reported memory to understand the unified memory architecture.

## Why This First

You cannot optimize what you have not measured. Before writing any kernels, you need a complete picture of what the GB10 actually is — not what marketing materials say, but what the driver reports. This project also teaches you the CUDA Runtime API's device query functions, which you will use in every subsequent project.

## Instructions

### Part A: Device Properties Query

Write `probe.cu` that calls the following and prints results in a formatted table:

```cpp
cudaGetDeviceCount()
cudaGetDeviceProperties(&prop, 0)  // for every field
cudaDeviceGetAttribute(...)        // for every attribute below
```

Report at minimum:
- Device name
- Compute capability (major.minor)
- SM count (`cudaDevAttrMultiProcessorCount`)
- Warp size
- Max threads per block
- Max threads per SM
- Max threads per block per dimension
- Shared memory per block (default and max)
- Shared memory per SM
- Total constant memory
- Register file size per block
- Register file size per SM
- L2 cache size
- Memory clock rate
- Memory bus width
- Peak memory bandwidth (calculated: clock * width * 2 / 8)
- Concurrent kernels support
- Async engine count
- Unified addressing support
- Managed memory support
- Memory pools support
- Cooperative launch support
- Graph support
- Multi-device support
- PCI bus ID
- TCC driver mode

### Part B: Memory Cross-Check

Report all of the following and explain discrepancies:

```cpp
cudaMemGetInfo(&free_bytes, &total_bytes)
```

```bash
cat /proc/meminfo    # MemTotal, MemFree, MemAvailable, Buffers, Cached, SwapTotal, SwapFree
numactl --hardware   # if available
free -h
nvidia-smi --query-gpu=memory.total,memory.free,memory.used --format=csv
```

### Part C: The UMA Lesson

On GB10's unified memory architecture, `cudaMemGetInfo()` does not report all memory that could become available because the OS can reclaim page cache and swap. NVIDIA's DGX Spark optimization guide explicitly calls this out.

Your program should print:
```
CUDA-reported free memory:     XXX GB
CUDA-reported total memory:    XXX GB
Linux available memory:        XXX GB
Linux page cache:              XXX GB
Swap available:                XXX GB
Theoretical allocatable:       XXX GB  (available + page cache + swap)
```

Then write a paragraph explaining why these numbers differ.

### Part D: Compilation

Compile with:
```bash
nvcc -arch=sm_121 -lineinfo probe.cu -o probe
```

Also try:
```bash
nvcc -arch=compute_121 -ptx probe.cu -o probe.ptx
```

Inspect the PTX file. You do not need to understand it yet — just confirm it exists and contains your kernel names.

## Acceptance Criteria

- [ ] `probe` runs and prints a complete device properties table
- [ ] Memory cross-check section shows all 6 memory figures
- [ ] Written explanation of UMA discrepancy (at least 3 sentences)
- [ ] `probe.ptx` file generated successfully
- [ ] Results saved to `results/probe_output.txt`

## Resources

- [DGX Spark Hardware Guide](https://docs.nvidia.com/dgx/dgx-spark/hardware.html)
- [DGX Spark Optimization Guide](https://docs.nvidia.com/dgx/dgx-spark-porting-guide/optimization.html)
- [CUDA Programming Guide: Device Management](https://docs.nvidia.com/cuda/cuda-programming-guide/)
- `cudaGetDeviceProperties` in `/usr/local/cuda/include/cuda_runtime_api.h`

## AI Agent Prompt Template

```
I need to write a CUDA C++ program that probes my NVIDIA DGX Spark (GB10, SM121, 
compute capability 12.1) and reports all device properties. The program should:
1. Call cudaGetDeviceProperties and print every field
2. Call cudaDeviceGetAttribute for all relevant attributes
3. Call cudaMemGetInfo and cross-check with /proc/meminfo
4. Explain the unified memory discrepancy

Compile with: nvcc -arch=sm_121 -lineinfo probe.cu -o probe

Do NOT use any features that don't exist on SM121 (no TMEM, no WGMMA, no DSMEM).
The GB10 has unified LPDDR5X memory, not HBM.
```
