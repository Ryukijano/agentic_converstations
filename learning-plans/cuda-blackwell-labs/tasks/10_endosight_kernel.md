# Task 10: Custom Endosight CUDA Kernel

**Phase:** 4 — Application Capstone
**Prerequisites:** Tasks 01-09 (all of them)
**Estimated sessions:** 5-7

---

## Objective

Replace one operation in your Endosight 3D pipeline with a custom CUDA kernel exposed as a PyTorch C++/CUDA extension. Benchmark it against the existing PyTorch implementation, profile the difference, and prove the improvement with controlled experiments.

## Why This Matters

This is the capstone. Every prior lab built a specific skill. This project integrates all of them: you will read SASS, use Nsight Compute, understand memory bandwidth, choose the right precision, use streams, and potentially capture a CUDA Graph — all on a real workload from your clinical pipeline. The result is a production-relevant CUDA extension that demonstrates genuine HPC depth.

## Instructions

### Part A: Choose the Operation

Review the Endosight pipeline stages and pick one operation that is:
- Repeated frequently (per-frame or per-point-cloud)
- Currently implemented in Python/PyTorch
- Memory-bound or compute-bound (not I/O-bound)
- Has stable enough input shapes for optimization

**Candidate operations** (from your AGENTS.md and pipeline knowledge):

| Operation | Input | Output | Why it's a good candidate |
|-----------|-------|--------|--------------------------|
| Point-cloud voxel filtering | Nx3 points | Mx3 points | Memory-bound, repeated per frame |
| FOV mask application | Nx3 points + mask | Mx3 points | Simple but bandwidth-heavy |
| RGB validity filtering | Nx3 points + Nx3 colors | Mx6 filtered | Memory-bound, large N |
| Depth validity filtering | HxW depth + mask | HxW filtered | Simple, per-frame |
| Point-cloud compaction | NxK attributes + bool mask | MxK compacted | Stream compaction, bandwidth-bound |
| Per-point color fusion | Nx3 points + Nx3 colors + accum | Nx6 fused | Arithmetic + memory, per-frame |
| Frame-wise mask intersection | HxW mask1 + HxW mask2 | HxW intersection | Simple, per-frame |

**Recommended:** Point-cloud compaction or RGB validity filtering. These are memory-bound, have large N (millions of points), and are simple enough to implement correctly.

### Part B: Implement the Baseline

Find or write the current PyTorch implementation:

```python
# Example: RGB validity filtering
def filter_rgb_valid(points, colors, threshold=0.1):
    mask = (colors.sum(dim=1) > threshold)  # non-black points
    return points[mask], colors[mask]
```

Benchmark:
- Input sizes: 100K, 500K, 1M, 2M, 5M, 8M points
- Measure: latency, memory usage, bandwidth
- Profile with `ncu`: identify the bottleneck

### Part C: Implement the Vectorized PyTorch Version

Optimize the PyTorch version before writing CUDA:

```python
# Use torch.index_select instead of boolean indexing
# Use torch.nonzero for compaction
# Try different memory layouts (contiguous vs strided)
# Try half precision for colors
```

This gives you a stronger baseline to beat.

### Part D: Write the Custom CUDA Kernel

```cpp
__global__ void filter_rgb_valid_kernel(
    const float3* points,
    const float3* colors,
    float3* out_points,
    float3* out_colors,
    int* out_count,
    const int n,
    const float threshold
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    
    float3 c = colors[i];
    if (c.x + c.y + c.z > threshold) {
        // Use atomic or block-level compaction
        // ...
    }
}
```

Consider:
- **Stream compaction** with `cub::DeviceSelect::Flagged`
- **Block-level compaction** with shared memory prefix sum
- **Warp-level compaction** with `__ballot_sync` and `__ffs`
- **Vectorized loads** with `float4` or `int4`
- **Shared memory tiling** for coalesced access

### Part E: Wrap as PyTorch C++/CUDA Extension

```cpp
#include <torch/extension.h>

torch::Tensor filter_rgb_valid_cuda(
    torch::Tensor points,
    torch::Tensor colors,
    double threshold
) {
    // Check inputs
    // Allocate output
    // Launch kernel
    // Return filtered tensor
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
    m.def("filter_rgb_valid", &filter_rgb_valid_cuda, "Filter points by RGB validity");
}
```

Build with:
```python
# setup.py
from setuptools import setup
from torch.utils.cpp_extension import BuildExtension, CUDAExtension

setup(
    name="endosight_cuda",
    ext_modules=[
        CUDAExtension(
            "endosight_cuda",
            ["endosight_cuda.cpp", "filter_rgb_valid.cu"],
            extra_compile_args={
                "cxx": ["-O3"],
                "nvcc": ["-O3", "-arch=sm_121", "-lineinfo"]
            }
        )
    ],
    cmdclass={"build_ext": BuildExtension}
)
```

Or use `torch.utils.cpp_extension.load` for JIT compilation:
```python
from torch.utils.cpp_extension import load
endosight_cuda = load(
    name="endosight_cuda",
    sources=["endosight_cuda.cpp", "filter_rgb_valid.cu"],
    extra_cuda_cflags=["-O3", "-arch=sm_121", "-lineinfo"]
)
```

### Part F: Optional Triton Version

If you want to compare against Triton:

```python
import triton
import triton.language as tl

@triton.jit
def filter_rgb_valid_triton(
    points_ptr, colors_ptr, out_points_ptr, out_colors_ptr,
    n, threshold,
    BLOCK_SIZE: tl.constexpr,
):
    # Triton implementation
    pass
```

### Part G: Benchmark All Versions

For input sizes 100K to 8M points:

| Version | 100K | 500K | 1M | 2M | 5M | 8M |
|---------|------|------|----|----|----|----|
| PyTorch baseline | | | | | | |
| PyTorch vectorized | | | | | | |
| Custom CUDA | | | | | | |
| Triton (optional) | | | | | | |

For each, measure:
- Latency (ms)
- Memory bandwidth (GB/s)
- % of peak bandwidth (273 GB/s)
- Correctness (max error vs baseline)

### Part H: Profile with Nsight Compute

```bash
ncu --set full --kernel-name regex:"filter_rgb" ./benchmark
```

Capture:
- Memory bandwidth utilization
- L2 cache hit rate
- Occupancy
- Register count
- Shared memory usage
- Stall reasons
- Coalescing efficiency

### Part I: Profile with Nsight Systems

```bash
nsys profile --stats=true ./benchmark
```

Check:
- Is the kernel overlapping with other work?
- Are there unnecessary synchronizations?
- Is there a CPU bottleneck?

### Part J: Integration Test

Integrate the custom kernel into the Endosight pipeline:

1. Replace the Python operation with your CUDA extension
2. Run the full pipeline on a test video
3. Verify the output is identical (or within numerical tolerance)
4. Measure end-to-end pipeline speedup
5. Check for regressions

**Important from AGENTS.md:** Do not parallelize the pose loop. Keep relative pose sequential. Only replace the specific operation you chose, not the entire pipeline.

## Deliverable

1. **Operation analysis**: which operation, why, what's the bottleneck
2. **4 implementations**: baseline PyTorch, vectorized PyTorch, custom CUDA, optional Triton
3. **Benchmark table**: 6 input sizes × 4 versions
4. **Nsight Compute profile** of the custom CUDA kernel
5. **Nsight Systems profile** of the full pipeline with and without the custom kernel
6. **Correctness verification**: max error, mean error, visual comparison
7. **Integration test results**: end-to-end pipeline speedup
8. **Written report** answering:
   - Why is the custom kernel faster (or not)?
   - Is the operation memory-bound or compute-bound?
   - What percentage of peak bandwidth does your kernel achieve?
   - What would you do next to improve further?
   - Was the development effort worth the speedup?

## Acceptance Criteria

- [ ] Operation chosen and justified
- [ ] Baseline PyTorch implementation benchmarked
- [ ] Vectorized PyTorch version benchmarked
- [ ] Custom CUDA kernel implemented and correct
- [ ] PyTorch C++/CUDA extension built and loadable
- [ ] Optional Triton version (bonus)
- [ ] Benchmark table completed (6 sizes × 4 versions)
- [ ] Nsight Compute profile captured and analyzed
- [ ] Nsight Systems pipeline profile captured
- [ ] Correctness verified against baseline
- [ ] Integration into Endosight pipeline tested
- [ ] Written report with all 5 questions answered

## Resources

- [PyTorch C++ Extensions](https://docs.pytorch.org/tutorials/advanced/cpp_extension.html)
- [PyTorch CUDA Extension tutorial](https://docs.pytorch.org/tutorials/advanced/cpp_extension.html)
- [CUB library documentation](https://nvidia.github.io/CUB/) — for stream compaction
- [Triton language reference](https://triton-lang.org/)
- [CUDA C++ Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/)
- Your Endosight 3D codebase: `endosight_project/endosight-3d/backend/pipeline/reconstruction/stages/`

## AI Agent Prompt Template

```
I need to write a custom CUDA kernel for [OPERATION] from my Endosight 3D endoscopy 
pipeline, and wrap it as a PyTorch C++/CUDA extension.

Current PyTorch implementation:
[INSERT CURRENT CODE]

The operation processes N points (up to 8 million) and is memory-bound on my 
GB10 DGX Spark (SM121, 273 GB/s LPDDR5X, unified memory).

I need:
1. A CUDA kernel that replaces the PyTorch operation
2. A PyTorch C++ extension wrapper (torch::Tensor in/out)
3. JIT compilation with torch.utils.cpp_extension.load
4. Compiled with: -arch=sm_121 -lineinfo -O3

The kernel should use:
- Coalesced memory access
- Stream compaction (CUB DeviceSelect or warp-level ballot)
- Vectorized loads if applicable

CRITICAL: Do NOT parallelize the pose estimation loop. Only replace this one operation.
Keep the rest of the Endosight pipeline unchanged.
Verify correctness against the PyTorch baseline with max abs error < 1e-5.
```
