# H-cGQE on IBM hardware — runbook & results notes

Persistent notes from Quaggle ↔ Conditional-GQE demo work (July 2026).
Circuits are **precomputed** by [Conditional_GQE](https://github.com/Quantum-Buddies/Conditional_GQE)
(H-cGQE transformer + L-BFGS-B); Quaggle visualizes, submits, and tracks them.

## What GQE is

The **Generative Quantum Eigensolver (GQE)** ([Nakaji et al., arXiv:2401.09253](https://arxiv.org/abs/2401.09253))
uses a classical generative model (e.g. a transformer) to design short quantum circuits
that approximate molecular ground states — an alternative to VQE parameter optimization.

In this pack, **H-cGQE / Conditional-GQE** exports OpenQASM demos:
Hartree–Fock (HF) initial state + a few Pauli-rotation operators from the trained model.

Metadata energies (e.g. iodobenzene **−7078.009 Ha**) come from **classical evaluation**
of ⟨ψ|H|ψ⟩ when the circuit was designed — **not** from the QPU histogram.

## Demo circuits

| File | Qubits | Gates | Molecule | Notes |
|------|--------|-------|----------|-------|
| `iodobenzene_gqe_demo.qasm` | 8 | ~26 | C₆H₅I | Preferred booth / smoke demo (shallow) |
| `h2_gqe_demo.qasm` | 4 | ~148 | H₂ | Deep 20-op — best **noise** demo |
| `h2_0.74_gqe_demo.qasm` | 4 | 26 | H₂ | Equilibrium, compact |
| `methyl_iodide_gqe_demo.qasm` | 8 | 21 | CH₃I | EUV photoresist |
| `phenol_gqe_demo.qasm` | 8 | 21 | C₆H₅OH | EUV photoresist |
| `imeph_gqe_demo.qasm` | 8 | 21 | IMePh | EUV photoresist |
| `lih_1.6_gqe_demo.qasm` | 8 | 25 | LiH | Equilibrium |
| `lih_1.2_gqe_demo.qasm` | 8 | 25 | LiH | Stretched bond |
| `n2_1.1_gqe_demo.qasm` | 12 | 47 | N₂ | Strongly correlated |

Suggested **single-circuit** smoke order on `ibm_fez`: iodobenzene (shallow) or H2 deep (noise).
**Do not** auto-submit the full table to live QPUs unless explicitly requested (queue cost / IBM units).

## How to run on live IBM QPU (critical path)

Live hardware submit is **Set up and run**, not **Run with Agent**
(agent path uses local sim + trust gate).

```
Browser → Circuit Builder → import *_demo.qasm
  → select ibm_fez, 1024 shots
  → Set up and run
  → Vite /api/ibm-proxy → scripts/local-ibm-proxy.mjs
  → Qiskit ISA transpile → IBM Sampler V2 → ibm_fez
```

### Local prerequisites

1. Branch with Sampler V2 + ISA fixes (e.g. `cursor/ibm-sampler-v2-2b59`).
2. `.secrets/ibm.env` with `IBM_API_KEY=…`
3. `pip install -r scripts/requirements-ibm-proxy.txt`
4. `node scripts/local-ibm-proxy.mjs` (port **8787**)
5. `npm run dev` (port **8080**; Vite proxies `/api/ibm-proxy` → local proxy)

Login (prototype): `testing@ryoushi.com` / `PrototypeTesting`

### One-circuit browser automation

```bash
# scripts/browser-ibm-qpu-gqe.mjs defaults to iodobenzene; override path if needed
IBM_BACKEND=ibm_fez IBM_SHOTS=1024 node scripts/browser-ibm-qpu-gqe.mjs
```

### Hosted Supabase `ibm-proxy` caveat

Hosted edge function historically used **Sampler V1** → IBM error **1513**.
Until redeployed with V2 + `IBM-API-Version` from `supabase/functions/ibm-proxy/index.ts`,
**local proxy is required** for successful QPU runs.

### Errors we hit and fixes

| Error | Cause | Fix |
|-------|-------|-----|
| IBM **1513** | Sampler V1 payload | Sampler V2 pubs + API version header |
| IBM **1517** | Raw QASM (`h`, `cx`, …) not ISA | `scripts/ibm_transpile_isa.py` before submit |
| HTTP **403** | Cloudflare blocks bare UA | Browser-like `User-Agent` in local proxy |
| Client gate block | Builder rejects unsupported gates | `allowUnsupported: true` for IBM QPU |
| Mock-looking counts on Run Detail | Early poll / wrong V2 parse | Parse V2 `samples`; keep polling until counts arrive |

## What a hardware histogram means

A QPU histogram is **computational-basis shot counts**, not energy.

Under Jordan–Wigner-style occupation encoding:

- each qubit ≈ one spin-orbital
- `|1⟩` = occupied, `|0⟩` = empty
- each bitstring ≈ one electronic configuration (Slater determinant)

IBM bit order for these demos: string left→right ≈ `meas[n-1]…meas[0]` with `meas[i] ← q[i]`.

### Iodobenzene — job `d9g1cfhhtsac739g2vag`

| Field | Value |
|-------|-------|
| Backend | `ibm_fez` |
| Shots | 1024 |
| Circuit | `iodobenzene_gqe_demo.qasm` (8q, HF + 2 Pauli ops) |
| Dominant | **`\|00001111⟩` = 867/1024 (84.7%)** |
| Unique outcomes | 18 |

**Decoding `00001111`:** circuit starts with `x` on `q[0]…q[3]` (4 electrons in lowest orbitals) → HF configuration. Shallow GQE slightly perturbs HF; hardware still peaks there. Spread (~15%) is NISQ noise (gates, decoherence, readout), not a chemistry energy.

**84.7% is:** empirical peaking / state-quality on hardware.  
**84.7% is not:** the −7078 Ha metadata energy, chemical accuracy, or proof of exact ground state.

Random over 2⁸ bitstrings would top out ~0.4%/outcome; 84.7% is a clear non-random peak.

### H2 deep — job `d9j93lgii2cc73eeg0cg`

| Field | Value |
|-------|-------|
| Backend | `ibm_fez` |
| Shots | 1024 |
| Circuit | `h2_gqe_demo.qasm` (4q, ~148 gates; ISA depth ~251) |
| Dominant | **`\|0011⟩` = 744/1024 (72.7%)** |
| Quaggle run | `run_ms2ek1je` |

Deeper circuit → lower peaking than iodobenzene, as expected on NISQ.

Artifacts from that run (local cloud env):

- `/opt/cursor/artifacts/h2-deep-ibm-fez-histogram.png`
- `/opt/cursor/artifacts/screenshots/gqe-batch-1-h2_gqe_demo-*.png`

### UI gotcha

Run Detail may briefly show **uniform placeholder counts** (e.g. 256 each on 4 states).
**Trust IBM Sampler V2 `results.*.data.*.samples`**, not the early receipt mock distribution.

## Mental model (one sentence)

> The GQE circuit prepares an approximate molecular state; measuring it counts **which electron configurations** appear — a tall peak (e.g. iodobenzene `00001111` at 84.7%) means the intended HF-dominated pattern survived real `ibm_fez` noise.

## Going further

1. **Energy on hardware** — measure Pauli expectations for ⟨H⟩; one Z-basis sample is not enough.
2. **Compare to noiseless sim** — sharper peak ⇒ hardware noise is the main spread.
3. **Readout mitigation** — calibration matrices can tighten histograms toward ideal.

## Related code / scripts

| Path | Role |
|------|------|
| `scripts/local-ibm-proxy.mjs` | Local Sampler V2 + ISA proxy (:8787) |
| `scripts/ibm_transpile_isa.py` | Qiskit ISA transpile |
| `scripts/browser-ibm-qpu-gqe.mjs` | One-circuit Playwright E2E |
| `scripts/browser-ibm-focused.mjs` | Focused single submit + poll |
| `scripts/browser-ibm-gqe-batch.mjs` | Multi-circuit batch — **use only when explicitly asked** |
| `supabase/functions/ibm-proxy/index.ts` | Hosted proxy (must stay on V2) |
| `*_metadata.json` | Classical energies / operator lists |

## References

- [GQE paper (arXiv:2401.09253)](https://arxiv.org/abs/2401.09253)
- [PennyLane GQE training demo](https://www.pennylane.ai/qml/demos/gqe_training)
- [Jordan–Wigner / qubit mappers (Qiskit Nature)](https://qiskit-community.github.io/qiskit-nature/tutorials/06_qubit_mappers.html)
