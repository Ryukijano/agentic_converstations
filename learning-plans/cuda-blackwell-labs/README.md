# CUDA Blackwell Labs — Learning Plan

A 10-project learning plan to master the NVIDIA Blackwell architecture and CUDA software stack on a DGX Spark (GB10 Grace Blackwell Superchip), using AI coding agents (Cursor, Devin, Claude) as development partners.

## Documents

| Document | Purpose |
|----------|---------|
| [CUDA_LEVEL_ASSESSMENT.md](CUDA_LEVEL_ASSESSMENT.md) | Honest assessment of current CUDA knowledge and gaps |
| [MASTERPLAN.md](MASTERPLAN.md) | Full 10-project plan with phases, resources, and progress tracking |
| [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) | How to use AI coding agents effectively for CUDA learning |
| [NVIDIA_AGENTIC_SKILLS_ANALYSIS.md](NVIDIA_AGENTIC_SKILLS_ANALYSIS.md) | How NVIDIA builds, verifies, and distributes agent skills |
| [tasks/](tasks/) | Individual task files for each of the 10 projects |

## Quick Start

1. Read [CUDA_LEVEL_ASSESSMENT.md](CUDA_LEVEL_ASSESSMENT.md) to understand the starting point
2. Read [MASTERPLAN.md](MASTERPLAN.md) for the full plan and resource list
3. Read [AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) for agent collaboration patterns
4. Start with [tasks/01_gb10_hardware_probe.md](tasks/01_gb10_hardware_probe.md)
5. Complete projects in order — do not skip ahead

## Project List

| # | Project | Phase | Status |
|---|---------|-------|--------|
| 1 | [GB10 Hardware Probe](tasks/01_gb10_hardware_probe.md) | 1 | Pending |
| 2 | [Memory Bandwidth & Latency Lab](tasks/02_memory_bandwidth.md) | 1 | Pending |
| 3 | [CUDA → PTX → SASS Pipeline](tasks/03_ptx_sass.md) | 1 | Pending |
| 4 | [Occupancy & Stall Experiments](tasks/04_occupancy_stalls.md) | 2 | Pending |
| 5 | [Five-Way GEMM Comparison](tasks/05_gemm_comparison.md) | 2 | Pending |
| 6 | [Precision Lab (FP32→FP4)](tasks/06_precision_lab.md) | 2 | Pending |
| 7 | [Streams, Events, Async Allocation](tasks/07_streams_events.md) | 3 | Pending |
| 8 | [CUDA Graphs](tasks/08_cuda_graphs.md) | 3 | Pending |
| 9 | [NVDEC Video Pipeline](tasks/09_nvdec_pipeline.md) | 3 | Pending |
| 10 | [Custom Endosight CUDA Kernel](tasks/10_endosight_kernel.md) | 4 | Pending |

## Hardware

- **GPU:** NVIDIA Blackwell (GB10 Superchip), SM121, compute capability 12.1
- **Memory:** 128 GB LPDDR5X unified (shared CPU+GPU), 273 GB/s peak
- **Tensor Cores:** 5th generation (FP4, FP6, FP8, BF16, FP16, TF32)
- **CUDA:** 13.0, driver 580.142
- **OS:** Ubuntu 24.04.4 LTS, kernel 6.17.0-1014-nvidia

## Key Constraints

- GB10 is NOT a B200. No TMEM, no WGMMA, no DSMEM, no NVSwitch.
- 128 GB is LPDDR5X, not HBM. Sustained bandwidth ~180 GB/s, not 273 GB/s.
- CUTLASS FP4 paths may produce silent garbage on SM121. Verify before trusting.
- `cudaMemGetInfo()` underreports available memory on UMA. Cross-check with `/proc/meminfo`.
- Compile with `-arch=sm_121` for GB10-specific SASS.
