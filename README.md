# Skills

Private skill collection for AI coding agents.

## Install All

```sh
npx skills add bonkey/skills -g --all
```

## Skills

### [captains-log](skills/captains-log/SKILL.md)

Lightweight ADR decision log — a captain's log for the codebase — that auto-captures plans. Includes a Claude Code hook (`PostToolUse` on `ExitPlanMode`) that prompts the agent to write a concise decision record after every plan approval. Cross-CLI via AGENTS.md fallback.

```sh
npx skills add bonkey/skills -g --skill captains-log -y
```

### [skills-manual](skills/skills-manual/SKILL.md)

Guidelines for creating well-structured AI agent skills. Includes Anthropic's official skill builder guide as reference.

```sh
npx skills add bonkey/skills -g --skill skills-manual -y
```

### [done](skills/done/SKILL.md)

Check if a PR already exists; if it does, update the PR. If no PR exists, merge current branch locally into main and push to main remote.

```sh
npx skills add bonkey/skills -g --skill done -y
```

### [plugin-forge](skills/plugin-forge/SKILL.md)

Create Claude Code plugins, skills, commands, agents, hooks, MCP servers, and marketplace files. Includes decision guide for choosing between plugin vs skill vs MCP vs standalone.

```sh
npx skills add bonkey/skills -g --skill plugin-forge -y
```

### [pr](skills/pr/SKILL.md)

Create, update, and manage pull requests with auto-generated descriptions from git diffs. Supports full PR lifecycle: create, update, close, merge, reviewers, labels, and CI checks.

```sh
npx skills add bonkey/skills -g --skill pr -y
```

### [pr-comment-triage](skills/pr-comment-triage/SKILL.md)

Reviews all comments on the current pull request, reading every page of the GitHub API results, evaluates whether each one still needs action, addresses or resolves each thread, and leaves a short explanation reply marked `🤖 Generated with Claude Code` on every thread it resolves. Treats remarks from AI review agents as unverified claims: it confirms each one in the code before changing a line, and rejects the ones the code contradicts. Ends each run with a linked list of the comments it posted.

```sh
npx skills add bonkey/skills -g --skill pr-comment-triage -y
```

### [pr-shepherd](skills/pr-shepherd/SKILL.md)

Carries the current pull request toward mergeable: reads what the base branch actually requires (required checks, approvals, thread resolution, linear history), works every unmet requirement to fixed, rejected, or reported-open, then arms a monitor and hands the watch back to the agent. Verifies AI-authored review remarks against the code instead of trusting them, and never widens the diff for a bot. Runs one pass per invocation and never merges unless the user says to.

```sh
npx skills add bonkey/skills -g --skill pr-shepherd -y
```

### [smooth-rebase](skills/smooth-rebase/SKILL.md)

Rebases the current branch onto the repository's default branch (detected from git), resolving conflicts carefully and conservatively. Resumes an in-progress rebase instead of starting a new one, and asks the user whenever the correct resolution is unclear.

```sh
npx skills add bonkey/skills -g --skill smooth-rebase -y
```

### [exec-summary](skills/exec-summary/SKILL.md)

Summarize the last substantive assistant message in plain language for decision-making: concise but not too short, bottom line up front, important details only, trade-offs, and practical options without ornaments.

```sh
npx skills add bonkey/skills -g --skill exec-summary -y
```

### [write-responsibly](skills/write-responsibly/SKILL.md)

Edit or draft prose that respects the reader's time. Cuts AI slop (hedge stacks, filler, inflated words, throat-clearing, em-dashes, semicolons) while keeping the writer's voice and register.

```sh
npx skills add bonkey/skills -g --skill write-responsibly -y
```

### [timeless-docs](skills/timeless-docs/SKILL.md)

Improve docs and comment prose so it describes the current state of the code directly — cutting history, transitions, absences, and trivial detail. Rewrites "previously / now / no longer / migrated from / instead of" phrasing into plain present-state statements while preserving every non-trivial fact. Runs in two modes: on the current changes (session edits, uncommitted work, or the branch diff) or on named files/folders.

```sh
npx skills add bonkey/skills -g --skill timeless-docs -y
```
