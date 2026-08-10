# Task 06: Precision Lab (FP32 → FP4)

**Phase:** 2 — Compiler and SM Literacy
**Prerequisites:** Task 05
**Estimated sessions:** 4-5

---

## Objective

Benchmark representative neural network layers across all supported precisions (FP32, TF32, FP16, BF16, FP8, INT8, FP4) and build a precision suitability table that maps each operation to its best precision.

## Why This Matters

Your LinkedIn claims HPC depth and your prior work mentioned FP8 experiments. This lab turns that into rigorous, measured evidence. A model can advertise FP8 or FP4 support while still spending most of its runtime in FP16/FP32 memory movement, normalization, or conversion. You need to measure what actually happens.

## Instructions

### Part A: Benchmark These Operations

For each operation, implement in every supported precision:

1. **GEMM** (matrix multiply) — reuse from Task 05
2. **LayerNorm** (normalize along last dim)
3. **Softmax** (with max subtraction for numerical stability)
4. **Convolution** (2D conv, 3x3 kernel)
5. **Attention** (QK^T → softmax → AV, with and without flash attention)
6. **Reduction** (sum along an axis)
7. **Pointwise operations** (ReLU, GELU, SiLU)
8. **Point-cloud operations** (per-point transform — relevant to Endosight)

### Part B: For Each Operation × Precision, Measure

- **Throughput** (ops/s or TFLOP/s)
- **Memory footprint** (bytes for weights, activations, gradients)
- **Numerical error** (max abs error and mean abs error vs FP32 reference)
- **Kernel choice** (which kernel does PyTorch/cuDNN select?)
- **Tensor Core utilization** (from `ncu`)
- **Conversion overhead** (time spent casting between precisions)
- **End-to-end impact** (if this precision were used in a full model)

### Part C: Precision Implementation Details

```python
# FP32
torch.randn(M, K, dtype=torch.float32)

# TF32 (controlled by tensor float math mode)
torch.backends.cuda.matmul.allow_tf32 = True  # enables TF32 for FP32 matmul

# FP16
torch.randn(M, K, dtype=torch.float16)

# BF16
torch.randn(M, K, dtype=torch.bfloat16)

# FP8 (if supported)
# Use torch.float8_e4m3fn or transformer_engine
import transformer_engine.pytorch as te
# Or use native PyTorch FP8 if available

# INT8 (quantization)
# Use torch quantization or custom INT8 kernels

# FP4 (if supported on SM121 — VERIFY FIRST)
# CUTLASS FP4 paths may produce garbage on SM121
# Test with small matrix first, check correctness
```

### Part D: GB10-Specific Precision Checks

Before benchmarking FP8 and FP4, verify what SM121 actually supports:

```cpp
// Check Tensor Core support for each precision
cudaDeviceGetAttribute(&val, cudaDevAttrTensorCoresSupported, 0);
// Check compute capability
int major, minor;
cudaDeviceGetAttribute(&major, cudaDevAttrComputeCapabilityMajor, 0);
cudaDeviceGetAttribute(&minor, cudaDevAttrComputeCapabilityMinor, 0);
// SM121 = compute capability 12.1
```

Also check:
```bash
# What Tensor Core instructions are available in SASS?
cuobjdump --dump-sass your_fp8_kernel | grep -i "tc\|tensor"
```

**Critical:** The Conselara Labs reference notes that CUTLASS FP4 is "broken: silent garbage output" on GB10. Verify this yourself with a small test before trusting any FP4 results.

### Part E: The "Hidden FP32" Discovery

Many "FP8 models" still spend significant time in FP32. Discover this by:

1. Profile a model layer that claims FP8 execution
2. Look at all kernels launched (not just the GEMM)
3. Identify which kernels run in FP32 (LayerNorm, Softmax, reductions, etc.)
4. Calculate what fraction of total time is FP32 vs FP8

```bash
ncu --kernel-name regex:".*" --metrics sm__inst_executed_pipe_tensor_op_hmma.sum,\
sm__inst_executed_pipe_fma.sum,\
sm__inst_executed_pipe_xmma.sum \
    ./your_model
```

### Part F: Build the Precision Suitability Table

```
Operation    | Best Precision | Speedup vs FP32 | Error    | Reason
-------------|----------------|-----------------|----------|--------
GEMM         | FP8            | 3.2x            | 1e-3     | Tensor Core FP8 path
LayerNorm    | FP16           | 1.1x            | 1e-4     | Reduction needs FP16 precision
Softmax      | FP32           | 1.0x            | ref      | Numerical stability requires FP32
Conv2D       | BF16           | 2.1x            | 1e-3     | cuDNN BF16 path optimized
Attention    | FP8 (QK^T)     | 2.5x            | 1e-2     | Flash attention FP8
Reduction    | FP32           | 1.0x            | ref      | Accumulation needs FP32
ReLU         | FP16           | 1.0x            | 0        | Pointwise, no precision issue
Point-cloud  | FP16           | 1.8x            | 1e-4     | Memory-bound, FP16 saves bandwidth
```

## Deliverable

1. **Precision support verification** for SM121 (which precisions work, which don't, which produce wrong results)
2. **Operation × precision benchmark table** (8 operations × 5+ precisions)
3. **Precision suitability table** (best precision per operation with justification)
4. **"Hidden FP32" analysis** for at least one model layer
5. **Profiler evidence** showing Tensor Core utilization per precision
6. **FP4 correctness report** — does FP4 work on SM121? If not, document the failure mode.

## Acceptance Criteria

- [ ] All 8 operations benchmarked in at least 3 precisions
- [ ] FP8 tested with correctness verification
- [ ] FP4 tested (or documented why it fails on SM121)
- [ ] Tensor Core utilization measured for each precision
- [ ] "Hidden FP32" analysis completed for at least one layer
- [ ] Precision suitability table produced with profiler evidence
- [ ] Numerical error reported for every precision × operation combination

## Resources

- [NVIDIA RTX Blackwell Architecture Whitepaper](https://images.nvidia.com/aem-dam/Solutions/geforce/blackwell/nvidia-rtx-blackwell-gpu-architecture.pdf) — 5th gen Tensor Cores, FP4/FP6/FP8
- [NVIDIA Tensor Cores page](https://www.nvidia.com/en-us/data-center/tensor-cores/) — precision support matrix
- [Conselara Labs: DGX Spark GB10 Hardware Reference](https://conselara.dev/notes/dgx-spark-gb10-hardware-reference/) — SM121 feature support (FP4 broken)
- [Transformer Engine documentation](https://docs.nvidia.com/deeplearning/transformer-engine/)
- [PyTorch AMP documentation](https://docs.pytorch.org/docs/stable/amp.html)
- [CUDA C++ Best Practices Guide §10: Mixed Precision](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/)

## AI Agent Prompt Template

```
I need to benchmark neural network operations across multiple precisions on my 
GB10 DGX Spark (SM121, Blackwell, 5th gen Tensor Cores).

Operations: GEMM, LayerNorm, Softmax, Conv2D, Attention, Reduction, ReLU, point-cloud transform
Precisions: FP32, TF32, FP16, BF16, FP8 (e4m3), INT8, FP4 (if supported)

CRITICAL: SM121 (GB10) may NOT support all FP4 paths. CUTLASS FP4 has been reported 
to produce "silent garbage output" on SM121. Test FP4 with a small matrix first 
and verify correctness before trusting any results.

For each operation × precision, I need:
- Throughput (TFLOP/s or ops/s)
- Memory footprint
- Max abs error vs FP32 reference
- Tensor Core utilization (from ncu)
- Whether the operation actually uses Tensor Cores or falls back to CUDA cores

Also identify "hidden FP32" — which operations in an FP8 model still run in FP32?
```
