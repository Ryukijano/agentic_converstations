# CUDA Blackwell Labs — Masterplan

A 10-project learning plan to go from advanced-beginner CUDA to genuine Blackwell architecture and CUDA stack mastery, using a DGX Spark (GB10 Grace Blackwell) and AI coding agents (Cursor, Devin, Claude).

---

## Goal

> Become someone who can inspect a slow PyTorch operation and answer: which kernel generated this? Is it compute-bound or bandwidth-bound? Is it using CUDA cores or Tensor Cores? What precision is actually executing? How many registers and how much shared memory does each block use? Is the kernel stalled on memory, synchronization, instruction throughput, or launch overhead? Can you prove the fix with a profiler and a controlled benchmark?

---

## Hardware Context

| Component | Specification |
|-----------|---------------|
| GPU | NVIDIA Blackwell architecture (GB10 Superchip), SM121, compute capability 12.1 |
| CPU | 20-core ARM (10 Cortex-X925 + 10 Cortex-A725) by MediaTek |
| Memory | 128 GB LPDDR5X unified (shared CPU+GPU), 256-bit, 273 GB/s peak |
| Tensor Cores | 5th generation (FP4, FP6, FP8, BF16, FP16, TF32) |
| RT Cores | 4th generation |
| CUDA cores | 6,144 |
| Video engines | 1x NVDEC, 1x NVENC |
| CUDA | 13.0 |
| Driver | 580.142 |
| OS | Ubuntu 24.04.4 LTS, kernel 6.17.0-1014-nvidia |

### Critical GB10 facts

- **128 GB is NOT HBM.** It is shared LPDDR5X. Capacity is high; bandwidth (273 GB/s peak, ~180 GB/s sustained) is far below datacenter GPUs.
- **Not all datacenter Blackwell features exist on GB10.** No TMEM, no WGMMA, no DSMEM, no NVSwitch. CUTLASS FP4 paths may produce silent garbage output on SM121.
- **Unified memory means the Linux page cache competes with CUDA allocations.** A warm filesystem cache can push CUDA into OOM.
- **`cudaMemGetInfo()` underreports available memory** because the OS can reclaim page cache and swap. Always cross-check with `/proc/meminfo`.
- **Compile with `-arch=sm_121`** for GB10-specific SASS. Use `compute_121` for forward-compatible PTX.

---

## Architecture Stack to Master

```
Your Endosight / PyTorch application
           ↓
PyTorch operators and extensions
           ↓
cuBLAS / cuDNN / NCCL / CUTLASS / Triton
           ↓
CUDA Runtime API
           ↓
CUDA Driver API
           ↓
CUDA kernels and launch configuration
           ↓
PTX virtual ISA
           ↓
SASS machine instructions
           ↓
Blackwell SM (SM121)
           ↓
L1/shared memory → L2 → unified LPDDR5X system memory
```

---

## Phase Structure

### Phase 1: Hardware and Memory Literacy (Projects 1-3)
Build a mental model of what the GB10 actually is. Probe the hardware, measure memory behavior, and trace CUDA source through the compiler pipeline.

### Phase 2: Compiler and SM Literacy (Projects 4-6)
Understand how source code becomes SASS, how the SM executes it, and how Tensor Cores fit into the picture. This is where you stop guessing and start reading profiler output.

### Phase 3: Runtime and Systems Literacy (Projects 7-9)
Master streams, events, CUDA Graphs, async allocation, and the video decode pipeline. This is where you learn to overlap work and reduce launch overhead.

### Phase 4: Application Capstone (Project 10)
Replace one Endosight operation with a custom CUDA extension, benchmark it against the PyTorch baseline, and profile the difference. This proves you can apply CUDA to real workloads.

---

## Project Sequence

| # | Project | Phase | Key Skills | Primary Resources |
|---|---------|-------|------------|-------------------|
| 1 | GB10 Hardware Probe | 1 | Device properties, memory reporting, UMA discrepancy | [DGX Spark Hardware Guide](https://docs.nvidia.com/dgx/dgx-spark/hardware.html), [DGX Spark Optimization Guide](https://docs.nvidia.com/dgx/dgx-spark-porting-guide/optimization.html) |
| 2 | Memory Bandwidth & Latency Lab | 1 | Coalescing, stride, access patterns, allocation types, effective bandwidth | [CUDA C++ Best Practices Guide §10](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#memory-optimizations) |
| 3 | CUDA → PTX → SASS Pipeline | 1 | nvcc flags, PTX inspection, SASS inspection, cuobjdump, nvdisasm | [PTX blog post](https://developer.nvidia.com/blog/understanding-ptx-the-assembly-language-of-cuda-gpu-computing/), [Blackwell GPU Wiki](https://0xsero.github.io/blackwell-gpu-wiki/fundamentals/cuda-pipeline/) |
| 4 | Occupancy & Stall Experiments | 2 | Register pressure, shared memory, warp divergence, Nsight Compute metrics | [Blackwell Tuning Guide](https://docs.nvidia.com/cuda/blackwell-tuning-guide/), [CUDA C++ Best Practices Guide §11](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#execution-configuration-optimizations) |
| 5 | Five-Way GEMM Comparison | 2 | Naive CUDA, tiled shared memory, cuBLAS, CUTLASS, PyTorch matmul | [CUTLASS docs](https://docs.nvidia.com/cutlass/latest/overview.html), [CuTe quickstart](https://docs.nvidia.com/cutlass/latest/media/docs/cpp/cute/00_quickstart.html) |
| 6 | Precision Lab (FP32→FP4) | 2 | Tensor Core programming, precision tradeoffs, numerical error, FP8/FP4 | [Blackwell architecture whitepaper](https://images.nvidia.com/aem-dam/Solutions/geforce/blackwell/nvidia-rtx-blackwell-gpu-architecture.pdf), [Tensor Cores page](https://www.nvidia.com/en-us/data-center/tensor-cores/) |
| 7 | Streams, Events, Async Allocation | 3 | Non-blocking streams, pinned memory, async memcpy, events, cudaMallocAsync | [CUDA Programming Guide §3.1](https://docs.nvidia.com/cuda/cuda-programming-guide/03-advanced/advanced-host-programming.html), [Stream-Ordered Allocator](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/stream-ordered-memory-allocation.html) |
| 8 | CUDA Graphs | 3 | Graph capture, instantiation, replay, stream capture, launch overhead | [CUDA Graphs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cuda-graphs.html) |
| 9 | NVDEC Video Pipeline | 3 | Hardware decode, PyNvVideoCodec, ffmpeg h264_cuvid, decode→preprocess→inference | [DGX Spark Hardware Guide](https://docs.nvidia.com/dgx/dgx-spark/hardware.html) |
| 10 | Custom Endosight CUDA Kernel | 4 | PyTorch C++/CUDA extension, point-cloud ops, benchmarking, profiling | [PyTorch C++ extension docs](https://docs.pytorch.org/tutorials/advanced/cpp_extension.html), Endosight 3D codebase |

---

## Online Resources (Ordered by When to Use Them)

### Phase 1 Resources

1. **[NVIDIA accelerated-computing-hub: CUDA C++ Tutorial](https://github.com/NVIDIA/accelerated-computing-hub/tree/main/tutorials/cuda-cpp)** — Free notebooks + YouTube lectures. Start with Part 1 ("CUDA Made Easy") for execution spaces, memory spaces, and parallel algorithms. Run on your GB10.
   - YouTube playlist: https://www.youtube.com/playlist?list=PL5B692fm6--vWLhYPqLcEu6RF3hXjEyJr

2. **[CUDA Programming Guide](https://docs.nvidia.com/cuda/cuda-programming-guide/)** — The official reference. Read sections on the programming model, memory model, and unified memory. Do not read end-to-end; use as reference for each project.

3. **[CUDA C++ Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/)** — The optimization manual. Read §10 (Memory Optimizations) for Project 2, §11 (Execution Configuration) for Project 4. This is the single most important reference for the entire plan.

4. **[DGX Spark Hardware Guide](https://docs.nvidia.com/dgx/dgx-spark/hardware.html)** — Your machine's specs. Read before Project 1.

5. **[DGX Spark Optimization Guide](https://docs.nvidia.com/dgx/dgx-spark-porting-guide/optimization.html)** — UMA-specific guidance. Read before Projects 1 and 2. Critical for understanding `cudaMemGetInfo` behavior.

6. **[PTX: The Assembly Language of CUDA](https://developer.nvidia.com/blog/understanding-ptx-the-assembly-language-of-cuda-gpu-computing/)** — NVIDIA blog post explaining PTX, cubin, JIT compilation. Read before Project 3.

7. **[Blackwell GPU Wiki: CUDA Pipeline](https://0xsero.github.io/blackwell-gpu-wiki/fundamentals/cuda-pipeline/)** — Community resource explaining the .cu → PTX → SASS pipeline with SM100/SM120 specifics. Read alongside Project 3.

### Phase 2 Resources

8. **[Blackwell Tuning Guide](https://docs.nvidia.com/cuda/blackwell-tuning-guide/)** — Architecture-specific optimization guidance. Read before Projects 4 and 5.

9. **[Blackwell Compatibility Guide](https://docs.nvidia.com/cuda/blackwell-compatibility-guide/)** — cubin/PTX compatibility rules across compute capabilities. Read before Project 3 and 5.

10. **[CUTLASS Documentation](https://docs.nvidia.com/cutlass/latest/overview.html)** — CUTLASS 4 overview including CuTe DSL. Read before Project 5.

11. **[CuTe Quickstart](https://docs.nvidia.com/cutlass/latest/media/docs/cpp/cute/00_quickstart.html)** — CuTe Layout/Tensor abstractions. Read during Project 5.

12. **[CuTe GEMM Tutorial](https://docs.nvidia.com/cutlass/latest/media/docs/cpp/cute/0x_gemm_tutorial.md)** — Implementing GEMM with CuTe. Read during Project 5.

13. **[NVIDIA RTX Blackwell Architecture Whitepaper](https://images.nvidia.com/aem-dam/Solutions/geforce/blackwell/nvidia-rtx-blackwell-gpu-architecture.pdf)** — 5th gen Tensor Cores, FP4, SM architecture. Read before Project 6.

14. **[NVIDIA Tensor Cores page](https://www.nvidia.com/en-us/data-center/tensor-cores/)** — Precision support matrix. Read before Project 6.

15. **[Ammar-Alnagar/AI-Kernel-learning](https://github.com/Ammar-Alnagar/AI-Kernel-learning)** — Community CUDA learning repo with structured curriculum from fundamentals to CUTLASS. Useful as a reference for project structure and examples.

### Phase 3 Resources

16. **[CUDA Programming Guide §3.1: Advanced Host Programming](https://docs.nvidia.com/cuda/cuda-programming-guide/03-advanced/advanced-host-programming.html)** — Streams, events, non-blocking streams, synchronization. Read before Project 7.

17. **[CUDA Programming Guide §4.3: Stream-Ordered Memory Allocator](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/stream-ordered-memory-allocation.html)** — `cudaMallocAsync`/`cudaFreeAsync`, memory pools. Read during Project 7.

18. **[CUDA Programming Guide §4.2: CUDA Graphs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cuda-graphs.html)** — Graph definition, instantiation, launch, stream capture. Read before Project 8.

19. **[NVIDIA accelerated-computing-hub: Part 2 — Asynchrony and CUDA Streams](https://github.com/NVIDIA/accelerated-computing-hub/tree/main/tutorials/cuda-cpp)** — Free notebooks on async, Nsight, NVTX, streams, pinned memory. Read during Projects 7 and 8.

### Phase 4 Resources

20. **[PyTorch C++ Extensions documentation](https://docs.pytorch.org/tutorials/advanced/cpp_extension.html)** — Writing custom C++/CUDA extensions for PyTorch. Read before Project 10.

21. **[NVIDIA DeepStream Coding Agent](https://github.com/NVIDIA-AI-IOT/DeepStream_Coding_Agent)** — Example of using AI coding assistants with NVIDIA SDKs. Reference for AI-agent collaboration patterns.

22. **[Cursor Agent Best Practices](https://cursor.com/blog/agent-best-practices)** — How to work effectively with AI coding agents. Read before starting any project.

23. **[SurePrompts: Complete Guide to Prompting AI Coding Agents (2026)](https://sureprompts.com/blog/the-complete-guide-to-prompting-ai-coding-agents-2026)** — Spec-writing, scope, context, acceptance criteria for agents. Read before starting any project.

---

## How to Use AI Agents for Each Project

### Before starting a project

1. **Write a spec** using the task file as a template. Include: goal, scope, context files, acceptance criteria.
2. **Feed the spec to your AI agent** (Cursor, Devin, or Claude) as the initial prompt.
3. **Provide context files**: the relevant NVIDIA documentation links, the task file, and any prior project code.

### During implementation

4. **Let the agent write the first draft**, but do not accept it blindly.
5. **Verify correctness** with `compute-sanitizer` and numerical checks against CPU reference.
6. **Verify performance** with `nsys` and `ncu` — never trust wall-clock time alone.
7. **Ask the agent to explain the SASS** — if it cannot, the kernel is probably wrong.
8. **Iterate**: ask the agent to optimize based on profiler metrics, not guesses.

### After implementation

9. **Write a report** answering all questions in the task file's "Deliverable" section.
10. **Commit with a structured message** including hardware, CUDA version, compiler flags, and measured results.
11. **Export the conversation** to this repo's `conversations/` directory for future reference.

### Anti-patterns to avoid

- Do NOT let the agent write CUDA code without checking register count, shared memory usage, and occupancy
- Do NOT accept "it compiles and runs" as success — verify with profilers
- Do NOT let the agent guess at performance — always measure
- Do NOT skip the PTX/SASS inspection step — it is the core of understanding
- Do NOT let the agent use B200/Hopper examples without checking GB10 compatibility

---

## Repository Structure for Labs

Create a separate repository (or directory) called `gb10-blackwell-labs`:

```
gb10-blackwell-labs/
├── 00_device_probe/
│   ├── probe.cu
│   ├── Makefile
│   ├── README.md
│   └── results/
├── 01_memory_bandwidth/
│   ├── bandwidth.cu
│   ├── Makefile
│   ├── README.md
│   └── results/
├── 02_ptx_sass/
├── 03_occupancy_stalls/
├── 04_gemm/
├── 05_precision/
├── 06_streams_events/
├── 07_cuda_graphs/
├── 08_nvdec/
├── 09_endosight_kernel/
├── benchmarks/
├── profiles/
├── reports/
├── environment.lock
├── Makefile
├── pyproject.toml
├── README.md
└── .github/workflows/ci.yml
```

Each lab directory contains:
- Source code (`.cu` / `.cpp` / `.py`)
- `Makefile` or `CMakeLists.txt`
- `README.md` with hypothesis, method, results, and conclusion
- `results/` with profiler output, graphs, and benchmark data

---

## Progress Tracking

Track progress in this file by checking off completed projects:

- [ ] Project 1: GB10 Hardware Probe
- [ ] Project 2: Memory Bandwidth & Latency Lab
- [ ] Project 3: CUDA → PTX → SASS Pipeline
- [ ] Project 4: Occupancy & Stall Experiments
- [ ] Project 5: Five-Way GEMM Comparison
- [ ] Project 6: Precision Lab (FP32→FP4)
- [ ] Project 7: Streams, Events, Async Allocation
- [ ] Project 8: CUDA Graphs
- [ ] Project 9: NVDEC Video Pipeline
- [ ] Project 10: Custom Endosight CUDA Kernel

---

## Estimated Effort Per Project

These are not deadlines. They are rough guides for how deep each project goes.

| Project | Depth | Sessions | Key blocker |
|---------|-------|----------|-------------|
| 1 | Shallow | 1-2 | None — straightforward API calls |
| 2 | Medium | 3-4 | Understanding bandwidth measurement methodology |
| 3 | Medium | 2-3 | Learning to read PTX and SASS |
| 4 | Deep | 4-5 | Interpreting Nsight Compute metrics |
| 5 | Deep | 5-7 | CUTLASS template complexity |
| 6 | Deep | 4-5 | FP8/FP4 correctness on GB10 |
| 7 | Medium | 3-4 | Stream synchronization semantics |
| 8 | Medium | 2-3 | Graph capture edge cases |
| 9 | Medium | 3-4 | NVDEC API and format compatibility |
| 10 | Deep | 5-7 | Integrating with Endosight pipeline |

---

## What "Done" Looks Like

You are done with this plan when you can:

1. Look at any PyTorch operator and predict whether it is compute-bound or memory-bound
2. Profile any kernel with `ncu` and identify the primary stall reason
3. Read SASS output and explain what each instruction does
4. Implement a GEMM that achieves >70% of cuBLAS throughput
5. Choose the right precision for a given operation and justify it numerically
6. Capture a CUDA Graph and explain when it helps vs when it doesn't
7. Write a PyTorch C++/CUDA extension that is faster than the Python baseline
8. Explain why your GB10 behaves differently from a B200 for the same kernel
9. Use AI agents to write CUDA code while verifying their output with profilers
10. Document your results with controlled experiments and reproducible benchmarks
