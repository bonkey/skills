# Agent Instructions

## Skill Naming

Follow the pattern set by existing skills (`pr`, `done`, `exec-summary`, `pr-shepherd`, `captains-log`, `smooth-rebase`, `timeless-docs`):

- Lowercase kebab-case, 1–3 words; folder name and frontmatter `name` must match
- Name the object or outcome, not the activity: `captains-log` not `log-decisions`, `timeless-docs` not `improve-docs`
- Prefix with the target domain when scoping a family: `pr`, `pr-comment-triage`, `pr-shepherd`
- Distinctive over generic: pick an evocative word that captures the skill's character (`timeless-docs`, `pr-shepherd`, `smooth-rebase`, `captains-log`), not a flat label (`docs-improver`, `pr-monitor`, `rebase-helper`). Avoid names that collide with well-known tools or services (e.g. `codex`)
- Must read naturally as a slash command (`/done`, `/pr`, `/exec-summary`)
- No filler words like `helper`, `tool`, `manager`, `skill`

## Skill Maintenance

When adding, updating, or removing a skill, always update:

1. `README.md` — keep the skill list accurate and up to date
2. `Justfile` — add a recipe to fetch/update any external resources the skill depends on (e.g., reference docs from URLs)

## Skill Structure

Skills live in `skills/<skill-name>/`. Each skill folder contains:

- `SKILL.md` — main skill file (required, exact case), with YAML frontmatter (`name`, `description`)
- `references/` — optional supporting docs
- `scripts/` — optional executable code
- `assets/` — optional templates, icons

See the [skills-manual](skills/skills-manual/SKILL.md) skill for full guidelines.

## Repo Maintenance vs Skill Content

Scripts that fetch or generate reference docs belong in the `Justfile`, not inside skill folders. Skill folders (`scripts/`, `references/`, `assets/`) should only contain content that the skill itself uses at runtime. Build/update tooling lives at the repo level.
