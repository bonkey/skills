---
name: decision-log
description: "Lightweight ADR decision log that auto-captures plans. Use when planning a new feature, proposing architecture changes, tracking implementation decisions, exiting plan mode, or asking 'should I write a decision log'. Includes a Claude Code hook for automatic capture on ExitPlanMode."
---

# Decision Log

Capture architectural and feature decisions as lightweight ADR files. Automatically triggered when exiting plan mode; manually triggered for significant decisions outside plan mode.

## Setup (run once per project)

### 1. Create the decision log directory

Scan the repo for common documentation folders (`docs/`, `doc/`, `documentation/`). Use the first match as `{docs}`. If none exist, default to `docs`. Then:

```bash
mkdir -p {docs}/decisions
```

### 2. Register in project agent instructions

Add to the project's `AGENTS.md`, `CLAUDE.md`, or `GEMINI.md` (whichever exists, prefer `AGENTS.md`):

```markdown
## Decision Log

Decision log directory: ./{docs}/decisions/

When exiting plan mode, create a decision record in the decisions directory. If a non-trivial decision is made outside plan mode (choosing between approaches, introducing a pattern, reversing a prior decision), create one too. Use the format: `YYYY-MM-DD-{slug}.md` with YAML frontmatter containing `title`, `id` (YYYY-MM-DD-animal), `date`, `areas`, `references` (IDs of related records), and `tldr`. Never modify existing records — create a new one that references the old. Keep entries concise — a decision record is a signpost, not a specification.
```

### 3. Install the Claude Code hook (Claude Code only)

Add to the project's `.claude/settings.json` (create if needed):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "ExitPlanMode",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/decision-log-capture.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

Create the hook script at `.claude/hooks/decision-log-capture.sh`:

```bash
#!/usr/bin/env bash
# Injects a reminder to create a decision log entry after exiting plan mode.
# The agent receives this as additionalContext and writes the ADR file itself.

cat <<'HOOK_JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "DECISION LOG: You just exited plan mode. Create a decision log entry now. Find the decisions directory from AGENTS.md/CLAUDE.md. Check existing IDs (grep '^id:' *.md) and pick an unused animal name. Write YYYY-MM-DD-{slug}.md with frontmatter: title, id (YYYY-MM-DD-animal), date, areas, references (IDs of related records or []), tldr. Four sections: Context, Decision, Alternatives Considered, Consequences. For Alternatives: only list what was actually discussed — if nothing, write 'No other approaches were evaluated'. Never modify existing records. Under 50 lines. Skip if trivial."
  }
}
HOOK_JSON
```

Make it executable: `chmod +x .claude/hooks/decision-log-capture.sh`

For other AI CLIs (Gemini CLI, Cursor, etc.): add equivalent post-plan instructions to the agent config. The AGENTS.md entry is the cross-CLI fallback.

## Decision Record Format

Filename: `YYYY-MM-DD-{slug}.md` where `{slug}` is a short kebab-case summary.

### ID assignment

Each record gets an `id` in frontmatter: `YYYY-MM-DD-{animal}` (e.g., `2025-03-15-falcon`). The date is the record's creation date; the animal is a short (≤8 char) memorable name. To assign:

1. List existing IDs in the decisions directory (`grep -h '^id:' *.md`)
2. Pick an animal name not already used on that date
3. If the obvious name collides, pick another animal — don't append numbers

The ID doubles as a human-friendly reference in conversation and in `references` frontmatter of other records.

### Template

```markdown
---
title: Short decision title
id: 2025-03-15-falcon
date: 2025-03-15
areas: [auth, database, ui]
references: []  # IDs of related prior decisions, e.g. [2025-03-10-otter, 2025-02-28-hawk]
tldr: One sentence — what changed and why.
---

## Context

What's the situation? 1-3 sentences. Reference prior decisions by ID if relevant.

## Decision

What was done? Be specific — name files, types, patterns. 2-5 sentences.

## Alternatives Considered

What else was on the table and why it was rejected? If nothing else was considered, write "No other approaches were evaluated" — do not invent alternatives after the fact.

## Consequences

What follows from this decision? Trade-offs, migration needs, things that become easier or harder. 2-4 bullet points.
```

### Guidelines

- **Concise over complete** — a decision record is a signpost, not a design doc. If someone needs detail, they read the code or the PR.
- **Frontmatter is for machines** — `tldr`, `areas`, `id`, and `references` let agents scan and traverse decisions without reading bodies.
- **One decision per file** — don't bundle unrelated choices.
- **No fabricated alternatives** — only document alternatives that were actually discussed or evaluated. "No other approaches were evaluated" is a valid and preferred answer over made-up options.
- **Never modify existing records** — if a decision changes, create a new record that references the old one. The old record stays as-is. History is append-only.
- **Skip trivial changes** — typo fixes, single-file renames, and dependency bumps don't need a record.

## When to Create a Decision Record

| Trigger | Action |
|---------|--------|
| Exiting plan mode (auto via hook) | Create record from the plan |
| Choosing between approaches | Create record explaining the choice |
| Introducing a new pattern or convention | Create record for future reference |
| Reversing or replacing a prior decision | Create new record referencing the old one by ID |
| Plan changes significantly during implementation | Create new record referencing the original plan's ID |
| Someone asks "why did we do X?" | If no record exists, create one retroactively |

## Before Making Changes

1. Check the decisions directory for existing records related to your task
2. Read related records to understand context, constraints, and prior decisions
3. Reference prior decisions by ID in your new record's `references` frontmatter field
