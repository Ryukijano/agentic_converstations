# Learning to Generate Quantum Circuits: Policy Optimization for Hamiltonian-Conditioned Ansatz Synthesis

**Ryoushi | Quantum Buddies** — Gyanateet Dutta, Dat Chi Le, Sid Iliyasu
GIC 2026, Mitsubishi Chemical & AIST track — Advanced Materials

---

## 1. Problem

Variational quantum eigensolvers place the burden of ansatz design on the practitioner. A circuit topology is chosen — hardware-efficient layers, UCCSD excitations, an adaptively grown operator sequence — and its rotation angles are then optimized against the electronic Hamiltonian. Two failure modes follow. Expressive ansätze produce optimization landscapes whose gradients vanish exponentially in system size. Compact ansätze avoid this but require domain knowledge that does not transfer between molecules, and must be reconstructed for every new system.

The generative quantum eigensolver reframes the first half of this problem. Rather than fixing a topology and optimizing parameters inside the circuit, a classical generative model is trained to emit operator sequences directly, moving the variational parameters into neural network weights. Prior work in this direction — GPT-QE, SpinGQE — trains one decoder-only model per Hamiltonian instance. The model does not generalize; it is a search procedure with a learned prior.

H-cGQE addresses the second half. The generator is conditioned on the Hamiltonian itself, so a single policy covers a set of molecules rather than one. Whether this conditioning produces genuine zero-shot transfer to unseen molecular families remains an open benchmark item in our own evaluation, and we state it as such below rather than as a result.

This document describes the pipeline and, in particular, the policy optimization procedure, which is where most of the difficulty turned out to lie.

---

## 2. Pipeline

The system spans five stages across three compute tiers: a local HPC cluster (28 nodes × 3 NVIDIA L40S), cloud GPU instances (H200, B200), and physical QPUs accessed through qBraid.

**Stage 1 — Hamiltonian construction.** PySCF computes the Hartree-Fock reference and one- and two-electron integrals. An active space is selected, ranging from CAS(2,2) to CAS(20,20) depending on target. OpenFermion applies the Jordan-Wigner transformation, yielding

$$H = \sum_{pq} h_{pq}\, a_p^\dagger a_q + \tfrac{1}{2}\sum_{pqrs} h_{pqrs}\, a_p^\dagger a_q^\dagger a_s a_r \;\longrightarrow\; H = \sum_{i=1}^{M} c_i P_i,$$

with $P_i \in \{I,X,Y,Z\}^{\otimes N_q}$. Records carry Pauli terms, coefficients, qubit count, and Hartree-Fock and FCI reference energies where the latter is computable. The GIC molecule set comprises 35 systems spanning 4 to 28 qubits, with a separate 40-qubit extension set.

**Stage 2 — Supervised warm start.** An encoder-decoder transformer (7.79M parameters, $d_{\text{model}}=256$, four encoder and four decoder layers, vocabulary 317) is trained by teacher-forced cross-entropy on operator sequences harvested from a CUDA-Q GQE baseline. AdamW, learning rate $6.4\times10^{-4}$, cosine annealing with 10-epoch warmup, label smoothing 0.1, and a commutator penalty ramped over 100 epochs. Training runs 500 epochs in BF16; validation loss reaches 1.037 with 96.2% token accuracy, converging near epoch 200 under early stopping with patience 60.

**Stage 3 — Reinforcement learning.** The warm-started policy is fine-tuned against energies computed by CUDA-Q. This stage is the subject of Section 3.

**Stage 4 — Continuous parameter optimization.** Generated operator sequences fix a circuit topology; rotation angles are then optimized classically by multi-start L-BFGS-B (five restarts) with expectation values evaluated through asynchronous `cudaq.observe_async()` across GPUs. The separation is deliberate: discrete topology search and continuous angle fitting have different landscapes and different optimizers suit each.

**Stage 5 — Evaluation.** Exact statevector simulation up to 24 qubits locally (28 on B200), MPS tensor-network simulation from 24 to 40 qubits with bond dimension swept over $D \in \{32,64,128,256\}$, QSCI subspace diagonalization for the largest active spaces, and physical execution on Rigetti Cepheus-1-108Q with SQD post-processing.

---

## 3. Policy optimization

### 3.1 Why a policy-gradient method

The objective is to minimize $E(s) = \min_{\boldsymbol\theta} \langle \psi(s,\boldsymbol\theta)|H|\psi(s,\boldsymbol\theta)\rangle$ over discrete operator sequences $s$. The map from $s$ to $E(s)$ is non-differentiable and expensive — each evaluation is a quantum-circuit simulation. Supervised learning cannot be applied because no ground-truth optimal sequence exists to imitate; the CUDA-Q baseline sequences used for warm start are themselves greedy approximations.

We use Group Relative Policy Optimization (Shao et al., arXiv:2402.03300) as the base. GRPO removes the learned value function, replacing per-state baselines with the empirical mean over a group of $G$ rollouts sampled from the same conditioning context:

$$A_i = \frac{R_i - \mu_{\text{group}}}{\sigma_{\text{group}} + \epsilon}.$$

For this problem the choice is not merely economical. A value network would have to predict converged energies from circuit structure — a regression problem at least as hard as the one being solved. Group-relative normalization sidesteps it entirely, and also handles the fact that absolute energies differ by four orders of magnitude across the molecule set (methyl iodide near $-6890$ Ha, H₂ near $-1.1$ Ha), which would otherwise dominate any shared-scale baseline.

### 3.2 Decoupled clipping

Standard PPO clips the importance ratio symmetrically to $[1-\epsilon, 1+\epsilon]$. Applied to low-probability tokens this is asymmetric in effect: a token at $\pi_{\theta_{\text{old}}} = 0.01$ can rise to at most $0.012$ under $\epsilon = 0.2$, while a token at $0.9$ can fall to $0.72$. Probability mass drains from the tail, entropy collapses, and the policy converges prematurely on whatever operators happened to be favoured after warm start.

DAPO (arXiv:2503.14476) decouples the bounds. We use $\epsilon_{\text{low}} = 0.2$, $\epsilon_{\text{high}} = 0.28$, giving rare operators more room to gain mass when they prove advantageous. In an operator-pool setting this matters more than in language modelling: the useful double excitations for a given molecule are a small subset of a large pool, and they are exactly the tokens that start with low probability under a warm start trained on a different distribution.

We supplement this with an entropy bonus ($10^{-2}$), adaptive temperature scheduling over $[0.7, 2.0]$ targeting entropy 1.5, top-$p$ nucleus sampling at 0.9, a frequency penalty of 1.0 against repeated operator emission, and REPO-style entropy regulation at $\beta = 0.05$ (arXiv:2603.11682). Observed mean policy entropy during stable training sits near 3.3–4.0.

### 3.3 Dynamic sampling

When every rollout in a group receives the same reward, $\sigma_{\text{group}} = 0$, all advantages vanish, and the group contributes gradient noise scaled by $1/\epsilon$ but no signal. In language RL this is an edge case. Here it is routine: distinct operator sequences frequently prepare states with identical energies, because operators acting on unoccupied orbitals leave the Hartree-Fock reference unchanged, and because permutations of commuting operators are physically equivalent.

Groups with $\sigma_{\text{group}} < 10^{-8}$ are skipped. Instrumented runs show this triggering on roughly half of early batches on small molecules — an equivalent fraction of wasted quantum-simulation cost recovered.

### 3.4 Token-level credit assignment

Loss is computed per token rather than per sequence. A sequence-level objective assigns the same advantage to every operator in a length-20 circuit, including operators that contributed nothing. Token-level weighting lets the gradient distinguish positions, which matters because circuit length is itself under selection pressure through the depth term in the reward.

### 3.5 Off-policy reuse

Rollout cost is dominated by energy evaluation, not by the transformer forward pass — typically by two to three orders of magnitude. Sampling 16 circuits takes 0.1–0.4 s; evaluating them on a 20-qubit Hamiltonian takes minutes. Off-policy GRPO with $\mu$-reuse (arXiv:2505.22257) takes $\mu = 3$ gradient steps per rollout batch, with the importance ratio $\exp(\log \pi_\theta - \log \pi_{\theta_{\text{old}}})$ correcting for the policy drift this introduces. A FIFO replay buffer of 2000 entries provides additional off-policy samples.

A persistent SQLite cache keyed on circuit hash stores every evaluated energy. Across long runs a substantial fraction of proposed circuits are repeats — the cache converts these to lookups. The same cache is used to pre-populate the replay buffer before RL begins, and can be warmed offline by a separate precomputation pass (512 circuits per molecule below 28 qubits, 128 above).

### 3.6 Reward design and the gating problem

The reward is a weighted sum,

$$r = w_1\!\left(-\frac{E}{|E_{\text{ref}}|}\right) + w_2\, f_{\text{ent}} + w_3\!\left(-\frac{d}{d_{\max}}\right) + w_4\, f_{\text{nc}} + w_5\, f_{\text{div}},$$

with $f_{\text{ent}}$ the fraction of entangling operators, $d$ circuit depth, $f_{\text{nc}}$ the fraction of non-commuting operator pairs, and $f_{\text{div}}$ a diversity term.

The auxiliary terms exist because energy alone is a sparse and often flat signal early in training. They also invite reward hacking: a policy can maximize entanglement fraction and non-commuting fraction while producing circuits that are worse than Hartree-Fock. We observed this directly. The fix is to gate $w_2$–$w_5$ on energy improvement — auxiliary terms are zeroed unless $E < E_{\text{HF}} - \delta$. Structural rewards only apply to circuits that have already earned them.

### 3.7 The reward proxy was measuring nothing

The most consequential finding of the project came from asking whether the reward signal was real.

To keep RL affordable, reward energies were computed at fixed rotation angle $\theta = 0.01$ rather than running full L-BFGS-B per rollout — roughly a 50× saving. The assumption was that fixed-$\theta$ energy ranks circuits in the same order as converged energy, even if the absolute values differ.

We tested it. Fifteen generated circuits for iodobenzene were evaluated both at $\theta = 0.01$ and after five-restart L-BFGS-B convergence, and the Spearman rank correlation computed:

> $\rho = 0.227$, $p = 0.416$.

The proxy carried no usable ranking information. Inspection of the raw values explains why: at $\theta = 0.01$ every circuit returned $-7078.008313$ Ha — the Hartree-Fock energy — with differences appearing only at the eleventh decimal place. After convergence the same circuits spread across roughly 8 mHa, from $-7078.001$ to $-7078.009$ Ha. As $\theta \to 0$ every parameterized circuit approaches the identity, so the proxy was reporting the reference state regardless of the topology it was supposed to be scoring. The policy had been optimizing numerical noise.

The correction runs truncated L-BFGS-B (10 iterations) on the best circuit in each batch and uses that energy for reward, raising rank correlation against the converged energy to approximately 0.5. It costs roughly 50× more per reward evaluation, which is what the persistent cache and off-policy reuse are there to absorb.

This is worth stating plainly because it is a general hazard in generative circuit design. A cheap surrogate reward is standard practice, and a surrogate that returns the reference-state energy for every input will train a policy that looks healthy — entropy stays high, loss decreases, rewards move — while learning nothing about the Hamiltonian.

### 3.8 Quality-diversity

Energy-greedy policy gradients converge to a single circuit family. A MAP-Elites archive discretizes a two-dimensional behaviour space — entanglement density against circuit depth — and retains the best circuit found in each cell. Rollouts landing in unoccupied cells receive a novelty bonus. This preserves structurally distinct solutions that a pure energy objective would discard, and provides a pool of candidate circuits at different depths for the QPU stage, where the shallowest viable circuit is preferred regardless of its simulated energy. A representative run held 708 elite circuits across 32 molecules by epoch 24.

### 3.9 Configuration

Main run: 300 epochs, 64 rollouts per epoch, 5 inner iterations, learning rate $10^{-5}$ — an order of magnitude below SFT, standard for stable RL fine-tuning. KL coefficient 0.05 against the reference policy. Curriculum learning introduces molecules in three stages over a 30-epoch warmup, ordered by qubit count from 4 upward. Statevector simulation below 24 qubits, MPS above, with bond dimension 64.

---

## 4. Diagonal sequence collapse

During Phase 2 the policy converged reproducibly onto sequences of Pauli words drawn from $\{I,Z\}^{\otimes N_q}$. These operators mutually commute, and a product of $Z$-type rotations acting on a computational basis state returns that state up to a global phase. The energy expectation therefore remains pinned at the Hartree-Fock value, the gradient with respect to every rotation angle vanishes, and the policy receives no signal distinguishing one such sequence from another. It is a stable attractor: once entered, nothing pushes the policy out.

The remedy is structural rather than statistical. Under Jordan-Wigner, a single fermionic excitation $A_{pq} = a_p^\dagger a_q - a_q^\dagger a_p$ maps to two Pauli strings, and a double excitation $A_{pqrs}$ to eight. Every one of them contains an odd number of $Y$ operators. Restricting the decoder vocabulary to a UCCSD-derived operator pool therefore eliminates diagonal $Z$-only generators by construction — not by penalizing them, but by removing them from the sample space. Any sequence the policy can emit drives off-diagonal configuration mixing.

Two additional measures operate at the training level. A `--force-entanglement` filter rejects diagonal-only sequences at sampling time as a defence against pool construction errors. A commutator penalty $L_{\text{comm}} = \sum_{i<j} \lVert [P_i, P_j] \rVert$ enters the supervised loss with weight 0.1, ramped over 100 epochs, discouraging the policy from selecting mutually commuting operators even within the constrained pool. At inference, trailing non-entangling operators are trimmed from generated sequences.

The distinction matters when reporting: the correct claim is that UCCSD-constrained pools eliminate diagonal generators by construction, not that a training procedure achieved zero collapse.

---

## 5. Ablations

**Warm start is necessary above four qubits.** Direct RL from a randomly initialized policy reaches $-1.1165$ Ha on H₂, within 0.8 mHa of FCI. On LiH the same configuration returns 0.0 Ha — the policy failed to emit any valid circuit — with mean entropy declining from 3.13 to 2.86 as exploration narrowed without ever finding a viable region. Supervised warm start on baseline sequences is what makes the RL stage tractable at scale.

**Fixed-$\theta$ reward is not a valid proxy above small systems.** Quantified in Section 3.7.

**Dynamic sampling recovers wasted evaluation.** Roughly half of early-training groups on small molecules are degenerate and are skipped.

---

## 6. Evaluation and hardware execution

**Classical simulation.** GPU statevector evaluation across 17 benchmark systems places H₂ at three geometries and methyl iodide within chemical accuracy (0.00, 0.15, 0.77, and 1.59 mHa respectively). LiH at 1.6 Å (1.85 mHa), iodobenzene (2.97 mHa), 4-iodo-2-methylphenol (24.78 mHa), and stretched N₂ (126.77 mHa) do not reach it. Error grows with active-space size and with static correlation, as expected for a compact ansatz.

In a controlled comparison on methyl iodide, CAS(4,4), the H-cGQE circuit followed by L-BFGS-B reaches 0.63 mHa against the active-space reference, compared with 2.65 mHa for the CUDA-Q GQE baseline and 987.79 mHa for hardware-efficient VQE under COBYLA at 200 iterations.

**Subspace scaling.** QSCI evaluates a 40-qubit benzene CAS(20,20) representation with 29,897 Hamiltonian terms from 34 sampled determinants in 18.6 s sampling and 0.33 s diagonalization. This is a subspace method — the sampled determinant set defines the accuracy ceiling, and 34 bitstrings is a thin basis for a system of that size. It demonstrates that the pipeline runs at that width, not that the 40-qubit ground state has been converged.

**Fragmentation.** Two-fragment FMO2 on 4-iodo-2-methylphenol reproduces the parent energy exactly, as it must when one- and two-body terms cancel at two fragments. A three-fragment decomposition of iodobenzene incurs 11.34 mHa of fragmentation error, which is the informative number: prototype FMO2 omits environmental electrostatic embedding.

**Physical hardware.** Twelve circuits were executed on Rigetti Cepheus-1-108Q at 8192 shots with SQD post-processing. Errors against FCI run from 13.95 mHa (methyl iodide, CAS(6,6) on 12 qubits) to 130.05 mHa (N₂ on 20 qubits). No error mitigation was applied. Given median two-qubit CZ fidelity near 99.1% and $T_2 \approx 10\ \mu$s on that device, this range is what one expects; reaching chemical accuracy on hardware requires zero-noise extrapolation and readout mitigation, which is Phase 4 work.

The QPU path uses qubit-wise-commuting term grouping to reduce measurement circuits — 15 to 5 for H₂, 631 to 180 for LiH, 2951 to 1308 for N₂ — and batches groups into single asynchronous submissions to avoid per-task fees, which dominate cost at these term counts. A SQLite ledger enforces budget limits, deduplicates by circuit hash, and classifies transient against permanent failures for retry.

---

## 7. Limitations

1. **Conditioning is partial.** The chemistry GNN encoder and FMO conditioning modules exist in the codebase but are not wired into the active RL checkpoint. Cross-molecule generalization should be described as an architectural direction supported by the encoder-decoder design, not as a demonstrated capability. Zero-shot transfer to unseen molecular families has not been benchmarked under a strict train/holdout split.

2. **The optimizer is DAPO-inspired.** Decoupled clipping, dynamic sampling, and token-level loss are implemented and instrumented. Not every component of the published DAPO method has been independently ablated in this setting, and the description should carry that qualification.

3. **Hardware results are unmitigated.** 13.95–130.05 mHa is two orders of magnitude from chemical accuracy.

4. **Subspace sampling is shallow.** 34–54 bitstrings for 28–40 qubit systems. Determinant coverage scales with RL sequence depth, currently $L \sim 20$ against a target of $L \sim 4N_q$.

5. **Reward surrogate remains approximate.** Truncated L-BFGS-B raises rank correlation to roughly 0.5, which is usable but not tight. A learned critic predicting converged energy from circuit structure is the obvious next step.

---

## 8. Contributors

**[CTO — NAME]** identified the challenge as worth committing to and set the technical direction that held across all three phases. The decision to frame circuit synthesis as conditional sequence generation, rather than as another variational ansatz variant, is what made the rest of the work possible.

**[RYAN — CONFIRM ROLE]** carried the physics review. The fixed-$\theta$ proxy audit in Section 3.7 is his — the observation that a cheap surrogate reward could be returning the Hartree-Fock energy for every circuit, and the insistence on measuring the rank correlation rather than assuming it. The result ($\rho = 0.227$, $p = 0.416$) invalidated the reward signal the RL stage had been running on and forced its redesign. Finding that a system is optimizing noise, in a training run that otherwise appears healthy, is the kind of check that separates a working method from one that only looks like it works.

**Sid Iliyasu** built the systems discipline: run manifests capturing git state and package versions, the SQLite QPU ledger enforcing budget and idempotency, the reproducibility scripts, and the forensic audit that cross-checked every reported figure against raw result files and caught a submission-compliance failure the rest of us had walked past. Reported numbers in this document are traceable to JSON artifacts because of that infrastructure.

---

## References

Shao et al., *DeepSeekMath* (GRPO), arXiv:2402.03300 · DAPO, arXiv:2503.14476 · Off-policy GRPO with $\mu$-reuse, arXiv:2505.22257 · REPO, arXiv:2603.11682 · Nakaji et al., *GQE*, arXiv:2401.09253 · Holden et al., *SpinGQE*, arXiv:2603.24298 · Grimsley et al., *ADAPT-VQE*, Nat. Commun. **10**, 3007 (2019) · Kitaura et al., *FMO*, Chem. Phys. Lett. **313**, 701 (1999) · Kanno et al., *QSCI*, arXiv:2302.11320 · Robledo-Moreno et al., *SQD*, arXiv:2405.05068 · Mouton et al., *MAP-Elites*, arXiv:1504.04909 · Sun et al., *PySCF*, J. Chem. Phys. **153**, 024109 (2020)

---

## Open items

- **CTO name and role** — not in the Phase 3 author list (Gyanateet Dutta, Dat Chi Le, Sid Iliyasu). Advisor, sponsor, or fourth member?
- **Ryan** — also not in the author list. Preferred name for Dat Chi Le, or a separate reviewer? I have attributed the fixed-$\theta$ audit to him from `physicist_verification_report.md`, which credits "the physicist." Confirm before circulating.
- **Reward weights** $w_1$–$w_5$ — the functional form is documented across your notes but the numerical values are not. Worth pinning down for reproducibility.
- **Checkpoint provenance** — `h_cgqe_rl_gic2026.pt` is named as the submission checkpoint in `PIPELINE_RESULTS_SUMMARY.md`, while `h_cgqe_model_b200_rl_main.pt` is the B200 main run. Confirm which produced the reported benchmarks.
