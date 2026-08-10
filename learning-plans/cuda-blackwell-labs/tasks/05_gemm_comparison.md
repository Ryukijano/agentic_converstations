# Task 05: Five-Way GEMM Comparison

**Phase:** 2 — Compiler and SM Literacy
**Prerequisites:** Task 03, Task 04
**Estimated sessions:** 5-7

---

## Objective

Implement matrix multiplication (GEMM) five different ways, benchmark all of them, and explain the performance gap at each level using profiler evidence.

## Why This Matters

GEMM is the most important kernel in deep learning. Every linear layer, attention computation, and convolution reduces to GEMM. Understanding why cuBLAS is 50x faster than naive CUDA teaches you everything about memory hierarchy, tiling, Tensor Cores, and library design.

## Instructions

### Part A: Implement Five GEMMs

#### 1. Naive CUDA GEMM

```cpp
__global__ void naive_gemm(const float* A, const float* B, float* C, int M, int N, int K) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (row < M && col < N) {
        float sum = 0.0f;
        for (int k = 0; k < K; k++) sum += A[row * K + k] * B[k * N + col];
        C[row * N + col] = sum;
    }
}
```

#### 2. Tiled Shared Memory GEMM

Implement the classic tiled GEMM with shared memory:
- Load tiles of A and B into shared memory
- Synchronize
- Compute partial products
- Accumulate
- Synchronize
- Repeat for next K-tile

Use 16x16 or 32x32 tile sizes.

#### 3. cuBLAS GEMM

```cpp
cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N, M, K, &alpha, B, N, A, K, &beta, C, N);
```

#### 4. CUTLASS GEMM

Use CUTLASS 4.x with CuTe. Start with a basic GEMM:
```cpp
#include <cute/tensor.hpp>
// Use CuTe layouts and tensors to define the GEMM
```

If CUTLASS C++ templates are too complex, try the CuTe DSL (Python-based):
```python
from cutlass.cute import ...
```

Compile CUTLASS for SM121:
```bash
cmake .. -DCUTLASS_NVCC_ARCHS=121
```

**Important:** Check that CUTLASS supports SM121. Some FP4 paths may produce garbage on SM121. Use FP16 or BF16 for safety.

#### 5. PyTorch matmul

```python
import torch
C = torch.matmul(A, B)
```

Use `torch.cuda.synchronize()` before timing.

### Part B: Benchmark All Implementations

Test matrix sizes: 128x128, 256x256, 512x512, 1024x1024, 2048x2048, 4096x4096, 8192x8192

For each implementation and size, measure:
- Kernel time (CUDA events)
- TFLOP/s: `2 * M * N * K / time_seconds / 1e12`
- Memory bandwidth: `bytes_accessed / time`
- Correctness: max absolute error vs CPU reference

### Part C: Test Multiple Precisions

Repeat for:
- FP32 (`float`, `cublasSgemm`)
- TF32 (if supported on SM121 — check with `cudaDeviceGetAttribute`)
- FP16 (`half`, `cublasGemmEx` with `CUDA_R_16F`)
- BF16 (`__nv_bfloat16`, `cublasGemmEx` with `CUDA_R_16BF`)
- FP8 (`__nv_fp8_e4m3`, if supported on SM121 — verify carefully)

**GB10 Warning:** FP4 CUTLASS paths may produce silent garbage on SM121. Test FP4 only after verifying correctness with a small matrix.

### Part D: Profile Each Implementation

For each GEMM at 4096x4096, run:
```bash
ncu --set full --kernel-name regex:"gemm" ./gemm_test
```

Capture:
- Tensor Core utilization (if used)
- Memory bandwidth utilization
- Occupancy
- Register count
- Shared memory usage
- L2 cache hit rate
- DRAM throughput

### Part E: Explain the Performance Gap

Create a table:
```
Implementation | Time (ms) | TFLOP/s | % of cuBLAS | Key bottleneck
---------------|-----------|---------|-------------|----------------
Naive CUDA     | 1250      | 0.11    | 2%          | Global memory bandwidth
Tiled SMEM     | 85        | 1.6     | 28%         | Shared memory bank conflicts
cuBLAS         | 24        | 5.7     | 100%        | (baseline)
CUTLASS        | 26        | 5.3     | 92%         | Template overhead
PyTorch        | 25        | 5.5     | 96%         | cuBLAS dispatch overhead
```

For each gap, explain which hardware resource is the bottleneck.

## Deliverable

1. **Performance table**: 5 implementations x 7 matrix sizes x 5 precisions
2. **TFLOP/s graph**: matrix size on x-axis, TFLOP/s on y-axis, one line per implementation
3. **Precision comparison table**: for 4096x4096, TFLOP/s and error for each precision
4. **Profiler comparison**: Nsight Compute metrics for all 5 implementations at 4096x4096
5. **Written analysis** explaining:
   - Why naive is slow (which specific memory behavior?)
   - Why tiling helps (how much bandwidth is saved?)
   - Why cuBLAS is faster than tiled (what does it do that you don't?)
   - Whether Tensor Cores are being used (which precision triggers them?)
   - What CUTLASS does differently from your tiled version

## Acceptance Criteria

- [ ] All 5 GEMM implementations working and correct
- [ ] 7 matrix sizes benchmarked
- [ ] At least 3 precisions tested (FP32, FP16, BF16)
- [ ] FP8 tested if supported on SM121 (with correctness verification)
- [ ] Nsight Compute profiles for all 5 at 4096x4096
- [ ] Performance gap explained with profiler evidence
- [ ] Tensor Core utilization identified (which implementation uses them?)

## Resources

- [CUTLASS Documentation](https://docs.nvidia.com/cutlass/latest/overview.html)
- [CuTe Quickstart](https://docs.nvidia.com/cutlass/latest/media/docs/cpp/cute/00_quickstart.html)
- [CuTe GEMM Tutorial](https://docs.nvidia.com/cutlass/latest/media/docs/cpp/cute/0x_gemm_tutorial.md)
- [CUTLASS Quickstart](https://docs.nvidia.com/cutlass/latest/media/docs/cpp/quickstart.html)
- [cuBLAS Documentation](https://docs.nvidia.com/cuda/cublas/)
- [CUDA C++ Best Practices Guide §10.2.3: Shared Memory in Matrix Multiplication](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#shared-memory-in-matrix-multiplication-c-ab)
- [Ammar-Alnagar/AI-Kernel-learning](https://github.com/Ammar-Alnagar/AI-Kernel-learning) — CUTLASS learning path

## AI Agent Prompt Template

```
I need to implement GEMM (matrix multiplication) five different ways on my GB10 
DGX Spark (SM121, Blackwell, 273 GB/s LPDDR5X):

1. Naive CUDA kernel (one thread per output element)
2. Tiled shared memory GEMM (16x16 or 32x32 tiles)
3. cuBLAS Sgemm
4. CUTLASS 4.x GEMM (compile with -DCUTLASS_NVCC_ARCHS=121)
5. PyTorch torch.matmul

Benchmark for matrix sizes: 128 to 8192 (powers of 2)
Test precisions: FP32, FP16, BF16, FP8 (if supported on SM121)

IMPORTANT: SM121 (GB10) does NOT support TMEM, WGMMA, or DSMEM.
Some CUTLASS FP4 paths may produce garbage on SM121. Use FP16/BF16 for safety.
Compile with: nvcc -arch=sm_121 -lineinfo

For each implementation, I need: time (ms), TFLOP/s, max error vs CPU.
```
