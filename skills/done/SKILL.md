---
name: done
description: "Check if a PR already exists; if it does, update the PR. If no PR exists, merge current branch locally into main and push to main remote. If main is protected, create a PR instead."
---

# Done

Ship the current branch — by updating an existing PR, merging locally to main, or creating a PR when main is protected.

## Workflow

### 0. Pre-flight — verify repo requirements

Find and read whichever convention/instruction files apply to this repo and harness (e.g. `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `.cursor/rules/*`, `.github/copilot-instructions.md`, `.clinerules`, etc. — follow any `@`-includes). Verify the branch satisfies the rules; fix or surface gaps before continuing.

### 1. Check for an existing PR

```bash
gh pr list --head "$(git branch --show-current)" --state open --json number,url --jq '.[0]'
```

- If a PR exists → go to **Step 2a** (update PR)
- If no PR exists → check if main is protected via:

  ```bash
  gh api repos/:owner/:repo/branches/main --jq '.protected'
  ```

  - **Main is protected** → go to **Step 2b** (create PR)
  - **Main is not protected** → go to **Step 2c** (local merge)

### 2a. Update existing PR

Stage, commit, and push the current branch:

```bash
wt step push
```

Then post a comment on the PR summarizing the changes.

### 2b. Create PR (main is protected)

Since main is protected, push the current branch and create a PR:

```bash
wt step push
```

Then create a PR:

```bash
gh pr create --fill
```

### 2c. Local merge to main

Merge the current branch into main using worktrunk:

```bash
wt merge
```

Then push main to remote:

```bash
git push origin main
```

### 3. Update related ticket

If a related ticket is known (Jira, Linear, GitHub issue, etc. — from branch name, commit messages, PR body, or conversation context), update its status to reflect the ship:

- **PR updated** → move ticket to "In Review" (or equivalent) if not already there
- **Merged to main** (via local merge or PR merge) → move ticket to "Done" / "Closed" / "Shipped"

If no ticket is obviously linked, skip this step — don't guess.

### 4. Confirm

Report what happened:

- **PR updated**: print the PR URL
- **Merged locally**: print the commit hash on main
- **PR created**: print the PR URL
- **Ticket updated**: print the ticket ID and new status (if applicable)

## Reference

For `wt` command details, see `references/worktrunk.md`.
