# Conversation Templates

This directory contains templates for different types of agentic conversations. Use these as starting points when exporting and formatting your own conversations.

## Available Templates

### 1. Basic Conversation Template
**File**: `basic-conversation.md`

Use for: Simple, straightforward conversations with standard user-agent interaction patterns.

**Best for**:
- Quick troubleshooting sessions
- Code explanations or reviews
- Simple feature implementations
- General Q&A with code generation

---

### 2. Debugging Session Template
**File**: `debugging-session.md`

Use for: Structured debugging workflows with clear problem → investigation → solution flow.

**Best for**:
- Error diagnosis and resolution
- Performance debugging
- Infrastructure troubleshooting
- Memory leaks, race conditions, crashes
- Environment configuration issues

**Structure**:
1. Problem Statement
2. Investigation Phase (hypothesis testing)
3. Root Cause Analysis
4. Solution Implementation
5. Resolution & Verification

---

### 3. Deployment Walkthrough Template
**File**: `deployment-walkthrough.md`

Use for: End-to-end deployment conversations from planning to production.

**Best for**:
- Model deployments
- Infrastructure provisioning
- Container orchestration
- CI/CD pipeline setup
- Production migrations

**Structure**:
1. Deployment Goal
2. Planning & Requirements
3. Environment Setup
4. Deployment Execution
5. Verification & Monitoring

---

## How to Use Templates

### 1. Copy Template
```bash
cp templates/basic-conversation.md conversations/category/my-conversation.md
```

### 2. Fill Metadata
Update the YAML frontmatter at the top:
```yaml
---
title: "Your Descriptive Title"
date: 2026-07-25
tools: [Cursor, Claude]
topics: [debugging, pytorch]
outcome: success
---
```

### 3. Add Conversation Content
Replace placeholder sections with your actual conversation transcript.

### 4. Follow Export Format
Maintain the structure:
```markdown
### User Input
[user query]

### Agent Response
[agent analysis]

*[action taken]*
```

### 5. Review Privacy
Check that no sensitive information (API keys, credentials, PII) is included.

### 6. Submit
Follow steps in [CONTRIBUTING.md](../CONTRIBUTING.md) to submit your conversation.

---

## Metadata Reference

See [metadata/schema.yaml](../metadata/schema.yaml) for complete metadata field definitions.

### Required Fields
- `title`: Descriptive conversation title
- `tools`: List of agent tools used
- `topics`: High-level categorization tags (1-5 tags)
- `outcome`: success | partial | blocked | learning

### Recommended Fields
- `date`: Conversation date (YYYY-MM-DD)
- `technologies`: Specific frameworks/libraries
- `hardware`: Computing platforms
- `key_insights`: Main takeaways (bullet list)

### Optional Fields
- `author`: GitHub username
- `duration`: Approximate time spent
- `related_conversations`: Links to related transcripts
- `external_resources`: Documentation references

---

## Custom Templates

Need a template for a specific use case not covered here? You can:

1. **Create your own**: Base it on existing templates and follow the metadata schema
2. **Request one**: Open an issue on GitHub with your use case
3. **Submit yours**: If you create a useful template, contribute it back!

Common custom template ideas:
- Research paper implementation
- Dataset curation and processing
- Model training and hyperparameter tuning
- Code refactoring and optimization
- Documentation generation
- CI/CD troubleshooting
- Security audit and fixes

---

## Tips for Great Conversation Exports

### ✅ Do:
- Include full context (what you're trying to achieve)
- Show the agent's reasoning and decision-making
- Document actions taken (file edits, commands run)
- Include error messages and logs when debugging
- Show iteration and refinement
- Add a summary at the end

### ❌ Avoid:
- Excessive tangents or off-topic discussion
- Dumping raw code without context
- Missing critical steps in the workflow
- Including sensitive information
- Overly verbose repetition
- Conversations with minimal educational value

---

## Questions?

See [CONTRIBUTING.md](../CONTRIBUTING.md) or open an issue on GitHub.
