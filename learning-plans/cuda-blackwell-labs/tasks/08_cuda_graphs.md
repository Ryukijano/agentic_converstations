# Task 08: CUDA Graphs

**Phase:** 3 — Runtime and Systems Literacy
**Prerequisites:** Task 07
**Estimated sessions:** 2-3

---

## Objective

Capture a repeated GPU workflow as a CUDA Graph, replay it, and measure the launch overhead reduction compared to individual kernel launches. Identify which parts of your Endosight pipeline are graph-capture candidates.

## Why This Matters

Your Endosight pipeline runs the same sequence of kernels for every frame: depth estimation → segmentation → reconstruction. Each kernel launch has CPU-side setup overhead. For short kernels, this overhead can be a significant fraction of total time. CUDA Graphs eliminate this by defining the workflow once and replaying it.

## Instructions

### Part A: Build a Repeated Workflow

Create a workflow that simulates a simplified inference pipeline:

```cpp
void run_pipeline(float* d_input, float* d_output, int n, cudaStream_t stream) {
    // Kernel 1: Normalize
    normalize_kernel<<<grid, block, 0, stream>>>(d_input, d_temp1, n);
    // Kernel 2: Transform
    transform_kernel<<<grid, block, 0, stream>>>(d_temp1, d_temp2, n);
    // Kernel 3: Reduce
    reduce_kernel<<<grid, block, smem_size, stream>>>(d_temp2, d_temp3, n);
    // Kernel 4: Activation
    activate_kernel<<<grid, block, 0, stream>>>(d_temp3, d_output, n);
}
```

### Part B: Implementation 1 — Individual Launches

```cpp
for (int i = 0; i < 1000; i++) {
    run_pipeline(d_input, d_output, n, stream);
}
cudaStreamSynchronize(stream);
```

Measure:
- Total time for 1000 iterations
- Average per-iteration time
- CPU time per iteration (launch overhead)
- GPU time per iteration (kernel execution)

### Part C: Implementation 2 — Stream Capture + Graph Replay

```cpp
cudaGraph_t graph;
cudaGraphExec_t graphExec;

// Capture phase
cudaStreamBeginCapture(stream, cudaStreamCaptureModeGlobal);
run_pipeline(d_input, d_output, n, stream);
cudaStreamEndCapture(stream, &graph);

// Instantiate
cudaGraphInstantiate(&graphExec, graph, nullptr, nullptr, 0);

// Replay phase
for (int i = 0; i < 1000; i++) {
    cudaGraphLaunch(graphExec, stream);
}
cudaStreamSynchronize(stream);
```

### Part D: Implementation 3 — Graph with Parameters

For workflows with changing inputs, use graph parameter updates:

```cpp
// Use cudaGraphExecKernelNodeSetParams to update kernel arguments
// without re-capturing the graph
```

Or use the newer CUDA 12+ graph update API:
```cpp
cudaGraphExecUpdate(graphExec, graph, &updateResult);
```

### Part E: Measure Launch Overhead

Create a micro-benchmark with very short kernels (e.g., a kernel that does almost nothing):

```cpp
__global__ void noop_kernel(float* ptr) {
    if (threadIdx.x == 0) ptr[0] += 1.0f;
}
```

Launch 10,000 times:
1. Individual launches
2. Graph replay

Measure the pure launch overhead difference.

### Part F: Nsight Systems Comparison

Profile both implementations:
```bash
nsys profile --stats=true --trace=cuda,nvtx ./individual_launches
nsys profile --stats=true --trace=cuda,nvtx ./graph_replay
```

Compare:
- CPU-side time per launch
- GPU idle gaps between kernels
- Total timeline length

### Part G: Endosight Graph Capture Analysis

Analyze your Endosight pipeline to identify graph-capture candidates:

1. Read the pipeline stage code in `endosight-3d/backend/pipeline/reconstruction/stages/`
2. For each stage, determine:
   - Is the work repeated with the same kernel sequence?
   - Are the tensor shapes stable across iterations?
   - Is there CPU-side control flow that would break capture?
   - Are there dynamic branches that depend on data?

3. Classify each stage as:
   - **Graph-capture candidate** (stable shapes, repeated kernels, minimal control flow)
   - **Partial capture** (some sub-operations could be captured)
   - **Not suitable** (dynamic shapes, data-dependent control flow, variable iteration counts)

## Deliverable

1. **Launch overhead benchmark**: individual vs graph for noop kernel (10,000 launches)
2. **Pipeline benchmark**: individual vs graph for 4-kernel pipeline (1,000 iterations)
3. **Nsight Systems timelines** showing the difference
4. **Graph parameter update** demonstration
5. **Endosight graph capture analysis table**:
   ```
   Stage           | Repeated? | Stable shapes? | Graph candidate?
   ----------------|-----------|----------------|------------------
   Depth estimation| Yes       | Yes (fixed)    | Yes
   Segmentation    | Yes       | Yes (fixed)    | Yes
   Crop            | Yes       | Variable       | Partial
   Reconstruction  | Yes       | Variable       | No
   ```
6. **Written analysis** answering:
   - How much launch overhead did graphs eliminate?
   - For which kernel durations is graph capture worthwhile?
   - Which Endosight stages should use graphs and which should not?

## Acceptance Criteria

- [ ] Individual launch and graph replay implementations working
- [ ] Launch overhead benchmark completed (noop kernel, 10K launches)
- [ ] Pipeline benchmark completed (4-kernel, 1K iterations)
- [ ] Nsight Systems timelines captured for both
- [ ] Graph parameter update demonstrated
- [ ] Endosight pipeline analyzed for graph capture suitability
- [ ] Written analysis quantifying launch overhead reduction

## Resources

- [CUDA Programming Guide §4.2: CUDA Graphs](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/cuda-graphs.html)
- [CUDA C++ Best Practices Guide: CUDA Graphs](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/)
- [Nsight Systems documentation](https://docs.nvidia.com/nsight-systems/)
- [CUDA Graphs blog post](https://developer.nvidia.com/blog/cuda-graphs/)

## AI Agent Prompt Template

```
I need to benchmark CUDA Graphs vs individual kernel launches on my GB10 DGX Spark 
(SM121, unified memory).

1. Create a 4-kernel pipeline: normalize → transform → reduce → activate
2. Implement two versions:
   a. Individual launches in a loop (1000 iterations)
   b. Stream capture into a CUDA Graph, then replay 1000 times
3. Also create a noop kernel launch overhead test (10,000 launches)
4. Measure: total time, per-iteration time, CPU launch overhead, GPU idle gaps
5. Profile with nsys and add NVTX ranges
6. Demonstrate graph parameter updates for changing input pointers

Compile with: nvcc -arch=sm_121 -lineinfo -lnvToolsExt

The GB10 has unified memory, so H2D/D2H copies may be near-instant.
Focus on kernel launch overhead, not copy overhead.
```
