# Agent Instructions

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
