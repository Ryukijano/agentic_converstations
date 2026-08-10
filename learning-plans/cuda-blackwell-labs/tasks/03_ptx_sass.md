# Task 03: CUDA → PTX → SASS Pipeline

**Phase:** 1 — Hardware and Memory Literacy
**Prerequisites:** Task 01, Task 02
**Estimated sessions:** 2-3

---

## Objective

Trace a simple CUDA kernel through the entire compilation pipeline: source code → PTX (virtual ISA) → SASS (machine code). Learn to read both and understand what the compiler does to your code.

## Why This Matters

If you cannot read PTX and SASS, you are guessing about what your kernel does. The compiler may unroll loops, predicate branches, vectorize loads, or reorder instructions in ways that change performance dramatically. This project teaches you to see what actually executes on the SM.

## Instructions

### Part A: Write a Simple Kernel

```cpp
__global__ void saxpy(const float* x, float* y, float a, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        y[i] = a * x[i] + y[i];
    }
}
```

### Part B: Compile Multiple Versions

```bash
# SASS for GB10
nvcc -arch=sm_121 -lineinfo -O0 saxpy.cu -o saxpy_O0
nvcc -arch=sm_121 -lineinfo -O3 saxpy.cu -o saxpy_O3

# PTX (virtual ISA)
nvcc -arch=compute_121 -ptx saxpy.cu -o saxpy.ptx

# Also try older architectures for comparison
nvcc -arch=sm_80 -lineinfo -O3 saxpy.cu -o saxpy_sm80
nvcc -arch=sm_90 -lineinfo -O3 saxpy.cu -o saxpy_sm90
```

### Part C: Inspect PTX

```bash
cuobjdump --dump-ptx saxpy_O3
```

Learn to identify:
- `.reg` declarations (register allocation)
- `ld.global.f32` (global memory load)
- `st.global.f32` (global memory store)
- `mul.f32`, `add.f32`, `fma.rn.f32` (arithmetic)
- `setp` (predicate setup for the bounds check)
- `@%p` (predicated execution)
- `mad.s32` (integer multiply-add for index calculation)
- `exit` (kernel exit)

### Part D: Inspect SASS

```bash
cuobjdump --dump-sass saxpy_O3
nvdisasm --print-line-info saxpy_O3
```

Learn to identify:
- `LDG.E.128` (global load, 128-bit vectorized)
- `STG.E.128` (global store, 128-bit vectorized)
- `FFMA` (fused multiply-add)
- `IADD3` (integer add)
- `IMAD` (integer multiply-add)
- `ISETP` (integer set predicate)
- `@P0` (predicated instruction)
- `EXIT` (kernel exit)
- Register usage (`R0`, `R1`, ... `R255`)
- Uniform registers (`UR0`, `UR1`, ...)
- Special registers (`SR0` for thread ID, etc.)

### Part E: Compare O0 vs O3

Diff the SASS output:
```bash
diff <(cuobjdump --dump-sass saxpy_O0) <(cuobjdump --dump-sass saxpy_O3)
```

Document what the optimizer changed:
- Did it vectorize loads? (look for `LDG.E.128` vs `LDG.E.32`)
- Did it use FMA? (look for `FFMA` vs separate `FMUL` + `FADD`)
- Did it predicate the branch? (look for `@P0` instead of `BRA`)
- Did it unroll any loops?
- How many registers does each version use?

### Part F: Repeat with Variations

Compile and compare SASS for these kernel variants:

1. Add `__restrict__` to pointers
2. Use `float4` vectorized loads
3. Use shared memory tiling
4. Add `__launch_bounds__(256, 2)`
5. Unroll the loop manually with `#pragma unroll`

For each variant, note:
- Register count change
- Instruction count change
- New instruction types
- Performance change (if any)

### Part G: Architecture Comparison

Compare SASS for the same kernel compiled for:
- `sm_80` (Ampere)
- `sm_90` (Hopper)
- `sm_121` (GB10 Blackwell)

Note architectural differences in instruction encoding, register usage, and available instructions.

## Deliverable

A report containing:

1. **Annotated PTX listing** for `saxpy_O3` with comments explaining each instruction
2. **Annotated SASS listing** for `saxpy_O3` with comments explaining each instruction
3. **O0 vs O3 comparison table**: register count, instruction count, vectorization, FMA usage, predication
4. **Variant comparison table**: 5 kernel variants with register count and key SASS differences
5. **Architecture comparison table**: sm_80 vs sm_90 vs sm_121 SASS differences
6. **Written explanation** of why the compiler made each optimization choice

## Acceptance Criteria

- [ ] PTX generated and annotated
- [ ] SASS generated and annotated
- [ ] O0 vs O3 comparison completed with at least 5 differences identified
- [ ] 5 kernel variants compiled and compared
- [ ] 3 architecture targets compared
- [ ] Report explains compiler optimization choices

## Resources

- [PTX: The Assembly Language of CUDA](https://developer.nvidia.com/blog/understanding-ptx-the-assembly-language-of-cuda-gpu-computing/)
- [Blackwell GPU Wiki: CUDA Pipeline](https://0xsero.github.io/blackwell-gpu-wiki/fundamentals/cuda-pipeline/)
- [Blackwell Compatibility Guide](https://docs.nvidia.com/cuda/blackwell-compatibility-guide/)
- `cuobjdump --help` and `nvdisasm --help`
- [PTX ISA Reference](https://docs.nvidia.com/cuda/parallel-thread-execution/)

## AI Agent Prompt Template

```
I have a simple SAXPY CUDA kernel compiled for sm_121 (GB10 Blackwell). I need to 
understand the PTX and SASS output. Please help me:

1. Generate PTX with: nvcc -arch=compute_121 -ptx saxpy.cu
2. Generate SASS with: cuobjdump --dump-sass saxpy_O3
3. Annotate every PTX instruction with what it does
4. Annotate every SASS instruction with what it does
5. Explain what the -O3 optimizer changed vs -O0
6. Check if loads were vectorized (LDG.E.128 vs LDG.E.32)
7. Check if FMA was used (FFMA vs FMUL+FADD)
8. Check if the branch was predicated (@P0 vs BRA)

The kernel is:
__global__ void saxpy(const float* x, float* y, float a, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) y[i] = a * x[i] + y[i];
}
```
