# CUDA Level Assessment — Gyanateet Dutta (Ryukijano)

**Date:** 2026-08-10
**Assessed by:** Devin (GLM-5.2 High) based on public GitHub, HuggingFace, LinkedIn, and publications analysis.

---

## Verdict: Advanced Beginner

You understand what CUDA is, have tried it, and know the vocabulary — but you have not built production CUDA kernels, used profiling tools, inspected PTX/SASS, programmed Tensor Cores, or used CUTLASS/CuTe. Your LinkedIn "HPC (CUDA/TPUs)" claim is aspirational, not demonstrated.

This is not a weakness — it is the starting point this plan fixes.

---

## Evidence

### What you have done

| Artifact | Date | What it shows | Limitation |
|----------|------|---------------|------------|
| Neural network from scratch in CUDA C++ | Nov 2020 (2nd year undergrad) | Persistence, basic kernels, memory layout, gradients, synchronization, numerical stability | Described as "walking straight into a wall"; no repo found; 5+ years ago |
| `Ryukijano/CUDA-PCA-jacobi` | Jan 2021 | Fork of IIT Delhi COL380 coursework; Jacobi eigenvalue algorithm in CUDA C | Fork with 1 contribution from you; coursework, not independent work |
| `Ryukijano/Cuda-Script` | — | GPU/CPU testing script | Not actual CUDA programming; just environment checking |
| Endosight 3D pipeline | 2024–2026 | PyTorch, cuDNN, cuBLAS usage via framework | No custom kernels; all CUDA is through PyTorch abstractions |
| LinkedIn "HPC (CUDA/TPUs)" claim | 2026 | Awareness of CUDA ecosystem | No demonstrated depth in kernel programming, profiling, or optimization |

### What you have NOT done (verified by absence in public repos)

- [ ] Written a custom CUDA kernel for a production system
- [ ] Inspected PTX or SASS output from `nvcc`
- [ ] Used `nsys` (Nsight Systems) or `ncu` (Nsight Compute) for profiling
- [ ] Programmed Tensor Cores directly (not through PyTorch/cuDNN)
- [ ] Used CUTLASS or CuTe
- [ ] Implemented shared memory tiling for GEMM
- [ ] Used CUDA Graphs for launch overhead reduction
- [ ] Used stream-ordered memory allocation (`cudaMallocAsync`)
- [ ] Analyzed occupancy, warp stalls, or memory throughput metrics
- [ ] Worked with unified memory management on UMA architectures
- [ ] Used `compute-sanitizer` for memory error detection
- [ ] Written a PyTorch C++/CUDA extension
- [ ] Used NVTX ranges for profiler annotation
- [ ] Benchmarked FP8/FP4 precision on Blackwell Tensor Cores
- [ ] Used NVDEC for hardware video decode in a pipeline

---

## Skill Breakdown

### CUDA Programming Model
- **Threads/Blocks/Grids:** Understood from coursework (Jacobi PCA) and 2020 NN attempt
- **Warps and divergence:** Conceptual awareness, no demonstrated optimization
- **Shared memory:** Conceptual awareness from coursework, no production use
- **Registers and occupancy:** Not demonstrated
- **Cooperative groups:** Not used

### Memory Hierarchy
- **Global memory coalescing:** Not demonstrated
- **Shared memory banking:** Not demonstrated
- **L1/L2 cache behavior:** Not demonstrated
- **Unified memory (UMA):** Not demonstrated — critical gap for GB10
- **Pinned memory:** Not demonstrated
- **Stream-ordered allocation:** Not used

### Compilation Pipeline
- **nvcc flags and architecture targeting:** Basic (`-arch` usage)
- **PTX inspection:** Never done
- **SASS inspection:** Never done
- **`cuobjdump` / `nvdisasm`:** Never used
- **JIT compilation understanding:** Not demonstrated

### Profiling
- **Nsight Systems (`nsys`):** Never used
- **Nsight Compute (`ncu`):** Never used
- **NVTX annotation:** Never used
- **`nvidia-smi` monitoring:** Basic usage implied
- **`compute-sanitizer`:** Never used

### Tensor Cores and Precision
- **WMMA/Tensor Core API:** Never used directly
- **CUTLASS:** Never used
- **CuTe:** Never used
- **FP8/FP4 programming:** Not demonstrated (only through PyTorch/TransformerEngine)
- **TF32:** Not demonstrated
- **Mixed precision training:** Used through PyTorch AMP, not at kernel level

### Libraries and Frameworks
- **cuBLAS:** Used through PyTorch
- **cuDNN:** Used through PyTorch
- **NCCL:** Used through PyTorch DDP
- **CUTLASS:** Never used
- **Triton:** Not demonstrated
- **Thrust/CUB:** Not demonstrated

### Runtime and Streams
- **CUDA streams:** Not directly managed
- **CUDA events:** Not used
- **CUDA Graphs:** Never used
- **Async memcpy:** Not demonstrated
- **Multi-stream overlap:** Not demonstrated

---

## What This Means for the Learning Plan

1. **You cannot skip the fundamentals.** Despite having "tried CUDA" in 2020, the gap since then means you should start from Project 1 (hardware probe) to rebuild muscle memory and fill in missing knowledge.

2. **Your PyTorch experience is an asset.** You understand what a model looks like, what operators do, and what a training loop is. The plan leverages this by connecting every CUDA concept back to PyTorch behavior.

3. **Your GB10 hardware is the perfect teacher.** Unified memory, 273 GB/s bandwidth, and Blackwell Tensor Cores give you a unique platform that most CUDA learners don't have. The plan is designed around GB10's specific characteristics.

4. **Your Endosight project provides real workloads.** Instead of only toy benchmarks, you can apply CUDA concepts to actual point-cloud processing, video decode, and 3D reconstruction — giving you production-grade experience.

5. **AI agents will accelerate your learning.** Cursor, Devin, and Claude can help you write CUDA code, but you must learn to verify their output with profilers and correctness tools. The plan includes an AI-agent collaboration guide for exactly this.

---

## Recommended Starting Point

**Start at Project 1 (GB10 Hardware Probe).** Do not skip to Tensor Cores or CUTLASS.

The progression is:

```
Project 1-3:   Hardware + memory + compiler literacy (fundamentals)
Project 4-6:   SM + occupancy + Tensor Cores (architecture depth)
Project 7-9:   Streams + graphs + video pipeline (runtime systems)
Project 10:    Custom Endosight kernel (capstone application)
```

Each project builds on the previous one. Skipping ahead will create gaps that surface later as "I don't understand why this kernel is slow."
