# Task 04: Occupancy & Stall Experiments

**Phase:** 2 — Compiler and SM Literacy
**Prerequisites:** Task 02, Task 03
**Estimated sessions:** 4-5

---

## Objective

Systematically vary register pressure, shared memory usage, block size, and divergence to understand how the SM schedules warps. Use Nsight Compute to identify stall reasons and prove that high occupancy does not always mean high performance.

## Why This Matters

Most CUDA tutorials say "maximize occupancy" without explaining when that advice is wrong. This lab teaches you to read Nsight Compute metrics and understand what is actually limiting your kernel. On GB10 with 6,144 CUDA cores and 273 GB/s bandwidth, the bottleneck is usually memory, not compute — but you need to prove it.

## Instructions

### Part A: Register Pressure Experiment

Write a kernel that uses a configurable number of registers:

```cpp
template<int N_REGS>
__global__ void register_pressure(float* out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    float regs[N_REGS];
    #pragma unroll
    for (int j = 0; j < N_REGS; j++) regs[j] = (float)(i + j);
    // Prevent optimization
    float sum = 0;
    #pragma unroll
    for (int j = 0; j < N_REGS; j++) sum += regs[j] * 0.001f;
    out[i] = sum;
}
```

Instantiate for N_REGS = 8, 16, 32, 64, 96, 128, 160, 192, 255.

For each:
- Compile with `-lineinfo`
- Check register count: `cuobjdump --dump-resource-usage`
- Calculate theoretical occupancy: `min(SM_registers / (regs_per_thread * threads_per_block), ...)`
- Measure achieved occupancy with `ncu`
- Measure kernel time

### Part B: Shared Memory Experiment

Write a kernel that uses configurable shared memory:

```cpp
template<int SMEM_BYTES>
__global__ void shared_mem_pressure(float* out, int n) {
    __shared__ float smem[SMEM_BYTES / sizeof(float)];
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    smem[threadIdx.x] = (float)i;
    __syncthreads();
    if (i < n) out[i] = smem[threadIdx.x];
}
```

Sweep SMEM_BYTES from 1 KB to 128 KB (if supported on SM121).
Sweep block size: 32, 64, 128, 256, 512, 1024.

For each combination:
- Calculate theoretical occupancy
- Measure achieved occupancy
- Measure kernel time

### Part C: Warp Divergence Experiment

Write kernels with different divergence patterns:

```cpp
__global__ void no_divergence(float* out, int n) { ... }  // all threads take same branch
__global__ void half_divergence(float* out, int n) { ... } // half threads take each branch
__global__ void full_divergence(float* out, int n) { ... } // every thread takes different branch
__global__ void interleaved_divergence(float* out, int n) { ... } // odd/even threads diverge
```

Measure:
- Warp issue efficiency
- Branch efficiency
- Diverged branches per warp

### Part D: Instruction Dependency Experiment

Write kernels with different dependency chain lengths:

```cpp
__global__ void short_chain(float* out, int n) {
    // Each iteration depends on previous
    float x = 1.0f;
    for (int j = 0; j < 4; j++) x = x * 1.001f + 0.001f;
    out[blockIdx.x * blockDim.x + threadIdx.x] = x;
}

__global__ void long_chain(float* out, int n) {
    float x = 1.0f;
    for (int j = 0; j < 32; j++) x = x * 1.001f + 0.001f;
    out[blockIdx.x * blockDim.x + threadIdx.x] = x;
}

__global__ void independent_ops(float* out, int n) {
    // Independent operations — no dependency chain
    float x0 = 1.0f, x1 = 2.0f, x2 = 3.0f, x3 = 4.0f;
    for (int j = 0; j < 8; j++) {
        x0 = x0 * 1.001f;
        x1 = x1 * 1.001f;
        x2 = x2 * 1.001f;
        x3 = x3 * 1.001f;
    }
    out[blockIdx.x * blockDim.x + threadIdx.x] = x0 + x1 + x2 + x3;
}
```

### Part E: Nsight Compute Deep Dive

For each kernel above, run:
```bash
ncu --set full --target-processes all \
    --metrics sm__warps_active.avg.per_cycle_active,\
smsp__warps_eligible.avg.per_cycle_active,\
smsp__inst_executed.avg.per_cycle_active,\
smsp__average_warps_issue_stalled_long_scoreboard_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_short_scoreboard_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_membar_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_lg_throttle_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_drain_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_branch_resolving_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_imc_miss_per_issue_active.ratio,\
smsp__average_warps_issue_stalled_misc_per_issue_active.ratio \
    ./your_binary
```

Document the primary stall reason for each kernel.

### Part F: The "High Occupancy ≠ Fast" Proof

Design 3 kernel pairs where:
1. Kernel A has higher occupancy but is slower
2. Kernel B has lower occupancy but is faster
3. Explain why in each case

Example: A memory-bound kernel with 100% occupancy vs the same kernel with 50% occupancy but better coalescing.

## Deliverable

1. **Register pressure table**: N_REGS, register count, theoretical occupancy, achieved occupancy, kernel time
2. **Shared memory table**: SMEM_BYTES, block size, theoretical occupancy, achieved occupancy, kernel time
3. **Divergence table**: kernel, branch efficiency, diverged branches, kernel time
4. **Dependency table**: kernel, primary stall reason, eligible warps/cycle, kernel time
5. **3 "high occupancy ≠ fast" cases** with profiler evidence and written explanation
6. **Stall reason breakdown** for at least 5 kernels

## Acceptance Criteria

- [ ] Register pressure sweep from 8 to 255 registers
- [ ] Shared memory sweep from 1 KB to max
- [ ] 4 divergence patterns tested
- [ ] 3 dependency chain lengths tested
- [ ] Nsight Compute stall metrics captured for all kernels
- [ ] 3 cases where high occupancy ≠ fast, with profiler evidence
- [ ] Written explanation for each stall reason

## Resources

- [Blackwell Tuning Guide](https://docs.nvidia.com/cuda/blackwell-tuning-guide/)
- [CUDA C++ Best Practices Guide §11: Execution Configuration](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#execution-configuration-optimizations)
- [CUDA C++ Best Practices Guide §12: Instruction Optimization](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#instruction-optimizations)
- [Nsight Compute documentation](https://docs.nvidia.com/nsight-compute/)

## AI Agent Prompt Template

```
I need to design CUDA experiments that demonstrate occupancy vs performance on my 
GB10 DGX Spark (SM121). Specifically I need:

1. A kernel with configurable register pressure (template parameter for N_REGS)
2. A kernel with configurable shared memory usage
3. Kernels with different warp divergence patterns (none, half, full, interleaved)
4. Kernels with different instruction dependency chain lengths

For each, I need to measure:
- Theoretical and achieved occupancy
- Primary stall reason (using ncu stall metrics)
- Kernel execution time

I also need 3 cases where higher occupancy does NOT mean faster performance.

Compile with: nvcc -arch=sm_121 -lineinfo
Profile with: ncu --set full

The GB10 has 6144 CUDA cores, 273 GB/s LPDDR5X bandwidth, unified memory.
```
