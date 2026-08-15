/*
 * probe.cu - GB10 Hardware Probe (CUDA Blackwell Labs Project 1)
 *
 * A secure, self-contained diagnostic that queries the NVIDIA GB10 GPU
 * via the CUDA Runtime API and cross-checks reported memory against
 * Linux /proc/meminfo to demonstrate the unified memory architecture (UMA).
 *
 * Security design:
 *   - No user-controlled format strings (all printf format strings are literal).
 *   - No popen(), system(), or shell execution from the executable.
 *   - No network I/O, no IPC handles, no secrets.
 *   - Fixed-size buffers and checked file operations.
 *   - All CUDA calls are checked and reported without aborting the program.
 *
 * Build:
 *   nvcc -arch=sm_121 -lineinfo probe.cu -o probe
 *   nvcc -arch=compute_121 -ptx probe.cu -o probe.ptx
 */

#include <cuda_runtime_api.h>
#include <cstdarg>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cerrno>
#include <string>

// Default log file inside the project results directory.
static const char* LOG_PATH = "results/probe_output.txt";
static FILE* g_log = nullptr;

// Print to stdout and the log file. 'fmt' must always be a string literal.
static void log_printf(const char* fmt, ...) __attribute__((format(printf, 1, 2)));
static void log_printf(const char* fmt, ...)
{
    va_list args, args_copy;
    va_start(args, fmt);
    va_copy(args_copy, args);
    vprintf(fmt, args);
    if (g_log) {
        vfprintf(g_log, fmt, args_copy);
    }
    va_end(args_copy);
    va_end(args);
}

#define CUDA_CHECK(expr)                                                       \
    do {                                                                       \
        cudaError_t err = (expr);                                              \
        if (err != cudaSuccess) {                                              \
            log_printf("  CUDA error at %s:%d: %s\n",                          \
                       __FILE__, __LINE__, cudaGetErrorString(err));           \
        }                                                                      \
    } while (0)

static void print_section(const char* title)
{
    log_printf("\n=== %s ===\n", title);
}

static void print_kv(const char* key, const char* value)
{
    log_printf("  %-40s %s\n", key, value);
}

static void print_kv_int(const char* key, long value)
{
    log_printf("  %-40s %ld\n", key, value);
}

static void print_kv_size(const char* key, size_t bytes)
{
    double gb = static_cast<double>(bytes) / (1024.0 * 1024.0 * 1024.0);
    double mib = static_cast<double>(bytes) / (1024.0 * 1024.0);
    log_printf("  %-40s %zu bytes  (%.2f MiB, %.3f GiB)\n", key, bytes, mib, gb);
}

static void print_kv_freq(const char* key, int khz)
{
    double mhz = static_cast<double>(khz) / 1000.0;
    log_printf("  %-40s %d kHz  (%.2f MHz)\n", key, khz, mhz);
}

static void print_kv_bandwidth(const char* key, double gbps)
{
    log_printf("  %-40s %.2f GB/s\n", key, gbps);
}

static void print_kv_bool(const char* key, int value)
{
    log_printf("  %-40s %s\n", key, value ? "Yes" : "No");
}

// ---------------------------------------------------------------------------
// Device property helpers
// ---------------------------------------------------------------------------

static const char* getComputeModeName(int mode)
{
    switch (mode) {
        case 0: return "Default";
        case 1: return "Exclusive thread";
        case 2: return "Prohibited";
        case 3: return "Exclusive process";
        default: return "Unknown";
    }
}

static void print_device_properties(int device)
{
    cudaDeviceProp prop;
    memset(&prop, 0, sizeof(prop));

    cudaError_t err = cudaGetDeviceProperties(&prop, device);
    if (err != cudaSuccess) {
        log_printf("  Failed to get device properties: %s\n", cudaGetErrorString(err));
        return;
    }

    log_printf("\nDevice %d\n", device);

    // Basic identity
    log_printf("  %-40s %s\n", "Device name:", prop.name);
    log_printf("  %-40s %d.%d\n", "Compute capability:", prop.major, prop.minor);

    // Streaming multiprocessors and threads
    // SM count is also queried via cudaDeviceGetAttribute to match the task spec.
    int sm_count = 0;
    CUDA_CHECK(cudaDeviceGetAttribute(&sm_count, cudaDevAttrMultiProcessorCount, device));
    print_kv_int("SM count:", sm_count);
    print_kv_int("Warp size:", prop.warpSize);
    print_kv_int("Max threads per block:", prop.maxThreadsPerBlock);
    print_kv_int("Max threads per SM:", prop.maxThreadsPerMultiProcessor);
    log_printf("  %-40s (%d, %d, %d)\n", "Max threads per block per dim:",
               prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);

    // Shared memory
    print_kv_size("Shared memory per block (default):", prop.sharedMemPerBlock);
    print_kv_size("Shared memory per block (max):", prop.sharedMemPerBlockOptin);
    print_kv_size("Shared memory per SM:", prop.sharedMemPerMultiprocessor);

    // Registers and constant memory
    print_kv_int("Register file size per block:", prop.regsPerBlock);
    print_kv_int("Register file size per SM:", prop.regsPerMultiprocessor);
    print_kv_size("Total constant memory:", prop.totalConstMem);

    // Cache and memory
    print_kv_size("L2 cache size:", prop.l2CacheSize);
    log_printf("  %-40s %d bits\n", "Memory bus width:", prop.memoryBusWidth);

    int mem_clock_khz = 0;
    CUDA_CHECK(cudaDeviceGetAttribute(&mem_clock_khz, cudaDevAttrMemoryClockRate, device));
    print_kv_freq("Memory clock rate:", mem_clock_khz);

    // Peak bandwidth = clock (kHz) * bus width (bits) * 2 (DDR) / 8 (bits/byte) / 1e6 (kHz*bits->GB/s)
    // Note: cudaDevAttrMemoryClockRate returns kHz; the formula above is kHz * bits / 4,000,000.
    double peak_gbps = static_cast<double>(mem_clock_khz) *
                       static_cast<double>(prop.memoryBusWidth) * 2.0 / 8.0 / 1e6;
    print_kv_bandwidth("Peak memory bandwidth (calc):", peak_gbps);

    // Runtime features
    print_kv_bool("Concurrent kernels support:", prop.concurrentKernels);
    print_kv_int("Async engine count:", prop.asyncEngineCount);
    print_kv_bool("Unified addressing support:", prop.unifiedAddressing);
    print_kv_bool("Managed memory support:", prop.managedMemory);
    print_kv_bool("Multi-GPU board:", prop.isMultiGpuBoard);
    print_kv_bool("TCC driver mode:", prop.tccDriver);

    // PCI bus ID (safe fixed-size buffer)
    char pci_bus_id[32];
    memset(pci_bus_id, 0, sizeof(pci_bus_id));
    CUDA_CHECK(cudaDeviceGetPCIBusId(pci_bus_id, sizeof(pci_bus_id), device));
    if (strlen(pci_bus_id) > 0) {
        print_kv("PCI bus ID:", pci_bus_id);
    }

    // Compute mode is not in cudaDeviceProp in this CUDA version; query it explicitly.
    int compute_mode = 0;
    CUDA_CHECK(cudaDeviceGetAttribute(&compute_mode, cudaDevAttrComputeMode, device));
    log_printf("  %-40s %s\n", "Compute mode:", getComputeModeName(compute_mode));
}

static void print_device_attributes(int device)
{
    int value = 0;
    struct AttrEntry {
        const char* label;
        cudaDeviceAttr attr;
    };

    // Attributes not already covered by cudaDeviceProp or requiring explicit query.
    // Note: cudaDevAttrGraphSupport and cudaDevAttrCooperativeMultiDeviceLaunch are not
    // available in CUDA 13.0, so we skip them. Graph support is inferred from the runtime
    // version below and cooperative multi-device is not a separate query here.
    AttrEntry attrs[] = {
        {"Cooperative launch support",       cudaDevAttrCooperativeLaunch},
        {"Memory pools support",             cudaDevAttrMemoryPoolsSupported},
    };

    log_printf("\nDevice %d attributes\n", device);
    for (const auto& a : attrs) {
        cudaError_t err = cudaDeviceGetAttribute(&value, a.attr, device);
        if (err == cudaSuccess) {
            print_kv_bool(a.label, value);
        } else if (err == cudaErrorInvalidValue) {
            log_printf("  %-40s not supported on this CUDA version\n", a.label);
        } else {
            log_printf("  %-40s query failed: %s\n", a.label, cudaGetErrorString(err));
        }
    }

    // Graph support has no device attribute in CUDA 13.0, but the runtime API exposes it.
    int runtime_version = 0;
    CUDA_CHECK(cudaRuntimeGetVersion(&runtime_version));
    print_kv_bool("Graph support (runtime API):", runtime_version >= 10020);
}

// ---------------------------------------------------------------------------
// UMA memory cross-check
// ---------------------------------------------------------------------------

struct MemInfo {
    long mem_total_kb;
    long mem_free_kb;
    long mem_available_kb;
    long buffers_kb;
    long cached_kb;
    long swap_total_kb;
    long swap_free_kb;
};

static int read_proc_meminfo(MemInfo* out)
{
    const char* path = "/proc/meminfo";
    FILE* f = fopen(path, "r");
    if (!f) {
        log_printf("  Failed to open %s: %s\n", path, strerror(errno));
        return -1;
    }

    memset(out, 0, sizeof(*out));
    out->mem_total_kb = -1;
    out->mem_free_kb = -1;
    out->mem_available_kb = -1;
    out->buffers_kb = -1;
    out->cached_kb = -1;
    out->swap_total_kb = -1;
    out->swap_free_kb = -1;

    char line[256];
    while (fgets(line, sizeof(line), f)) {
        long value = 0;
        if (sscanf(line, "MemTotal: %ld kB", &value) == 1 && value >= 0) {
            out->mem_total_kb = value;
        } else if (sscanf(line, "MemFree: %ld kB", &value) == 1 && value >= 0) {
            out->mem_free_kb = value;
        } else if (sscanf(line, "MemAvailable: %ld kB", &value) == 1 && value >= 0) {
            out->mem_available_kb = value;
        } else if (sscanf(line, "Buffers: %ld kB", &value) == 1 && value >= 0) {
            out->buffers_kb = value;
        } else if (sscanf(line, "Cached: %ld kB", &value) == 1 && value >= 0) {
            out->cached_kb = value;
        } else if (sscanf(line, "SwapTotal: %ld kB", &value) == 1 && value >= 0) {
            out->swap_total_kb = value;
        } else if (sscanf(line, "SwapFree: %ld kB", &value) == 1 && value >= 0) {
            out->swap_free_kb = value;
        }
    }

    fclose(f);
    return 0;
}

static double kb_to_gb(long kb)
{
    return static_cast<double>(kb) / (1024.0 * 1024.0);
}

static double bytes_to_gb(size_t bytes)
{
    return static_cast<double>(bytes) / (1024.0 * 1024.0 * 1024.0);
}

static void print_uma_cross_check(void)
{
    print_section("UMA Memory Cross-Check");

    size_t cuda_free = 0, cuda_total = 0;
    cudaError_t err = cudaMemGetInfo(&cuda_free, &cuda_total);
    if (err != cudaSuccess) {
        log_printf("  cudaMemGetInfo failed: %s\n", cudaGetErrorString(err));
        return;
    }

    MemInfo mi;
    if (read_proc_meminfo(&mi) != 0) {
        log_printf("  Could not read /proc/meminfo\n");
        return;
    }

    long page_cache_kb = (mi.buffers_kb > 0 ? mi.buffers_kb : 0) +
                         (mi.cached_kb > 0 ? mi.cached_kb : 0);
    long theoretical_kb = (mi.mem_available_kb > 0 ? mi.mem_available_kb : 0) +
                          (page_cache_kb > 0 ? page_cache_kb : 0) +
                          (mi.swap_free_kb > 0 ? mi.swap_free_kb : 0);

    log_printf("  %-40s %.3f GiB\n", "CUDA-reported free memory:", bytes_to_gb(cuda_free));
    log_printf("  %-40s %.3f GiB\n", "CUDA-reported total memory:", bytes_to_gb(cuda_total));
    log_printf("  %-40s %.3f GiB\n", "Linux total memory:", kb_to_gb(mi.mem_total_kb));
    log_printf("  %-40s %.3f GiB\n", "Linux free memory:", kb_to_gb(mi.mem_free_kb));
    log_printf("  %-40s %.3f GiB\n", "Linux available memory:", kb_to_gb(mi.mem_available_kb));
    log_printf("  %-40s %.3f GiB\n", "Linux page cache (Buffers + Cached):", kb_to_gb(page_cache_kb));
    log_printf("  %-40s %.3f GiB\n", "Swap total:", kb_to_gb(mi.swap_total_kb));
    log_printf("  %-40s %.3f GiB\n", "Swap available:", kb_to_gb(mi.swap_free_kb));
    log_printf("  %-40s %.3f GiB\n", "Theoretical allocatable:", kb_to_gb(theoretical_kb));

    print_section("UMA Explanation");
    log_printf(
        "The NVIDIA GB10 in the DGX Spark uses a Unified Memory Architecture (UMA) "
        "where the CPU and GPU share the same 128 GiB of LPDDR5X. Because the OS can "
        "reclaim memory from the page cache, buffers, and even swap pages to disk, the "
        "amount of DRAM that can be made available to a GPU allocation is larger than "
        "what cudaMemGetInfo() reports.\n\n"
    );
    log_printf(
        "cudaMemGetInfo() only sees the memory that the CUDA driver currently considers "
        "free, which does not include reclaimable page-cache or swap-backed pages. "
        "Therefore, the 'Linux available memory' and 'theoretical allocatable' figures "
        "are upper bounds, while the CUDA-reported free memory is a conservative lower "
        "bound. A large GPU allocation may succeed even when cudaMemGetInfo() reports "
        "less free memory than the allocation size, because the OS can reclaim cache "
        "or swap cold pages on demand.\n\n"
    );
    log_printf(
        "On a traditional discrete GPU, cudaMemGetInfo() closely matches the physical "
        "VRAM state because the GPU owns dedicated framebuffer memory. On GB10 UMA, "
        "it underreports the actual allocatable space, so application-level memory "
        "planning should treat it as a conservative estimate and rely on Linux memory "
        "accounting for a more optimistic bound.\n"
    );
}

// ---------------------------------------------------------------------------
// A tiny kernel so the PTX file contains a kernel name
// ---------------------------------------------------------------------------

__global__ void probe_kernel(float* out, int n)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        out[i] = out[i] * 2.0f + 1.0f;
    }
}

static int run_kernel_smoke_test(void)
{
    print_section("Kernel Smoke Test");

    const int n = 256;
    const size_t bytes = n * sizeof(float);

    float host_in[n];
    for (int i = 0; i < n; ++i) {
        host_in[i] = static_cast<float>(i);
    }

    float* dev = nullptr;
    cudaError_t err = cudaMalloc(&dev, bytes);
    if (err != cudaSuccess) {
        log_printf("  cudaMalloc failed: %s\n", cudaGetErrorString(err));
        return -1;
    }

    err = cudaMemcpy(dev, host_in, bytes, cudaMemcpyHostToDevice);
    if (err != cudaSuccess) {
        log_printf("  cudaMemcpy H2D failed: %s\n", cudaGetErrorString(err));
        cudaFree(dev);
        return -1;
    }

    probe_kernel<<<(n + 31) / 32, 32>>>(dev, n);
    err = cudaGetLastError();
    if (err != cudaSuccess) {
        log_printf("  Kernel launch failed: %s\n", cudaGetErrorString(err));
        cudaFree(dev);
        return -1;
    }

    err = cudaDeviceSynchronize();
    if (err != cudaSuccess) {
        log_printf("  cudaDeviceSynchronize failed: %s\n", cudaGetErrorString(err));
        cudaFree(dev);
        return -1;
    }

    float host_out[n];
    err = cudaMemcpy(host_out, dev, bytes, cudaMemcpyDeviceToHost);
    if (err != cudaSuccess) {
        log_printf("  cudaMemcpy D2H failed: %s\n", cudaGetErrorString(err));
        cudaFree(dev);
        return -1;
    }

    cudaFree(dev);

    // Verify a couple of outputs without printing the whole array.
    int ok = 1;
    for (int i = 0; i < n; ++i) {
        float expected = host_in[i] * 2.0f + 1.0f;
        if (host_out[i] != expected) {
            ok = 0;
            break;
        }
    }

    if (ok) {
        print_kv("probe_kernel smoke test:", "PASSED");
    } else {
        print_kv("probe_kernel smoke test:", "FAILED");
        return -1;
    }

    return 0;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

int main(int argc, char* argv[])
{
    // Optional: allow a different log path via command line for testability.
    // This path is never used in a format string, and we validate it minimally.
    const char* log_path = LOG_PATH;
    if (argc > 1) {
        if (argv[1] == nullptr) {
            fprintf(stderr, "Invalid log path: NULL\n");
            return 1;
        }
        // Reject paths containing '..' or leading '-' to avoid accidents.
        // Also reject control characters that could confuse a later viewer.
        size_t len = strnlen(argv[1], 4096);
        if (len == 0 || len >= 4096 || argv[1][0] == '-' ||
            strstr(argv[1], "..") != nullptr ||
            strpbrk(argv[1], "\r\n\t\x01-\x1f\x7f") != nullptr) {
            fprintf(stderr, "Invalid log path: %s\n", argv[1]);
            return 1;
        }
        log_path = argv[1];
    }

    g_log = fopen(log_path, "w");
    if (!g_log) {
        fprintf(stderr, "Warning: cannot open %s for writing: %s\n",
                log_path, strerror(errno));
        fprintf(stderr, "Continuing with stdout only.\n");
    }

    log_printf("GB10 Hardware Probe\n");
    log_printf("Generated by CUDA Blackwell Labs Project 1\n");

    int device_count = 0;
    cudaError_t err = cudaGetDeviceCount(&device_count);
    if (err != cudaSuccess) {
        log_printf("cudaGetDeviceCount failed: %s\n", cudaGetErrorString(err));
        if (g_log) fclose(g_log);
        return 1;
    }

    log_printf("\nFound %d CUDA device(s)\n", device_count);
    for (int i = 0; i < device_count; ++i) {
        print_device_properties(i);
        print_device_attributes(i);
    }

    // Multi-device peer access summary.
    print_section("Multi-Device Support");
    if (device_count < 2) {
        log_printf("  Multi-device peer access:                No (only %d device present)\n",
                   device_count);
    } else {
        int peer_count = 0;
        for (int i = 0; i < device_count; ++i) {
            for (int j = 0; j < device_count; ++j) {
                if (i == j) continue;
                int can_access = 0;
                cudaError_t perr = cudaDeviceCanAccessPeer(&can_access, i, j);
                if (perr == cudaSuccess && can_access) {
                    log_printf("  Device %d can access peer device %d\n", i, j);
                    ++peer_count;
                }
            }
        }
        if (peer_count == 0) {
            log_printf("  No peer access between detected devices.\n");
        }
    }

    print_uma_cross_check();
    run_kernel_smoke_test();

    log_printf("\n=== End of probe ===\n");

    if (g_log) {
        fclose(g_log);
        g_log = nullptr;
    }

    return 0;
}
