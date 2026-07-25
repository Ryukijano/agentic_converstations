# Repository Structure

Complete directory structure and file organization for the agentic_converstations repository.

## Directory Tree

```
agentic_converstations/
│
├── README.md                          # Repository overview, research context, citation
├── QUICKSTART.md                      # 5-minute getting started guide
├── INDEX.md                           # Searchable catalog of all conversations with metadata
├── CONTRIBUTING.md                    # Contribution guidelines and privacy checklist
├── STRUCTURE.md                       # This file - repository organization reference
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore patterns for sensitive files
│
├── .github/                           # GitHub-specific configurations
│   └── ISSUE_TEMPLATE/
│       └── conversation-submission.md # Issue template for conversation submissions
│
├── conversations/                     # All conversation transcripts organized by domain
│   │
│   ├── quantum-computing/             # 2 conversations
│   │   ├── Improve H-cGQE RL Training for GIC.md
│   │   └── qBraid Credit Usage and Integration.md
│   │
│   ├── computer-vision/               # 15 conversations
│   │   ├── 3D Endoscopy Pipeline Setup.md
│   │   ├── Cholec80 Predict Agentic Loop.md
│   │   ├── cursor_3d_reconstruction_server_setup.md
│   │   ├── cursor_3d_reconstruction_server_setup (1).md
│   │   ├── cursor_explore_mot_training_pipeline.md
│   │   ├── cursor_explore_mot_training_pipeline (1).md
│   │   ├── cursor_locateanything_hermes_audit.md
│   │   ├── cursor_qa_gating_and_reconstruction_wor.md
│   │   ├── Debug VLLM Multimodal Error.md
│   │   ├── Endosight Robust Deployment Phase 2.md
│   │   ├── ESD-WORLD TAO LoRA Setup.md
│   │   ├── RAE ViT Decoder Integration.md
│   │   ├── Refine TDV Training Output.md
│   │   ├── RF-DETR Ablation Plotting.md
│   │   └── RF-DETR vs RT-DETR Performance.md
│   │
│   ├── robotics-embodied-ai/          # 3 conversations
│   │   ├── cursor_nvidia_ai_hack_project_overview.md
│   │   ├── Deploy GR00T SO-101 Model.md
│   │   └── NVIDIA Suite Integration and Deployment.md
│   │
│   ├── infrastructure-devops/         # 2 conversations
│   │   ├── cursor_dgx_spark_setup_and_requirements.md
│   │   └── Fixing SLURM Conda Activation.md
│   │
│   └── general-development/           # 6 conversations
│       ├── Convert Science Skills to Agent Formats.md
│       ├── cursor_chat_location_inquiry.md
│       ├── cursor_create_cosmos3_comparison_canvas.md
│       ├── cursor_repo_understanding.md
│       ├── cursor_repo_understanding (1).md
│       └── Windows Compatibility for AI Models.md
│
├── templates/                         # Conversation export templates
│   ├── README.md                      # Template usage guide
│   ├── basic-conversation.md          # Standard conversation format
│   ├── debugging-session.md           # Structured debugging workflow
│   └── deployment-walkthrough.md      # Deployment process template
│
└── metadata/                          # Metadata schemas and specifications
    └── schema.yaml                    # Complete metadata field definitions
```

## File Count Summary

| Category | Count | Total Size |
|----------|-------|------------|
| **Quantum Computing** | 2 | ~794 KB |
| **Computer Vision** | 15 | ~3.5 MB |
| **Robotics & Embodied AI** | 3 | ~680 KB |
| **Infrastructure & DevOps** | 2 | ~814 KB |
| **General Development** | 6 | ~190 KB |
| **Total Conversations** | **28** | **~5.8 MB** |

## Key File Purposes

### Root Documentation
- **README.md**: Entry point with overview, featured conversations, usage, and citation
- **QUICKSTART.md**: Fast onboarding for readers and contributors (5-min guide)
- **INDEX.md**: Searchable catalog with summaries, topics, and metadata for all conversations
- **CONTRIBUTING.md**: Detailed contribution guidelines, privacy checklist, submission process
- **STRUCTURE.md**: This file - complete repository organization reference
- **LICENSE**: MIT License for open sharing

### Configuration
- **.gitignore**: Prevents committing sensitive files (secrets, credentials, drafts)
- **.github/ISSUE_TEMPLATE/conversation-submission.md**: Standardized issue template for submissions

### Templates (templates/)
Reusable markdown templates for different conversation types:
- **basic-conversation.md**: General-purpose conversation format
- **debugging-session.md**: Structured debugging workflow (problem → investigation → solution)
- **deployment-walkthrough.md**: End-to-end deployment process
- **README.md**: Template usage instructions

### Metadata (metadata/)
- **schema.yaml**: Complete specification of metadata fields, types, and examples

### Conversations (conversations/)
Organized by domain for easy navigation:
- **quantum-computing/**: Quantum algorithms, QPU access, error correction
- **computer-vision/**: Detection, segmentation, 3D reconstruction, medical imaging
- **robotics-embodied-ai/**: Humanoid control, world models, Physical AI
- **infrastructure-devops/**: Clusters, SLURM, deployment, containerization
- **general-development/**: Tools, workflows, debugging, integrations

## Navigation Tips

### By Use Case
- **Learning agentic patterns**: Start with README → QUICKSTART → Browse conversations/
- **Contributing**: CONTRIBUTING.md → templates/ → Submit PR
- **Finding specific topics**: INDEX.md → Search by topic/technology/hardware
- **Understanding structure**: This file (STRUCTURE.md)

### By Domain Expertise
- **Quantum Researchers**: conversations/quantum-computing/
- **Computer Vision Engineers**: conversations/computer-vision/
- **Robotics Engineers**: conversations/robotics-embodied-ai/
- **DevOps/MLOps**: conversations/infrastructure-devops/
- **Tool Builders**: All categories for agentic patterns

### By Tool/Framework
Use INDEX.md search (Ctrl+F / Cmd+F):
- Search "PyTorch" → Training, debugging, optimization conversations
- Search "CUDA-Q" → Quantum computing conversations
- Search "Isaac Sim" → Robotics simulation conversations
- Search "SLURM" → Cluster infrastructure conversations
- Search "Docker" → Deployment and containerization conversations

## File Naming Conventions

### Existing Files
Current files use various naming styles:
- **Descriptive titles**: "3D Endoscopy Pipeline Setup.md"
- **Tool-prefixed**: "cursor_repo_understanding.md"
- **Action-focused**: "Deploy GR00T SO-101 Model.md"

### Recommended for New Files
Use descriptive, kebab-case names:
- ✅ `debug-cuda-memory-error.md`
- ✅ `deploy-fastapi-model-server.md`
- ✅ `optimize-transformer-training.md`

## Metadata Standards

Every conversation should include YAML frontmatter:

```yaml
---
title: "Conversation Title"
date: YYYY-MM-DD
author: github-username
tools: [Cursor, Claude Sonnet 4.5]
topics: [topic1, topic2, topic3]
technologies: [Framework, Library]
hardware: [GPU, Cluster]
outcome: success | partial | blocked | learning
key_insights:
  - "Key insight 1"
  - "Key insight 2"
---
```

See `metadata/schema.yaml` for complete field definitions.

## Growth & Evolution

### Adding New Categories
If conversations don't fit existing categories:
1. Propose new category in pull request
2. Create `conversations/new-category/` directory
3. Update this STRUCTURE.md file
4. Add section to INDEX.md

### Potential Future Categories
- `machine-learning/` (general ML beyond CV/quantum)
- `data-engineering/` (pipelines, ETL, data quality)
- `security/` (security audits, vulnerability fixes)
- `testing/` (test generation, CI/CD, QA)
- `research/` (paper implementations, experiments)

## Maintenance

### Regular Updates
- **INDEX.md**: Add entries for new conversations
- **STRUCTURE.md**: Update file counts and structure
- **README.md**: Feature particularly valuable conversations

### Quality Control
- Remove duplicate files (marked with "(1)" suffix)
- Ensure all conversations have proper metadata
- Verify no sensitive information in commits
- Keep templates up-to-date with best practices

## Statistics

- **Total Conversations**: 28 (some duplicates to deduplicate)
- **Total Size**: ~5.8 MB of transcripts
- **Domains**: 5 (Quantum, Vision, Robotics, Infrastructure, General)
- **Average Size**: ~207 KB per conversation
- **Largest**: Fixing SLURM Conda Activation (755 KB)
- **Primary Tools**: Cursor IDE, Cascade, Devin, Claude Sonnet 4.5, Pieces LTM

## Related Repositories

This repository is part of Ryukijano's broader ecosystem:
- **Quantum-Buddies/Conditional_GQE**: GIC 2026 competition (H-cGQE with RL)
- **cosmos-framework**: NVIDIA Cosmos integration for world models
- **syndrome-net**: Quantum error correction with neural networks
- **DreamDojo**: Physical AI simulation and training
- **GR00T-WholeBodyControl**: Humanoid whole-body control
- **Ising / Ising-Decoding**: Quantum Ising model decoding

---

_Last updated: 2026-07-25_
