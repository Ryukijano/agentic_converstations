# MCP Servers and Tools

Custom MCP servers for the DGX Spark that work both as direct CLI tools AND as MCP tools for AI coding agents (Cursor, Devin, Claude, Windsurf, Gemini).

## Quick Start

```bash
# 1. Install all MCP servers into all agents
bash install_all.sh

# 2. Test a server in CLI mode
python3 servers/dgx_monitor/server.py --cli gpu_status

# 3. Test with MCP Inspector (web UI)
npx @modelcontextprotocol/inspector python3 servers/dgx_monitor/server.py

# 4. Restart your AI agents to pick up the new servers
```

## What's Included

### 4 Custom MCP Servers

| Server | Tools | Purpose |
|--------|-------|---------|
| **dgx-monitor** | 11 | GPU status, memory, Docker, conda, CUDA info, kernel compilation |
| **cuda-profiling** | 10 | nsys/ncu profiling, compute-sanitizer (memcheck/racecheck/initcheck), SASS/PTX dump, benchmarking |
| **endosight-pipeline** | 8 | Pipeline status, clip listing, reconstruction stats, verification, sweep, reconstruction trigger |
| **research-workflow** | 8 | ArXiv search, paper download, BibTeX management, experiment tracking, Semantic Scholar |

### NVIDIA CUDA MCP Server (Hosted)

Also installed: `nvidia-cuda-docs` — NVIDIA's hosted MCP server giving agents access to up-to-date CUDA documentation. Requires NVIDIA Developer account (free) on first connection.

## Dual CLI + MCP Interface

Every server has two modes:

```bash
# CLI mode — you use it directly
python3 servers/dgx_monitor/server.py --cli gpu_status
python3 servers/dgx_monitor/server.py --cli conda_envs
python3 servers/cuda_profiling/server.py --cli memcheck --command ./my_kernel

# MCP mode — agents call it via stdio
# (configured automatically by install_all.sh)
```

## Available Tools

### DGX Monitor (`dgx-monitor`)

| Tool | What it does |
|------|-------------|
| `gpu_status` | GPU utilization, memory, temperature, power (with GB10 unified memory fallback) |
| `gpu_processes` | Processes using GPU memory |
| `kill_gpu_process` | Kill a GPU process by PID |
| `system_memory` | System RAM usage (critical for unified memory) |
| `disk_usage` | Disk space check |
| `docker_ps` | Running containers |
| `docker_logs` | Container logs |
| `docker_gpu_stats` | Which containers are using GPU |
| `conda_envs` | List conda environments |
| `conda_packages` | List packages in an environment |
| `cuda_info` | CUDA/nvcc/driver versions |
| `compile_cuda` | Compile .cu with correct SM121 flags |

### CUDA Profiling (`cuda-profiling`)

| Tool | What it does |
|------|-------------|
| `profile_nsys` | Nsight Systems timeline profiling |
| `parse_nsys_stats` | Parse nsys report stats |
| `profile_ncu` | Nsight Compute kernel profiling |
| `parse_ncu_report` | Parse ncu report metrics |
| `memcheck` | compute-sanitizer memory error detection |
| `racecheck` | compute-sanitizer data race detection |
| `initcheck` | compute-sanitizer uninitialized memory detection |
| `dump_sass` | Dump SASS instructions |
| `dump_ptx` | Dump PTX intermediate representation |
| `benchmark_kernel` | Multi-run timing benchmark |

### Endosight Pipeline (`endosight-pipeline`)

| Tool | What it does |
|------|-------------|
| `list_clips` | List available endoscopy clips |
| `list_reconstructions` | List completed reconstructions |
| `get_reconstruction_stats` | Point count, mesh info, file sizes |
| `pipeline_status` | Check BFF/Node/Vite/Postgres status |
| `start_pipeline` | Instructions to start the pipeline |
| `verify_pipeline` | Run verify.sh |
| `sweep_clinical_clips` | Run clinical clip sweep |
| `run_reconstruction` | Trigger reconstruction via BFF upload |

### Research Workflow (`research-workflow`)

| Tool | What it does |
|------|-------------|
| `search_arxiv` | Search arXiv by keywords |
| `get_arxiv_paper` | Get paper metadata, optionally download PDF |
| `add_to_bibtex` | Add paper to BibTeX file |
| `search_bibtex` | Search BibTeX database |
| `list_experiments` | List experiment directories |
| `create_experiment` | Create new experiment with metadata |
| `log_experiment` | Append to experiment log |
| `search_semantic_scholar` | Search Semantic Scholar API |

## Agent Configuration

Servers are registered in these config files:

| Agent | Config file |
|-------|------------|
| Cursor | `~/.cursor/mcp.json` |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |
| Claude Code | `~/.claude/mcp.json` |
| Devin | `~/.config/devin/mcp_config.json` |
| Gemini | `~/.gemini/config/mcp_config.json` |

## GB10-Specific Notes

- **Unified memory**: nvidia-smi reports `[N/A]` for GPU memory fields on GB10. The `gpu_status` tool falls back to `free -h` for memory info.
- **Compile flags**: `compile_cuda` defaults to `-arch=sm_121 -lineinfo` for GB10.
- **No HBM**: Memory bandwidth is ~273 GB/s peak (LPDDR5X), not HBM. Profile carefully.

## NVIDIA Nsight Copilot Blueprint (Optional)

To deploy the self-hosted CUDA AI backend on your DGX Spark:

```bash
git clone https://github.com/NVIDIA-AI-Blueprints/nsight-copilot
cd nsight-copilot
# Follow docs/deploy-docker-self-hosted.md
```

Requirements: Docker Compose v2, NVIDIA Container Toolkit, 200 GB disk, NGC API key.
The blueprint auto-detects DGX Spark and sizes models to fit the 128 GB unified memory pool.

## Adding More Tools

To add a new tool to any server, edit the `server.py` file and add a function with the `@server.tool()` decorator:

```python
@server.tool()
def my_new_tool(
    arg1: Annotated[str, "Description of arg1"],
    arg2: Annotated[int, "Description of arg2"] = 10,
) -> str:
    """What this tool does (this becomes the tool description for agents)."""
    # Your logic here
    return "result"
```

Then add it to the `TOOLS` dict at the bottom of the file for CLI mode.
