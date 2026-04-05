---
name: done
description: "Check if a PR already exists; if it does, update the PR. If no PR exists, merge current branch locally into main and push to main remote."
---

# Done

Ship the current branch — either by updating an existing PR or merging locally to main.

## Workflow

### 0. Pre-flight — verify repo requirements

Find and read whichever convention/instruction files apply to this repo and harness (e.g. `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `.cursor/rules/*`, `.github/copilot-instructions.md`, `.clinerules`, etc. — follow any `@`-includes). Verify the branch satisfies the rules; fix or surface gaps before continuing.

### 1. Check for an existing PR

```bash
gh pr list --head "$(git branch --show-current)" --state open --json number,url --jq '.[0]'
```

- If a PR exists → go to **Step 2a** (update PR)
- If no PR exists → go to **Step 2b** (local merge)

### 2a. Update existing PR

Stage, commit, and push the current branch:

```bash
wt step push
```

Then post a comment on the PR summarizing the changes.

### 2b. Local merge to main

Merge the current branch into main using worktrunk:

```bash
wt merge --no-remove
```

Then push main to remote:

```bash
git push origin main
```

### 3. Confirm

Report what happened:
- **PR updated**: print the PR URL
- **Merged locally**: print the commit hash on main

## Reference

For `wt` command details, see `references/worktrunk.md`.
