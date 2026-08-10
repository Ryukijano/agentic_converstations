# AI-Agent Collaboration Guide for CUDA Learning

How to use Cursor, Devin, Claude, and other AI coding agents effectively while learning CUDA — without letting them do the thinking for you.

---

## Core Principle

> AI agents can write CUDA code faster than you can. But they cannot verify it is correct or optimal without your judgment. Your job is to become the verifier, not the typist.

---

## The Verification Loop

```
You write a spec → Agent writes code → You verify correctness → You verify performance → You iterate
     ↑                                                                    |
     └────────────────────── profiler evidence drives next spec ──────────┘
```

The agent is good at:
- Writing boilerplate CUDA code
- Suggesting optimization techniques
- Explaining PTX/SASS instructions
- Generating benchmark harnesses
- Writing PyTorch extension wrappers

The agent is bad at:
- Knowing what GB10 SM121 supports vs B200
- Interpreting Nsight Compute metrics correctly
- Choosing the right precision without testing
- Understanding unified memory behavior
- Knowing when an optimization is counterproductive

---

## Per-Project Agent Strategy

### Projects 1-3 (Hardware, Memory, Compiler)

**Use agents liberally.** These projects are about building vocabulary and tool familiarity. Let the agent write the probe code, the benchmark harness, and the PTX/SASS annotation scripts. Your job is to read the output and understand it.

**Prompt pattern:**
```
Write a CUDA program that [specific task] for my GB10 DGX Spark (SM121, 
unified LPDDR5X memory, 273 GB/s peak bandwidth). 

Compile with: nvcc -arch=sm_121 -lineinfo

After writing the code, explain:
1. What each CUDA API call does
2. What the output will tell me about my hardware
3. What discrepancies to expect on unified memory
```

**Verification:** Run the code. Check the output matches your hardware specs from the DGX Spark Hardware Guide. If the agent says "HBM" anywhere, correct it — your GB10 has LPDDR5X.

### Projects 4-6 (Occupancy, GEMM, Precision)

**Use agents for implementation, but verify everything with profilers.** This is where agents start making mistakes. They may suggest Hopper-only features, use wrong Tensor Core APIs, or claim FP4 works without checking.

**Prompt pattern:**
```
I need to [specific task] on my GB10 DGX Spark (SM121, Blackwell).

CRITICAL CONSTRAINTS:
- SM121 does NOT support: TMEM, WGMMA, DSMEM, NVSwitch
- CUTLASS FP4 may produce silent garbage on SM121 — verify with small test first
- Memory is unified LPDDR5X (273 GB/s peak, ~180 GB/s sustained), NOT HBM
- Compile with: nvcc -arch=sm_121 -lineinfo

After implementation, I will verify with:
- compute-sanitizer for memory errors
- ncu --set full for performance metrics
- Correctness check against CPU reference

Please also tell me:
1. How many registers this kernel uses
2. What the theoretical occupancy is
3. Whether Tensor Cores are being used
```

**Verification:**
1. Run `compute-sanitizer --tool memcheck ./your_binary` — no memory errors
2. Run `ncu --set full ./your_binary` — check occupancy, stalls, bandwidth
3. Compare output to CPU reference — max error < tolerance
4. Check SASS with `cuobjdump --dump-sass` — are the instructions what you expect?

### Projects 7-9 (Streams, Graphs, NVDEC)

**Use agents for API boilerplate, but design the experiments yourself.** The agent knows the CUDA stream API, but it does not know your Endosight pipeline. You need to decide what to measure and why.

**Prompt pattern:**
```
I need to implement [specific pipeline] with CUDA streams/events/graphs 
on my GB10 DGX Spark (SM121, unified memory).

The pipeline has these stages:
1. [stage 1 description]
2. [stage 2 description]
3. [stage 3 description]

I need to measure:
- Total latency
- GPU idle time
- CPU blocked time
- Memory reuse

Use non-blocking streams, CUDA events for dependencies, and NVTX ranges.
Profile with: nsys profile --trace=cuda,nvtx,osrt

IMPORTANT: On unified memory, H2D/D2H copies may be near-instant because 
CPU and GPU share physical memory. Do not assume discrete GPU copy behavior.
```

**Verification:**
1. Open `nsys` report — check stream overlap visually
2. Verify NVTX ranges appear correctly in timeline
3. Compare GPU idle time across implementations
4. Check that non-blocking streams actually enable overlap

### Project 10 (Endosight Kernel)

**This is where you lead and the agent assists.** You know the Endosight pipeline; the agent does not. Write the spec yourself, choose the operation, and use the agent only for CUDA implementation details.

**Prompt pattern:**
```
I'm replacing [specific operation] in my Endosight 3D endoscopy pipeline 
with a custom CUDA kernel. Here is the current PyTorch implementation:

[INSERT CODE]

The operation processes [N] points and is [memory/compute]-bound.
Input: [describe tensor shapes and dtypes]
Output: [describe tensor shapes and dtypes]

I need a CUDA kernel + PyTorch C++/CUDA extension that:
1. Matches the PyTorch output (max error < 1e-5)
2. Uses coalesced memory access
3. Uses stream compaction (CUB or warp-level)
4. Compiles with: nvcc -arch=sm_121 -lineinfo -O3

CRITICAL: Do NOT modify the pose estimation loop or any other part of the 
Endosight pipeline. Only replace this one operation.

After implementation, tell me:
1. Register count and theoretical occupancy
2. Expected memory bandwidth utilization
3. Whether vectorized loads are used
```

**Verification:**
1. `compute-sanitizer --tool memcheck` — no errors
2. `ncu --set full` — bandwidth, occupancy, stalls
3. Correctness: `torch.allclose(custom_output, baseline_output, atol=1e-5)`
4. Integration: run full Endosight pipeline, verify no regression
5. End-to-end: measure pipeline time before and after

---

## Common Agent Mistakes to Watch For

### 1. "This should work on Blackwell"

Agents often conflate B100/B200 with GB10. Watch for:
- `tcgen05` instructions (TMEM — not on SM121)
- `wgmma` instructions (not on SM121)
- Cluster/Distributed Shared Memory (not on SM121)
- FP4 CUTLASS paths (may produce garbage on SM121)

**Fix:** Always specify "SM121, GB10, no TMEM/WGMMA/DSMEM" in your prompt.

### 2. "Use cudaMalloc for device memory"

On UMA, `cudaMalloc` and `cudaMallocManaged` behave differently than on discrete GPUs. The agent may not know this.

**Fix:** Specify "unified LPDDR5X memory, not HBM" and test both allocation types.

### 3. "This kernel should achieve 90% bandwidth"

Agents cite theoretical bandwidth. Your sustained bandwidth is ~180 GB/s, not 273 GB/s.

**Fix:** Always compare to measured bandwidth from Task 02, not theoretical peak.

### 4. "Occupancy is low, let's increase it"

High occupancy is not always better. A memory-bound kernel with 50% occupancy may be faster than one with 100% occupancy but worse coalescing.

**Fix:** Always check the stall reason in `ncu` before optimizing occupancy.

### 5. "Let's use FP4 for 4x speedup"

FP4 may not work correctly on SM121. The Conselara Labs reference reports "silent garbage output" for CUTLASS FP4 on GB10.

**Fix:** Test FP4 with a small matrix first. Verify correctness before benchmarking.

### 6. "This optimization will help"

Agents guess at optimizations. You need profiler evidence.

**Fix:** Never accept an optimization without before/after `ncu` metrics.

---

## Agent-Specific Tips

### Cursor

- Use `@Files` to include your task file and relevant NVIDIA docs
- Use `@Web` to search for SM121-specific information
- Use Rules (`.cursor/rules`) to persist "SM121 constraints" across sessions
- Use `@Chats` to reference prior project conversations
- After each project, export the conversation to this repo

### Devin

- Provide the full task file as the initial prompt
- Let Devin run the code and iterate — it can execute `nvcc`, `ncu`, `nsys`
- Ask Devin to save profiler output to `results/` directory
- Ask Devin to generate the report based on profiler evidence

### Claude (standalone)

- Paste the task file and ask for implementation
- Ask Claude to explain every CUDA API call
- Ask Claude to predict what the SASS will look like, then verify
- Use Claude for code review — paste your kernel and ask "what stall reasons should I expect?"

---

## The Spec Template

For every project, write a spec before talking to the agent:

```markdown
## Goal
[One sentence: what to build]

## Scope
- IN: [what the agent should do]
- OUT: [what the agent should NOT do]

## Context
- Hardware: GB10 DGX Spark, SM121, 128GB unified LPDDR5X, 273 GB/s peak
- CUDA: 13.0, driver 580.142
- Compile: nvcc -arch=sm_121 -lineinfo -O3
- Constraints: No TMEM, no WGMMA, no DSMEM. FP4 may not work.

## Acceptance Criteria
- [ ] Correctness: [specific check]
- [ ] Performance: [specific metric]
- [ ] Profiling: [specific tool and output]
- [ ] Report: [specific deliverable]

## Resources
- [links to specific NVIDIA docs]
```

---

## Exporting Conversations

After completing each project, export the agent conversation to this repo:

```bash
cp templates/basic-conversation.md conversations/general-development/cuda-lab-XX.md
# Fill in the conversation transcript
# Update INDEX.md
git add conversations/general-development/cuda-lab-XX.md INDEX.md
git commit -m "Add CUDA Lab XX conversation: [topic]"
```

This creates a record of your learning journey and helps you reference prior solutions when working on later projects.

---

## The Golden Rule

> If you cannot explain why the kernel is fast (or slow) using profiler evidence, you have not learned anything — regardless of what the agent wrote.

Every project must end with you explaining the result in your own words, backed by `ncu` or `nsys` output. The agent writes the code; you write the understanding.
