---
name: decision-log
description: "Design log methodology for significant features and architectural changes. Use when planning a new feature, proposing architecture changes, tracking implementation decisions, or asking 'should I write a design log'."
---

# Decision Log

Maintain structured design logs for significant features and architectural changes.

## Setup

The repository must define the decision log directory (e.g., in `AGENTS.md`, `CLAUDE.md`, or equivalent):

```
Decision log directory: ./{docs}/decision-log/
```

If the directory is not configured, suggest a default path by scanning the repo for common documentation folders (`docs/`, `doc/`, `documentation/`). Use the first match as `{docs}`. If none exist, default to `docs`. Then ask the user to confirm before proceeding.

## Before Making Changes

1. Check the decision log directory for existing designs related to your task
2. Read related logs to understand context, constraints, and prior decisions
3. For new features or architectural changes: create a design log first, get approval, then implement

## Creating a Design Log

Structure each log with these sections in order:

1. **Background** — what exists today and why this matters
2. **Problem** — what's wrong or missing, with concrete symptoms
3. **Open Questions** — anything unclear or needing input; keep questions in place when answered, append the answer below each
4. **Design** — the proposed solution with file paths, type signatures, validation rules
5. **Implementation Plan** — ordered phases with deliverables per phase
6. **Examples** — realistic code showing correct and incorrect usage (mark with GOOD/BAD)
7. **Trade-offs** — what you're gaining, what you're giving up, and why it's worth it

Guidelines:
- Be brief — short explanations, only what's most relevant
- Be specific — include file paths, type signatures, validation rules
- Explain why, not just what
- Use mermaid diagrams when they clarify flow or architecture

## During Implementation

1. Follow the implementation plan phases from the design log
2. Write or update tests first to match the new behavior
3. Do not modify the original design sections once implementation starts
4. Append an **Implementation Notes** section as you go, documenting:
   - Deviations from design and why
   - Test results (X/Y passing)
5. After completing implementation, append a **Summary** section listing deviations from the original design

## Referencing Logs

When answering questions or making decisions, reference design logs by number (e.g., "See Design Log #12") so context is traceable.
