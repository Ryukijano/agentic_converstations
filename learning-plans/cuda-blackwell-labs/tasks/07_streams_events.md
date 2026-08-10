# Task 07: Streams, Events, Async Allocation

**Phase:** 3 — Runtime and Systems Literacy
**Prerequisites:** Task 02, Task 04
**Estimated sessions:** 3-4

---

## Objective

Build a four-stage pipeline (H2D copy → preprocessing → kernel → D2H copy) and implement it four ways: default stream, multiple streams, pinned memory + async copies, and stream-ordered allocation. Measure how each technique improves overlap and reduces latency.

## Why This Matters

Your Endosight pipeline has sequential stages: decode → extract → crop → reconstruct. If each stage waits for the previous one to complete, you are wasting GPU time. CUDA streams and events are the mechanism for overlapping independent work. This lab teaches you the runtime-level skills needed before you tackle CUDA Graphs in Task 08.

## Instructions

### Part A: Build the Four-Stage Pipeline

```cpp
// Stage 1: H2D copy (host to device)
cudaMemcpyAsync(d_in, h_in, size, cudaMemcpyHostToDevice, stream);

// Stage 2: Preprocessing kernel (normalize, scale, etc.)
preprocess_kernel<<<grid, block, 0, stream>>>(d_in, d_intermediate, n);

// Stage 3: Compute kernel (the "real" work)
compute_kernel<<<grid, block, 0, stream>>>(d_intermediate, d_out, n);

// Stage 4: D2H copy (device to host)
cudaMemcpyAsync(h_out, d_out, size, cudaMemcpyDeviceToHost, stream);
```

### Part B: Implementation 1 — Default Stream + Synchronous

```cpp
// Everything on default stream (stream 0)
// Use cudaMalloc (synchronous allocation)
// Use cudaMemcpy (synchronous copy)
// Use cudaDeviceSynchronize() after each stage
```

Measure:
- Total latency
- GPU idle time (time between kernel end and next kernel start)
- CPU utilization (is the CPU blocked waiting?)

### Part C: Implementation 2 — Multiple Streams

```cpp
cudaStream_t stream1, stream2, stream3;
cudaStreamCreate(&stream1);
cudaStreamCreate(&stream2);
cudaStreamCreate(&stream3);

// Pipeline: process batch 0 on stream1, batch 1 on stream2, batch 2 on stream3
// Use events to create dependencies between stages within a batch
cudaEvent_t event;
cudaEventCreate(&event);

cudaMemcpyAsync(d_in0, h_in0, size, cudaMemcpyHostToDevice, stream1);
preprocess_kernel<<<..., stream1>>>(d_in0, d_int0, n);
cudaEventRecord(event, stream1);
cudaStreamWaitEvent(stream2, event);
compute_kernel<<<..., stream2>>>(d_int0, d_out0, n);
```

### Part D: Implementation 3 — Pinned Memory + Async Copies

```cpp
// Use pinned (page-locked) host memory
cudaHostAlloc(&h_in, size, cudaHostAllocDefault);
// or
cudaMallocHost(&h_in, size);

// Use non-blocking streams
cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking);

// Use async copies
cudaMemcpyAsync(d_in, h_in, size, cudaMemcpyHostToDevice, stream);
```

**GB10 Note:** On unified memory architectures, pinned memory behavior differs. The GPU and CPU share physical memory, so "pinned" may not provide the same benefit as on discrete GPUs. Measure and document this.

### Part E: Implementation 4 — Stream-Ordered Allocation

```cpp
// Use cudaMallocAsync instead of cudaMalloc
void* d_in;
cudaMallocAsync(&d_in, size, stream);
// ... use d_in ...
cudaFreeAsync(d_in, stream);

// Configure memory pool for caching
cudaMemPool_t pool;
cudaDeviceGetDefaultMemPool(&pool, 0);
uint64_t threshold = UINT64_MAX;  // keep all freed memory in pool
cudaMemPoolSetAttribute(pool, cudaMemPoolAttrReleaseThreshold, &threshold);
```

### Part F: Measure and Compare

For all 4 implementations, process 16 batches of 1M floats each:

| Metric | Impl 1 (default) | Impl 2 (multi-stream) | Impl 3 (pinned+async) | Impl 4 (async alloc) |
|--------|------------------|-----------------------|-----------------------|----------------------|
| Total latency (ms) | | | | |
| GPU idle time (ms) | | | | |
| CPU blocked time (ms) | | | | |
| Peak memory (GB) | | | | |
| Memory reuse | No | No | No | Yes (pool) |

### Part G: Nsight Systems Timeline

```bash
nsys profile --stats=true ./pipeline_test
```

Open the `.nsys-rep` file in Nsight Systems and capture:
- Stream timelines showing overlap (or lack thereof)
- Kernel launch gaps
- Memory transfer timelines
- CPU thread timelines

Add NVTX ranges for each stage:
```cpp
nvtxRangePushA("H2D_copy");
cudaMemcpyAsync(...);
nvtxRangePop();

nvtxRangePushA("preprocess");
preprocess_kernel<<<...>>>(...);
nvtxRangePop();
```

### Part H: The GB10 UMA Copy Experiment

On GB10, H2D and D2H copies may be no-ops or very fast because CPU and GPU share memory. Test:

1. `cudaMemcpy` with `cudaMemcpyHostToDevice` — measure time
2. `cudaMemcpyAsync` with `cudaMemcpyHostToDevice` — measure time
3. Direct pointer access (GPU kernel reading from host pointer via managed memory) — measure time
4. Compare to a discrete GPU's copy behavior (if you have access to one, or use documented numbers)

Document whether "copies" on UMA are real copies or just cache flushes.

## Deliverable

1. **4 implementations** of the four-stage pipeline
2. **Comparison table** with all 5 metrics
3. **Nsight Systems timeline screenshots** showing stream overlap
4. **NVTX-annotated timeline** with labeled stages
5. **UMA copy experiment results** — are H2D/D2H copies real on GB10?
6. **Written analysis** answering:
   - How much overlap did multiple streams provide?
   - Did pinned memory help on UMA? Why or why not?
   - How much memory did the async allocator save?
   - What is the GPU idle time in each implementation?

## Acceptance Criteria

- [ ] 4 pipeline implementations working and correct
- [ ] Comparison table with 5 metrics for all 4
- [ ] Nsight Systems timeline captured with NVTX ranges
- [ ] UMA copy experiment completed
- [ ] Written analysis answering all 4 questions
- [ ] Non-blocking streams used in implementations 3 and 4

## Resources

- [CUDA Programming Guide §3.1: Advanced Host Programming](https://docs.nvidia.com/cuda/cuda-programming-guide/03-advanced/advanced-host-programming.html)
- [CUDA Programming Guide §4.3: Stream-Ordered Memory Allocator](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/stream-ordered-memory-allocation.html)
- [CUDA C++ Best Practices Guide §9: Asynchronous Transfers](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/#asynchronous-transfers)
- [NVIDIA accelerated-computing-hub Part 2: Asynchrony and Streams](https://github.com/NVIDIA/accelerated-computing-hub/tree/main/tutorials/cuda-cpp)
- [Nsight Systems documentation](https://docs.nvidia.com/nsight-systems/)

## AI Agent Prompt Template

```
I need to implement a 4-stage CUDA pipeline on my GB10 DGX Spark (SM121, unified memory):
Stage 1: H2D copy
Stage 2: Preprocessing kernel
Stage 3: Compute kernel
Stage 4: D2H copy

I need 4 versions:
1. Default stream + synchronous (cudaMalloc, cudaMemcpy, cudaDeviceSynchronize)
2. Multiple streams with events for dependencies
3. Pinned memory (cudaHostAlloc) + async copies + non-blocking streams
4. Stream-ordered allocation (cudaMallocAsync/cudaFreeAsync) with memory pool

IMPORTANT: GB10 has unified LPDDR5X memory. H2D/D2H copies may be very fast 
or near-instant because CPU and GPU share physical memory. Measure and document 
this behavior — it is different from discrete GPUs.

Add NVTX ranges for each stage.
Profile with: nsys profile --stats=true
Compile with: nvcc -arch=sm_121 -lineinfo -lnvToolsExt
```
