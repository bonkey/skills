# Skills

Private skill collection for AI coding agents.

## Install All

```sh
npx skills add bonkey/skills -g --all
```

## Skills

### decision-log

Lightweight ADR decision log that auto-captures plans. Includes a Claude Code hook (`PostToolUse` on `ExitPlanMode`) that prompts the agent to write a concise decision record after every plan approval. Cross-CLI via AGENTS.md fallback.

```sh
npx skills add bonkey/skills -g --skill decision-log -y
```

### skills-manual

Guidelines for creating well-structured AI agent skills. Includes Anthropic's official skill builder guide as reference.

```sh
npx skills add bonkey/skills -g --skill skills-manual -y
```

### done

Check if a PR already exists; if it does, update the PR. If no PR exists, merge current branch locally into main and push to main remote.

```sh
npx skills add bonkey/skills -g --skill done -y
```

### claude-plugin-creator

Create Claude Code plugins, skills, commands, agents, hooks, MCP servers, and marketplace files. Includes decision guide for choosing between plugin vs skill vs MCP vs standalone.

```sh
npx skills add bonkey/skills -g --skill claude-plugin-creator -y
```

### pr

Create, update, and manage pull requests with auto-generated descriptions from git diffs. Supports full PR lifecycle: create, update, close, merge, reviewers, labels, and CI checks.

```sh
npx skills add bonkey/skills -g --skill pr -y
```

### pr-comment-triage

Reviews all comments on the current pull request, evaluates whether each one still needs action, addresses or resolves each thread, and leaves a short explanation reply on every thread it resolves.

```sh
npx skills add bonkey/skills -g --skill pr-comment-triage -y
```

### seamless-rebase

Rebases the current branch onto the repository's default branch (detected from git), resolving conflicts carefully and conservatively. Resumes an in-progress rebase instead of starting a new one, and asks the user whenever the correct resolution is unclear.

```sh
npx skills add bonkey/skills -g --skill seamless-rebase -y
```

### exec-summary

Summarize the last substantive assistant message in plain language for decision-making: concise but not too short, bottom line up front, important details only, trade-offs, and practical options without ornaments.

```sh
npx skills add bonkey/skills -g --skill exec-summary -y
```
