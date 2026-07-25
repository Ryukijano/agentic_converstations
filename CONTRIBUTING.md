# Contributing to Agentic Conversations

Thank you for your interest in contributing your agentic conversation transcripts! This guide will help you prepare and submit high-quality conversation exports.

## What Makes a Good Contribution?

### ✅ Include Conversations That:
- Demonstrate real problem-solving with AI agents
- Show interesting multi-step workflows or debugging sessions
- Cover technical depth (infrastructure, ML training, research)
- Illustrate effective human-agent collaboration patterns
- Document solutions to non-trivial problems
- Show agent reasoning, iteration, and tool usage

### ❌ Avoid Conversations That:
- Contain private/confidential information, API keys, credentials
- Are simple "explain this code" or basic Q&A
- Include proprietary code or unpublished research data
- Have minimal educational or reference value
- Are duplicates of existing conversations
- Contain personally identifiable information (PII)

## Export Format

### Standard Markdown Format

Conversations should be exported as markdown files following this structure:

```markdown
# [Tool Name] Chat Conversation

Note: _This is purely the output of the chat conversation and does not 
contain any raw data, codebase snippets, etc. used to generate the output._

### User Input
[User query/request]

### [Agent Role] Response
[Agent's analysis and response]

*[Action taken, e.g., "Edited relevant file", "Ran command"]*

### User Input
[Follow-up query]

### [Agent Role] Response
[Continued response]
...
```

### Example:

```markdown
# Cursor Chat Conversation

Note: _This is purely the output of the chat conversation and does not 
contain any raw data, codebase snippets, etc. used to generate the output._

### User Input
Debug the CUDA out of memory error in training.py

### Assistant Response
Let me analyze the memory usage in your training loop.

*Read file training.py*

I can see the issue - you're accumulating gradients without clearing them...

*Edited training.py*

### User Input
Now test it with batch size 32

### Assistant Response
*Ran command `python training.py --batch_size 32`*

Success! The training now runs without OOM errors. Memory usage is stable at 22GB.
```

## File Naming Convention

Use descriptive, kebab-case file names:
- ✅ `debug-cuda-memory-error.md`
- ✅ `deploy-model-to-production.md`
- ✅ `setup-slurm-multi-node-training.md`
- ❌ `conversation.md`
- ❌ `Chat 123.md`
- ❌ `debugging_stuff.md`

## Directory Organization

Place your conversation in the appropriate category folder:

```
conversations/
├── quantum-computing/       # Quantum algorithms, QPU access, quantum ML
├── computer-vision/         # Detection, segmentation, 3D reconstruction, video
├── robotics-embodied-ai/    # Robot control, simulation, world models
├── infrastructure-devops/   # Clusters, containers, CI/CD, deployment
├── general-development/     # Tools, workflows, debugging, integrations
└── [new-category]/          # Propose new categories as needed
```

If your conversation doesn't fit existing categories, propose a new one in your pull request.

## Metadata Requirements

Add a YAML frontmatter block at the top of your file (optional but recommended):

```yaml
---
title: "Debug CUDA Memory Error in Multi-GPU Training"
date: 2026-07-15
author: username
tools: [Cursor, Claude Sonnet 4.5]
topics: [debugging, pytorch, multi-gpu, memory-optimization]
technologies: [PyTorch, CUDA, DDP, NCCL]
hardware: [A100, DGX]
outcome: success
duration: 45 minutes
key_insights:
  - "Gradient accumulation needs explicit zero_grad()"
  - "Use gradient checkpointing for large models"
---

# Cursor Chat Conversation
...
```

### Metadata Fields

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `title` | Yes | Descriptive conversation title | "Deploy GR00T Model to Jetson" |
| `date` | No | Date of conversation (YYYY-MM-DD) | "2026-07-15" |
| `author` | No | GitHub username or handle | "Ryukijano" |
| `tools` | Yes | Agent tools used | ["Cursor", "Claude 4.5"] |
| `topics` | Yes | High-level topic tags | ["debugging", "deployment"] |
| `technologies` | No | Specific tech stack | ["PyTorch", "Docker", "FastAPI"] |
| `hardware` | No | Compute platforms | ["A100", "Jetson Orin"] |
| `outcome` | Yes | success \| partial \| blocked \| learning | "success" |
| `duration` | No | Approximate conversation length | "2 hours", "30 minutes" |
| `key_insights` | No | Main takeaways (bullet list) | See example above |

## Privacy & Security Checklist

Before submitting, review your conversation and **remove or redact**:

- [ ] API keys, tokens, passwords, secrets
- [ ] Private repository URLs or internal service endpoints
- [ ] Personal email addresses, phone numbers
- [ ] Company-internal hostnames, IPs, or infrastructure details
- [ ] Unpublished research data or proprietary algorithms
- [ ] Names of colleagues or collaborators (unless public)
- [ ] Database credentials or connection strings
- [ ] Private Slack/Discord/Teams conversations
- [ ] SSH keys or certificate contents

### Safe Redaction Example:

```markdown
# Before
ssh user@10.0.45.123 -i ~/.ssh/company_rsa

# After
ssh user@<server> -i ~/.ssh/<key>
```

## Submission Process

### 1. Fork & Clone
```bash
git clone https://github.com/YOUR_USERNAME/agentic_converstations.git
cd agentic_converstations
```

### 2. Create a Branch
```bash
git checkout -b add-conversation-topic-name
```

### 3. Add Your Conversation
- Place markdown file in appropriate `conversations/` subfolder
- Add metadata frontmatter
- Review privacy checklist

### 4. Update INDEX.md
Add an entry to [INDEX.md](INDEX.md) under the relevant section:

```markdown
### Your Conversation Title
- **File**: `conversations/category/your-conversation.md`
- **Size**: XX KB
- **Topics**: Topic1, Topic2, Topic3
- **Key Technologies**: Framework, Library, Platform
- **Outcome**: Success/Partial/Blocked/Learning
- **Summary**: One-sentence description of the conversation's focus and outcome.
```

### 5. Commit & Push
```bash
git add conversations/category/your-conversation.md INDEX.md
git commit -m "Add conversation: Your Conversation Title"
git push origin add-conversation-topic-name
```

### 6. Open Pull Request
- Go to https://github.com/Ryukijano/agentic_converstations
- Click "New Pull Request"
- Describe your conversation and why it's valuable
- Reference any related issues or projects

## Quality Standards

### Conversation Quality
- **Complete**: Shows full problem → solution arc (or blocked explanation)
- **Educational**: Others can learn from the workflow
- **Well-Formatted**: Proper markdown, readable structure
- **Contextual**: Enough context to understand the problem domain
- **Clean**: No excessive tangents or off-topic diversions

### Technical Quality
- **Accurate**: Commands, code, and explanations are correct
- **Reproducible**: Others could follow similar steps (when applicable)
- **Current**: Uses up-to-date libraries, APIs, best practices
- **Documented**: Key decisions and trade-offs are explained

## Templates

See [templates/](templates/) directory for:
- **Basic Conversation Template**: Minimal structure for simple conversations
- **Detailed Conversation Template**: Full metadata + multi-section format
- **Debugging Session Template**: Structured format for debugging workflows
- **Deployment Walkthrough Template**: Step-by-step deployment conversations

## Review Process

Maintainers will review submissions for:
1. **Privacy**: No sensitive information exposed
2. **Quality**: Meets educational/reference value bar
3. **Format**: Follows markdown and metadata conventions
4. **Uniqueness**: Not a duplicate of existing conversations
5. **Scope**: Fits the repository's focus on agentic workflows

Expect feedback within 1-2 weeks. We may request:
- Additional redactions for privacy
- Metadata improvements
- Formatting fixes
- Clarifications or context

## Code of Conduct

- Be respectful and professional
- Credit others' work when applicable
- Don't submit others' conversations without permission
- Follow open source norms (attribution, licensing)

## Questions?

- **Issues**: Open a [GitHub Issue](https://github.com/Ryukijano/agentic_converstations/issues)
- **Discussions**: Use [GitHub Discussions](https://github.com/Ryukijano/agentic_converstations/discussions)
- **Email**: Contact maintainer (see README)

## License

By contributing, you agree your conversations will be licensed under the [MIT License](LICENSE).

---

Thank you for helping build a valuable resource for the agentic AI community! 🚀
