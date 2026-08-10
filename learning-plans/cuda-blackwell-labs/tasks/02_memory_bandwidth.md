# Task 02: Memory Bandwidth & Latency Lab

**Phase:** 1 — Hardware and Memory Literacy
**Prerequisites:** Task 01 (GB10 Hardware Probe)
**Estimated sessions:** 3-4

---

## Objective

Implement a suite of memory access kernels and measure effective bandwidth across different patterns, working-set sizes, strides, and allocation types. Build a complete picture of your GB10's memory behavior.

## Why This Matters

Your GB10 has 273 GB/s peak LPDDR5X bandwidth, but sustained bandwidth under load is ~180 GB/s for reads and ~116 GB/s for writes. Under inference load, read bandwidth drops to ~90 GB/s. Most CUDA performance problems are memory problems. This lab teaches you to diagnose them.

## Instructions

### Part A: Implement These Kernels

```cpp
__global__ void sequential_read(const float* in, float* out, int n);
__global__ void sequential_write(const float* in, float* out, int n);
__global__ void read_write_copy(const float* in, float* out, int n);
__global__ void saxpy(const float* x, float* y, float a, int n);
__global__ void strided_read(const float* in, float* out, int n, int stride);
__global__ void random_read(const float* in, float* out, const int* indices, int n);
__global__ void coalesced_access(const float* in, float* out, int n);
__global__ void non_coalesced_access(const float* in, float* out, int n);
__global__ void atomic_accumulate(const float* in, float* result, int n);
```

### Part B: Measure Effective Bandwidth

For each kernel, calculate:

```
effective_bandwidth = bytes_read_and_written / kernel_time_seconds
```

Use CUDA events for timing:
```cpp
cudaEventRecord(start, stream);
kernel<<<grid, block, 0, stream>>>(...);
cudaEventRecord(stop, stream);
cudaEventSynchronize(stop);
cudaEventElapsedTime(&ms, start, stop);
```

### Part C: Sweep These Variables

1. **Working-set size:** 1 KB, 4 KB, 16 KB, 64 KB, 256 KB, 1 MB, 4 MB, 16 MB, 64 MB, 256 MB, 1 GB, 4 GB, 16 GB, 64 GB
2. **Stride:** 1, 2, 4, 8, 16, 32, 64, 128
3. **Block size:** 32, 64, 128, 256, 512, 1024
4. **Allocation type:** `cudaMalloc`, `cudaMallocManaged`, `cudaHostAlloc` (pinned)

### Part D: Compare to Theoretical Peak

Print a table:
```
Kernel          | Working Set | Bandwidth (GB/s) | % of Peak (273)
----------------|-------------|------------------|----------------
sequential_read | 1 KB        | 0.5              | 0.18%
sequential_read | 1 MB        | 45.2             | 16.6%
sequential_read | 1 GB        | 178.3            | 65.3%
...
```

### Part E: Profile with Nsight Compute

For at least 3 kernels, run:
```bash
ncu --set full --target-processes all ./bandwidth_test
```

Look at:
- `gpc__cycles_elapsed.max`
- `dram__bytes_read.sum`
- `dram__bytes_write.sum`
- `l1tex__t_bytes.sum`
- `lts__t_bytes.sum`
- `sm__warps_active.avg.per_cycle_active`

### Part F: The UMA Experiment

On GB10, CPU and GPU share memory. Test:
1. Allocate with `cudaMalloc` — measure bandwidth
2. Allocate with `cudaMallocManaged` — measure bandwidth (first access, second access)
3. Allocate with `malloc` (host) — access from GPU via managed memory — measure bandwidth
4. Run a CPU thread that hammers memory while GPU kernel runs — measure bandwidth degradation

## Deliverable

A report containing:

1. **Graph: working-set size vs bandwidth** for sequential_read, sequential_write, read_write_copy
2. **Graph: stride vs bandwidth** for strided_read at 64 MB working set
3. **Graph: block size vs bandwidth** for sequential_read at 64 MB
4. **Table: allocation type vs bandwidth** for sequential_read at 256 MB
5. **Table: UMA contention** — GPU-only vs GPU+CPU bandwidth
6. **Profiler output** for 3 kernels with explanation of each metric
7. **Written analysis** answering:
   - At what working-set size does bandwidth plateau?
   - What stride causes bandwidth to drop by 50%?
   - How much bandwidth is lost to CPU contention on UMA?
   - What is your measured sustained bandwidth vs the 273 GB/s peak?

## Acceptance Criteria

- [ ] All 9 kernels implemented and verified correct against CPU reference
- [ ] Working-set sweep covers 1 KB to 64 GB
- [ ] Stride sweep covers 1 to 128
- [ ] Block size sweep covers 32 to 1024
- [ ] 3 allocation types tested
- [ ] UMA contention experiment completed
- [ ] Nsight Compute output captured for 3 kernels
- [ ] Report with 4 graphs and 2 tables produced
- [ ] Written analysis answers all 4 questions

## Resources

- [CUDA C++ Best Practices Guide §10: Memory Optimizations](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#memory-optimizations)
- [CUDA C++ Best Practices Guide §10.2.1: Coalesced Access](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#coalesced-access-to-global-memory)
- [DGX Spark Optimization Guide](https://docs.nvidia.com/dgx/dgx-spark-porting-guide/optimization.html)
- [NVIDIA accelerated-computing-hub Part 1](https://github.com/NVIDIA/accelerated-computing-hub/tree/main/tutorials/cuda-cpp) — notebooks on memory spaces

## AI Agent Prompt Template

```
I need to implement a CUDA memory bandwidth benchmark suite for my GB10 DGX Spark 
(SM121, 273 GB/s peak LPDDR5X, unified memory). The suite should test:
- sequential read/write/copy, saxpy, strided read, random read
- coalesced vs non-coalesced access, atomic accumulation
- working-set sizes from 1KB to 64GB
- strides from 1 to 128
- block sizes from 32 to 1024
- allocation types: cudaMalloc, cudaMallocManaged, cudaHostAlloc

Use CUDA events for timing. Calculate effective_bandwidth = bytes / time.
Compile with: nvcc -arch=sm_121 -lineinfo

The GB10 has unified LPDDR5X memory shared between CPU and GPU, NOT HBM.
Do not assume discrete GPU behavior.
```
