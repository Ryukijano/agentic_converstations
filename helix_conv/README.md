# Conditional-GQE → Quaggle demo packs

Precomputed circuits from [Quantum-Buddies/Conditional_GQE](https://github.com/Quantum-Buddies/Conditional_GQE)
(`scripts/export_quaggle_demo.py`). These are **not** trained live in Quaggle.

| Pack | Qubits | Notes |
|------|--------|--------|
| `iodobenzene_gqe_demo.qasm` | 8 | Shallow (depth ~15) — preferred booth / smoke demo |
| `h2_gqe_demo.qasm` | 4 | Deeper (many operators) — still parses |

## Import in Quaggle

1. Open Circuit Builder → **Import**
2. Format: **OpenQASM 2**
3. Paste or choose the `*_demo.qasm` file → **Import to canvas**
4. Select a **Simulator** backend → **Run with Agent** (or Set up and run)
5. Compare energies / notes in the matching `*_metadata.json`

Full Conditional-GQE (PySCF, RL, CUDA-Q, qBraid QPU) stays on HPC; Quaggle is for
visualize → sim run → Run Card → Reproduce.
