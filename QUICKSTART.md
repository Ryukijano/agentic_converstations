# Quick Start Guide

Get up and running with the Agentic Conversations repository in 5 minutes.

## For Readers (Exploring Conversations)

### 1. Browse by Category
Navigate to `conversations/` and pick a domain:
```
conversations/
├── quantum-computing/        # Quantum algorithms, QPU, error correction
├── computer-vision/          # Detection, 3D reconstruction, medical imaging
├── robotics-embodied-ai/     # Robot control, world models, humanoids
├── infrastructure-devops/    # Clusters, deployment, SLURM, Docker
└── general-development/      # Tools, debugging, workflows
```

### 2. Find Specific Topics
Check [INDEX.md](INDEX.md) for a searchable catalog with:
- Conversation summaries
- Technology tags
- Outcome status
- File sizes

**Search tips**:
- Use browser find (Ctrl+F / Cmd+F) in INDEX.md
- Search for hardware: "A100", "DGX", "Jetson"
- Search for frameworks: "PyTorch", "CUDA-Q", "Isaac Sim"
- Search for tasks: "debugging", "deployment", "training"

### 3. Read a Conversation
Each markdown file follows this format:
```markdown
---
title: Conversation Title
topics: [debugging, pytorch]
outcome: success
---

# Tool Chat Conversation

### User Input
[User query]

### Agent Response
[Agent analysis and actions]
```

### 4. Learn Patterns
Look for:
- **Effective prompts**: How users frame problems for agents
- **Agent reasoning**: How agents break down complex tasks
- **Tool usage**: When agents read files, run commands, edit code
- **Iteration**: How solutions are refined through conversation
- **Error recovery**: How agents handle failures and pivot

---

## For Contributors (Adding Conversations)

### 1. Export Your Conversation
From Cursor/Cascade/Devin:
- Export chat as markdown
- Or copy/paste conversation with formatting

### 2. Use a Template
```bash
cd agentic_converstations
cp templates/basic-conversation.md conversations/category/my-topic.md
```

Templates available:
- `basic-conversation.md` - Standard format
- `debugging-session.md` - Structured debugging
- `deployment-walkthrough.md` - Deployment flows

### 3. Add Metadata
Fill the YAML frontmatter:
```yaml
---
title: "Debug CUDA Memory Error"
date: 2026-07-25
tools: [Cursor, Claude Sonnet 4.5]
topics: [debugging, pytorch, cuda]
technologies: [PyTorch, CUDA]
hardware: [A100]
outcome: success
key_insights:
  - "Use gradient checkpointing for memory-constrained training"
---
```

### 4. Privacy Check
**Remove before submitting**:
- ❌ API keys, tokens, passwords
- ❌ Private repository URLs
- ❌ Personal contact info
- ❌ Internal infrastructure details
- ❌ Unpublished research data

See full checklist in [CONTRIBUTING.md](CONTRIBUTING.md).

### 5. Add to Index
Update [INDEX.md](INDEX.md) with an entry:
```markdown
### Your Conversation Title
- **File**: `conversations/category/your-file.md`
- **Topics**: Debugging, PyTorch, CUDA
- **Outcome**: Success
- **Summary**: One-sentence description of the conversation.
```

### 6. Submit Pull Request
```bash
git checkout -b add-conversation-topic
git add conversations/category/your-file.md INDEX.md
git commit -m "Add conversation: Your Topic"
git push origin add-conversation-topic
```

Then open PR on GitHub.

---

## Common Use Cases

### Research & Learning
- Study how agents solve complex problems
- Learn effective prompt engineering
- Understand multi-step reasoning patterns
- See real debugging workflows

### Building Agent Tools
- Analyze conversation patterns for UX design
- Study context management strategies
- Learn from agent failure modes
- Design better tool integrations

### Training & Fine-tuning
- Curate high-quality agent interaction data
- Build domain-specific agent training sets
- Analyze agent reasoning chains
- Create evaluation benchmarks

### Documentation & Teaching
- Show real-world agent capabilities
- Demonstrate problem-solving workflows
- Create tutorials with actual examples
- Share debugging war stories

---

## Key Files

| File | Purpose |
|------|---------|
| `README.md` | Repository overview and context |
| `INDEX.md` | Searchable catalog of all conversations |
| `CONTRIBUTING.md` | Detailed contribution guidelines |
| `QUICKSTART.md` | This file - 5-minute guide |
| `templates/` | Conversation export templates |
| `metadata/schema.yaml` | Metadata field definitions |
| `conversations/` | All conversation transcripts |

---

## Example Workflow: Adding a Debugging Conversation

```bash
# 1. Clone repository (first time only)
git clone https://github.com/Ryukijano/agentic_converstations.git
cd agentic_converstations

# 2. Create branch
git checkout -b add-cuda-debug

# 3. Copy template
cp templates/debugging-session.md \
   conversations/infrastructure/debug-cuda-oom.md

# 4. Edit file, add your conversation
nano conversations/infrastructure/debug-cuda-oom.md

# 5. Add metadata and verify no secrets
# (Check CONTRIBUTING.md privacy checklist)

# 6. Update INDEX.md
nano INDEX.md
# Add entry under "Infrastructure & DevOps" section

# 7. Commit and push
git add conversations/infrastructure/debug-cuda-oom.md INDEX.md
git commit -m "Add conversation: Debug CUDA OOM in Multi-GPU Training"
git push origin add-cuda-debug

# 8. Open pull request on GitHub
```

---

## Questions?

- **General**: Read [README.md](README.md)
- **Contributing**: See [CONTRIBUTING.md](CONTRIBUTING.md)
- **Metadata**: Check [metadata/schema.yaml](metadata/schema.yaml)
- **Templates**: Browse [templates/](templates/)
- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions

---

## What's Next?

### Explore
- Browse [conversations/](conversations/) folders
- Read [INDEX.md](INDEX.md) for summaries
- Find conversations matching your interests

### Contribute
- Export your own agentic conversations
- Follow the [CONTRIBUTING.md](CONTRIBUTING.md) guide
- Submit a pull request

### Share
- Star the repository
- Share conversations on social media
- Reference in blog posts or papers
- Cite using the BibTeX in README

---

**Happy exploring! 🚀**
