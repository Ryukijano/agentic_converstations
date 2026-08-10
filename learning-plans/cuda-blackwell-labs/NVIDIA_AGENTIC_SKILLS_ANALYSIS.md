# How NVIDIA Makes Agentic Skills

An analysis of NVIDIA's approach to building, verifying, and distributing agent skills for AI coding assistants — based on their public repos, documentation, and the skills already installed on this DGX Spark.

---

## What Is an Agentic Skill?

An agentic skill is a **structured knowledge package** that an AI coding assistant (Cursor, Claude Code, Codex, Devin, etc.) can automatically discover and activate during code generation. It contains:

1. **Domain-specific rules** — what to do and what not to do
2. **Reference documentation** — condensed API docs, examples, guardrails
3. **Executable scripts** — pre-flight checks, validation, benchmarking
4. **Evaluation tasks** — test cases that verify the skill improves agent output
5. **Governance metadata** — ownership, license, risks, security scanning

The key insight: **skills eliminate the need to paste the same context into every conversation.** The agent loads the skill once and consults it automatically when a matching task arrives.

---

## The Open Specification: agentskills.io

NVIDIA's skills build on the open [Agent Skills specification](https://agentskills.io/specification), which defines a portable format that works across AI coding assistants.

### Directory Structure

```
skill-name/
├── SKILL.md          # Required: metadata + instructions
├── scripts/          # Optional: executable code
├── references/       # Optional: documentation loaded on demand
├── assets/           # Optional: templates, resources
├── evals/            # Optional: evaluation test cases
├── skill-card.md     # Optional: governance and trust metadata
├── BENCHMARK.md      # Optional: evaluation results
├── skill.oms.sig     # Optional: cryptographic signature
├── .claude-plugin/   # Optional: Claude Code plugin manifest
├── .codex-plugin/    # Optional: Codex plugin manifest
└── .cursor-plugin/   # Optional: Cursor plugin manifest
```

### SKILL.md Format

```markdown
---
name: skill-name
description: "What this skill does and when to use it. This description
  carries the entire burden of triggering — the agent uses it to decide
  whether to activate the skill."
license: Apache-2.0
version: "1.0.0"
compatibility: "Environment requirements: Docker, GPU, CUDA 13.0, etc."
metadata:
  author: NVIDIA Product Team
  tags:
    - cuda
    - optimization
  upstream:
    repo: https://github.com/NVIDIA/product-repo
    branch: main
allowed-tools: Read Shell Edit
---

# Skill Name

## Purpose
[What this skill does, narrowly scoped]

## Prerequisites
[What needs to be installed/configured]

## Limitations
[What this skill does NOT do — critical for preventing overreach]

## Core Rule
[The most important instruction the agent must follow]

## Workflow
[Step-by-step instructions the agent follows]

## References
[Links to bundled reference files in references/]
```

### Progressive Disclosure

Skills use a three-stage loading model:

1. **Discovery** (~50-100 tokens per skill): At startup, the agent loads only `name` and `description` from each skill's frontmatter. This lets it know what skills exist without consuming context.

2. **Activation** (full SKILL.md body): When a task matches a skill's `description`, the agent reads the full `SKILL.md` body into context.

3. **Execution** (references loaded on demand): If the instructions reference files in `references/` or `scripts/`, those load individually as needed — not all at once.

This means a system with 50 skills installed uses ~5,000 tokens at startup, not 500,000.

---

## NVIDIA's Skill Catalog

NVIDIA maintains a central catalog at [github.com/NVIDIA/skills](https://github.com/NVIDIA/skills) (2.8k stars, 529 commits). It mirrors skills from product repos daily via an automated sync pipeline.

### Current Skill Groups

| Group | What it covers | Example skills |
|-------|---------------|----------------|
| **Agentic AI** | RAG, AI-Q, sandboxing, policy, evaluation | aiq-research, aiq-deploy |
| **Conversational AI** | Speech NIMs, ASR/TTS/NMT | nemotron-speech, nemotron-asr-finetune |
| **Data Science** | Data preparation, accelerated analytics | accelerated-computing-cudf, cupynumeric |
| **Decision Optimization** | Routing, scheduling, numerical optimization | cuopt-install, cuopt-routing-api-python |
| **GPU Development** | CUDA-adjacent kernel work, performance tuning | TileGym kernel development |
| **Inference AI** | Model serving, deployment, troubleshooting | Dynamo, NeMo Platform |
| **Simulation & Modeling** | Weather, climate, quantum, physics-ML | Earth2Studio, PhysicsNeMo, CUDA-Q |
| **Physical AI** | Robotics, simulation, synthetic data, neural reconstruction | omniverse-cad-to-simready, physical-ai-neural-reconstruction |
| **Video Analytics** | DeepStream pipeline development | deepstream-dev, deepstream-generate-pipeline, deepstream-profile-pipeline |
| **Model Customization** | Training, fine-tuning, RL alignment | nemotron-customize |

### DeepStream Skills (Most Mature Example)

The [DeepStream Coding Agent](https://github.com/NVIDIA-AI-IOT/DeepStream_Coding_Agent) ships **nine complementary skills**, each with a different operating mode:

| Skill | Mode | Use when |
|-------|------|----------|
| `deepstream-dev` | Reference-rich | Hand-author a pipeline with the agent consulting docs |
| `deepstream-generate-pipeline` | Interactive questionnaire + retrieval | Generate a ready-to-run pipeline by answering questions |
| `deepstream-profile-pipeline` | Measure-then-derive (Nsight Systems) | Benchmark, tune, and measure FPS — agent profiles with `nsys` |
| `deepstream-import-vision-model` | Autonomous orchestration | Take any HuggingFace model and onboard it end-to-end |
| `deepstream-debug-pipeline` | Diagnostic | Debug pipeline issues with structured investigation |
| `deepstream-optimize-pipeline` | Optimization | Optimize pipeline performance with profiler-driven analysis |
| `deepstream-deploy-pipeline` | Deployment | Deploy pipelines to production with containerization |
| `deepstream-multistream` | Scaling | Configure multi-stream video analytics |
| `deepstream-custom-probe` | Extension | Write custom GStreamer probes and plugins |

Each skill follows the same structure:
```
deepstream-dev/
├── SKILL.md              # Routing rules, guardrails, workflow
├── references/           # Condensed API docs (loaded on demand)
├── evals/                # Test cases for skill activation
├── skill-card.md         # Governance metadata
├── BENCHMARK.md          # Evaluation results
├── skill.oms.sig         # Cryptographic signature
└── .claude-plugin/
    └── plugin.json       # Claude Code plugin manifest
```

---

## The NVIDIA Verification Pipeline

NVIDIA doesn't just publish skills — they run a **5-stage trust pipeline** before any skill enters the catalog:

### Stage 1: Security Scanning (SkillSpector)

[SkillSpector](https://github.com/NVIDIA/SkillSpector) scans for **68 vulnerability patterns across 17 categories**:

- Prompt injection (hidden instructions, instruction override)
- Data exfiltration (outbound data transfer)
- Privilege escalation (unauthorized access)
- Supply chain (vulnerable dependencies, OSV.dev lookup)
- Excessive agency (doing more than the description says)
- Output handling (unsafe output to files/shell)
- System prompt leakage
- Memory poisoning
- Tool misuse
- Rogue agent behavior
- Anti-refusal patterns
- Trigger abuse (over-broad activation triggers)
- Dangerous code patterns (AST analysis)
- Taint tracking
- YARA signatures
- MCP least privilege violations
- MCP tool poisoning

Output: risk score 0-100, severity label, `safe_to_install` boolean, and detailed findings.

**Research finding from NVIDIA**: 26.1% of skills contain vulnerabilities, 5.2% show likely malicious intent.

### Stage 2: Deduplication

Semantic overlap check against existing catalog skills — prevents the same capability being published twice under different names.

### Stage 3: Live Evaluation (SkillEvaluator)

The skill is exercised by **real agents** (Claude Code, Codex) in a sandbox against a task set, both **with and without** the skill loaded. Each dimension is scored:

- **Correctness** — does the agent produce right answers?
- **Security** — does the agent avoid risky behavior?
- **Discoverability** — does the skill activate when it should?
- **Effectiveness** — does the skill improve output quality?
- **Efficiency** — does the skill reduce token usage or time?

The difference between with-skill and without-skill scores is the skill's **measured contribution**, published as `BENCHMARK.md`.

### Stage 4: Skill Card

A machine-readable governance document (`skill-card.md`) recording:

| Section | What it answers |
|---------|----------------|
| Description | What does this skill do in one sentence? |
| Owner | Who is accountable for this skill? |
| License/Terms | What rules govern use and redistribution? |
| Use case | Who should use it, and for what purpose? |
| Deployment geography | Where is the skill intended to be used? |
| Requirements/Dependencies | What components are needed? |
| Risks and mitigations | What could go wrong, and how is that reduced? |
| References | What docs, papers, or model cards support this? |
| Skill output | What does the skill produce, and in what format? |
| Skill version | Which release does this card describe? |
| Ethical considerations | What governance or misuse concerns exist? |

### Stage 5: Cryptographic Signing

Each published skill carries a detached OMS signature (`skill.oms.sig`) verifiable against `nv-agent-root-cert.pem`. This ensures the downloaded skill is authentic and unchanged.

---

## How NVIDIA Structures a Real Skill: nemotron-customize

The `nemotron-customize` skill (already installed on this DGX Spark at `~/.agents/skills/nemotron-customize/`) is a good example of the full pattern:

### SKILL.md Structure

```yaml
---
name: nemotron-customize
description: "Plan, configure, and chain repo-native Nemotron customization
  steps into single-step or multi-step pipelines: curation, translation,
  SFT/PEFT, pretraining/CPT, RL alignment, checkpoint conversion, ModelOpt
  optimization, env profiles, and evaluation. Use when a request names a
  Nemotron step or workflow. Do NOT use for frontend/dashboard/visualization
  work, generic ML advice, billing/access, or non-Nemotron coding tasks."
version: 0.1.1
license: Apache-2.0
metadata:
  author: NVIDIA Nemotron Team
  tags: [nemotron, customization, training, pipelines]
---
```

### Key Design Patterns

1. **Narrow scope with explicit exclusions**: The description says "Do NOT use for frontend/dashboard/visualization work, generic ML advice, billing/access, or non-Nemotron coding tasks." This prevents trigger abuse.

2. **Core Rule**: "Use bundled references first. The `references/` folder is the first decision surface for routing, artifacts, patterns, hardware heuristics, and command shape."

3. **Reference hierarchy**: When sources disagree:
   - Checked live repo files win for exact execution
   - Bundled references win for initial routing and planning
   - Upstream docs are used only for exceptional cases

4. **Limitations section**: "Does not invent new catalog steps. When no existing step can satisfy the request, it names the gap instead of fabricating a step."

5. **References directory** with progressive loading:
   ```
   references/
   ├── HARDWARE.md          # GPU heuristics
   ├── ARTIFACTS.md         # Input/output wiring
   ├── COMMANDS.md          # Command shapes
   ├── act/                 # Action-specific docs
   │   ├── STAGE.md
   │   └── PROJECT.md
   └── context/             # Step-specific context (loaded on demand)
       ├── index.toml
       ├── automodel-sft-peft-core.txt
       ├── nemo-rl-alignment.txt
       ├── checkpoint-conversion.txt
       ├── modelopt-optimization.txt
       └── ... (15+ context files)
   ```

6. **Evaluation tasks** at `evals/evals.json` — test cases that verify the skill activates correctly and improves agent output.

7. **Benchmark report** at `BENCHMARK.md` — measured improvement over baseline.

---

## How NVIDIA Distributes Skills

### Installation Methods

```bash
# Install from the NVIDIA catalog (recommended)
npx skills add nvidia/skills

# List available skills before installing
npx skills add nvidia/skills --list

# Install a specific skill
npx skills add nvidia/skills --skill cudaq-guide

# Install for a specific agent
npx skills add nvidia/skills --agent cursor
```

### Discovery Paths

| Agent | Global skills directory | Workspace skills directory |
|-------|------------------------|---------------------------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Codex | `~/.codex/skills/` | `.codex/skills/` |
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` |
| Cross-client standard | `~/.agents/skills/` | `.agents/skills/` |

### What's Already on This DGX Spark

Your system has **24 skills** installed at `~/.agents/skills/`, symlinked into multiple agent directories:

**NVIDIA product skills (2):**
- `nemotron-customize` — Nemotron model customization pipelines
- `physical-ai-neural-reconstruction` — NuRec/NRE router for neural reconstruction

**Research workflow skills (10):**
- `adversarial-review`, `claim-verification`, `experiment-protocol`
- `hypothesis-canvas`, `prisma-systematic-review`, `explore-sota`
- `digest-paper`, `repro-bundle`, `tao-finetune-cosmos-reason`
- `teach`

**Software engineering skills (12):**
- `babysit-pr`, `ci-watcher`, `ship-pr`, `split-to-prs`
- `impact-aware-testing`, `iterative-test-loop`, `tdd-red-green`
- `systematic-debug`, `safe-refactor`, `review-bugbot`, `review-security`
- `loop`

---

## How to Build Your Own CUDA Skill

Based on NVIDIA's pattern, here's how you would build a `cuda-blackwell-labs` skill that teaches AI agents how to help with your learning plan:

### Directory Structure

```
cuda-blackwell-labs/
├── SKILL.md
├── references/
│   ├── gb10-hardware.md          # SM121 specs, constraints, what doesn't work
│   ├── cuda-compilation.md        # nvcc flags, PTX/SASS, sm_121 targeting
│   ├── memory-uma.md             # Unified memory behavior, bandwidth limits
│   ├── tensor-cores.md           # 5th gen TC, FP4/FP8/FP16 support on SM121
│   ├── profiling.md              # ncu/nsys metrics, stall reasons, occupancy
│   └── cutlass-cute.md           # CUTLASS 4.x, CuTe DSL, SM121 compatibility
├── scripts/
│   ├── preflight.sh              # Check nvcc, ncu, nsys, compute-sanitizer
│   └── verify_kernel.sh          # Correctness + profiling wrapper
├── evals/
│   └── evals.json                # Test cases for skill activation
├── assets/
│   ├── kernel_template.cu        # Starter CUDA kernel template
│   └── benchmark_template.py     # Benchmark harness template
└── skill-card.md
```

### SKILL.md

```markdown
---
name: cuda-blackwell-labs
description: "Guide CUDA kernel development and optimization on NVIDIA GB10
  DGX Spark (SM121, Blackwell, unified LPDDR5X memory). Use when writing
  CUDA kernels, profiling with Nsight, inspecting PTX/SASS, benchmarking
  GEMM, testing Tensor Core precisions, or building PyTorch CUDA extensions
  for GB10. Do NOT use for non-GB10 architectures, frontend work, or
  generic ML advice."
license: Apache-2.0
version: "0.1.0"
compatibility: "GB10 DGX Spark, CUDA 13.0, driver 580.142, Ubuntu 24.04 ARM64"
metadata:
  author: Gyanateet Dutta
  tags: [cuda, blackwell, gb10, kernel, profiling]
allowed-tools: Read Shell Edit
---

# CUDA Blackwell Labs

## Purpose

Guide AI coding assistants to produce correct, optimized CUDA code for the
NVIDIA GB10 DGX Spark (SM121, Blackwell architecture, unified LPDDR5X memory).

## Critical Constraints

The GB10 is NOT a B200. The following features do NOT exist on SM121:
- TMEM (Tensor Memory)
- WGMMA (Warp Group Matrix Multiply Accumulate)
- DSMEM (Distributed Shared Memory)
- NVSwitch
- Some CUTLASS FP4 paths (may produce silent garbage output)

Memory is unified LPDDR5X (273 GB/s peak, ~180 GB/s sustained), NOT HBM.
cudaMemGetInfo() underreports available memory because the OS can reclaim
page cache. Always cross-check with /proc/meminfo.

Compile with: nvcc -arch=sm_121 -lineinfo

## Core Rule

Always verify CUDA code with:
1. compute-sanitizer --tool memcheck (correctness)
2. ncu --set full (performance metrics)
3. cuobjdump --dump-sass (instruction verification)
4. CPU reference comparison (numerical correctness)

Never accept "it compiles and runs" as success.

## References

- [GB10 Hardware](references/gb10-hardware.md) — SM121 specs, what works, what doesn't
- [CUDA Compilation](references/cuda-compilation.md) — nvcc, PTX, SASS
- [Memory & UMA](references/memory-uma.md) — Unified memory behavior
- [Tensor Cores](references/tensor-cores.md) — Precision support on SM121
- [Profiling](references/profiling.md) — Nsight metrics and stall reasons
- [CUTLASS/CuTe](references/cutlass-cute.md) — SM121 compatibility
```

---

## Key Takeaways

1. **NVIDIA treats skills as software artifacts**, not just text files. They have versioning, signatures, evaluation, security scanning, and governance.

2. **The description field is the most important part of a skill.** It carries the entire burden of triggering. A good description says what the skill does AND what it does NOT do.

3. **Progressive disclosure keeps context small.** Skills load in three stages: name+description at startup, full SKILL.md on activation, references on demand.

4. **References are the knowledge base.** NVIDIA's `nemotron-customize` skill has 15+ context files that load individually. The DeepStream skills have condensed API docs that the agent consults before writing code.

5. **Evaluation is mandatory for NVIDIA-verified skills.** Every skill is tested with real agents against task sets, with and without the skill, to prove it improves output.

6. **Security scanning is non-negotiable.** SkillSpector checks for 68 vulnerability patterns. 26.1% of unscanned skills contain vulnerabilities.

7. **The cross-client standard is `.agents/skills/`.** This is already on your system. Your existing skills are symlinked from `~/.agents/skills/` into Cursor, Devin, and Windsurf directories.

8. **You already have NVIDIA skills installed.** `nemotron-customize` and `physical-ai-neural-reconstruction` are on your system. Study their structure as templates for building your own.

---

## Resources

- [NVIDIA/skills GitHub repo](https://github.com/NVIDIA/skills) — central catalog (2.8k stars)
- [NVIDIA Skill Documentation](https://docs.nvidia.com/skills) — official docs
- [agentskills.io specification](https://agentskills.io/specification) — open format spec
- [NVIDIA SkillSpector](https://github.com/NVIDIA/SkillSpector) — security scanner
- [DeepStream Coding Agent](https://github.com/NVIDIA-AI-IOT/DeepStream_Coding_Agent) — most mature skill example
- [DeepStream skills in mono-repo](https://github.com/NVIDIA/DeepStream/tree/main/skills) — 9 skills
- [NVIDIA Trustworthy AI](https://github.com/NVIDIA/Trustworthy-AI) — skill card generator
- [NVIDIA blog: Verified Agent Skills](https://developer.nvidia.com/blog/nvidia-verified-agent-skills-provide-capability-governance-for-ai-agents/) — announcement blog
- [skills.sh catalog](https://www.skills.sh/nvidia/skills) — web catalog
- [NVIDIA Glossary: Agent Skills](https://www.nvidia.com/en-us/glossary/agent-skills/) — definition
