# Create Cosmos3 comparison canvas
_Exported on 6/5/2026 at 13:12:41 GMT+1 from Cursor (3.5.38)_

---

**User**

Create the Cosmos3 8B vs 32B comparison canvas. Prior agents: 32B research completed; 8B/canvas agents did not finish. Canvas file does NOT exist yet.

## Canvas path (REQUIRED)
`/home/aimsgroupuol/.cursor/projects/home-aimsgroupuol/canvases/cosmos3-8b-vs-32b.canvas.tsx`

Read canvas skill: `/home/aimsgroupuol/.cursor/skills-cursor/canvas/SKILL.md`
Read SDK: `/home/aimsgroupuol/.cursor/skills-cursor/canvas/sdk/index.d.ts`

## Research to embed (verify + supplement from local files)
Read:
- `/home/aimsgroupuol/AIMSgeneral/DGX_SPARK_SETUP.md`
- `/home/aimsgroupuol/AIMSgeneral/scripts/run_cosmos3_t2v_spark.py`
- `/home/aimsgroupuol/AIMSgeneral/models/Cosmos3-Nano/README.md` if exists
- List `/home/aimsgroupuol/AIMSgeneral/outputs/` for proof of successful Nano runs

## Key facts for canvas (from completed 32B research + local evidence)

**8B tier = Cosmos3-Nano (`nvidia/Cosmos3-Nano`)**
- 16B total (8B reasoner + 8B generator MoT)
- Pipeline: Cosmos3OmniPipeline
- Output: result.video (NOT .frames), result.sound
- ~33GB weights cached locally; T2V works on Spark (GB10, 128GB unified) — cosmos3_spark_test.mp4, cosmos3_spark_sanity.mp4 exist
- Tasks: T2V, I2V, T2I, video+sound, action (same modalities as Super, lower quality)

**32B tier — two distinct products:**
1. Cosmos3-Super (`nvidia/Cosmos3-Super`) — 64B total (32B+32B), same Cosmos3OmniPipeline, ~128GB+ weights, needs 8× H200 (2× min). NOT feasible on Spark.
2. Cosmos-Reason2-32B — reasoning VLM only (Qwen3VL), ~64-90GB inference, no video generation. Marginal on Spark for planning/VLM.

**Spark recommendation matrix:**
- Endoscopy/surgical T2V experiments → Nano (works today)
- Highest quality omni gen → Super on multi-GPU cluster
- Physical reasoning without gen → Reason2-32B (optional adjunct)

## Canvas requirements
- Comparison table, VRAM bar chart, recommendation matrix, "works on Spark today" section with evidence
- useHostTheme() tokens only, no slop patterns, labeled plots with source captions
- Default export, import only from cursor/canvas

Return absolute path to canvas file when done.

---

**Cursor**

Composer. Creating the Cosmos3 comparison canvas: reading the canvas skill, SDK, and local research files first.


Building the comparison canvas from verified local evidence and framework docs.


Fixing the broken comparison-table row and cleaning up type issues.


Composer

The comparison canvas is ready. A **canvas** is a live React panel you can open beside this chat for structured, visual analysis.

**Open:** [cosmos3-8b-vs-32b](/home/aimsgroupuol/.cursor/projects/home-aimsgroupuol/canvases/cosmos3-8b-vs-32b.canvas.tsx)

**Absolute path:** `/home/aimsgroupuol/.cursor/projects/home-aimsgroupuol/canvases/cosmos3-8b-vs-32b.canvas.tsx`

### What’s inside
- **Summary stats** — Nano works on Spark; Super needs multi-GPU; Reason2 is marginal
- **“Works on Spark today”** — evidence from `cosmos3_spark_test.mp4` (27 KB), `cosmos3_spark_sanity.mp4` (13 KB), 33 GB HF cache, `Cosmos3OmniPipeline` → `result.video` / `result.sound`
- **Comparison table** — Nano (16B MoT / 8B+8B) vs Super (64B / 32B+32B) vs Reason2-32B (VLM only)
- **VRAM bar chart** — 33 / 32 / 128 / 77 GB with axis caption and sources
- **UsageBar** — Nano footprint vs 128 GB Spark budget
- **Recommendation matrix** — surgical T2V → Nano; best omni → Super cluster; reasoning → Reason2 adjunct
- **Deployment card** — `spark-1240`, AIMSgeneral paths, `run_cosmos3_t2v_spark.py`

Facts were checked against `DGX_SPARK_SETUP.md`, `run_cosmos3_t2v_spark.py`, `models/Cosmos3-Nano/README.md`, and `cosmos-framework/docs/faq.md` (32 GB / 128 GB memory table).

