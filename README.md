# Skills

Private skill collection for AI coding agents.

## Install All

```sh
npx skills add bonkey/skills -g --all
```

## Skills

### decision-log

Design log methodology for significant features and architectural changes. Enforces structured flow: design first, approval, then implement with tracked deviations.

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
