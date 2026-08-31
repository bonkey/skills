# Update all skill references
update-all: update-skills-manual update-plugin-forge update-done update-pr-comment-triage update-pr-shepherd update-smooth-rebase update-exec-summary update-timeless-docs

# Fetch latest Anthropic skill builder guide for skills-manual
update-skills-manual:
    curl -sL "https://gist.githubusercontent.com/joyrexus/ff71917b4fc0a2cbc84974212da34a4a/raw" -o skills/skills-manual/references/skill-builder-guide.md

# Regenerate worktrunk reference for done skill from CLI help
update-done:
    #!/usr/bin/env bash
    set -euo pipefail
    strip_ansi() { sed $'s/\x1b\[[0-9;]*m//g'; }
    {
        cat <<'HEADER'
    # Worktrunk (`wt`) Reference

    Git worktree management for parallel AI agent workflows.
    Docs: https://worktrunk.dev

    ---

    HEADER
        for cmd in merge "step" "step commit" "step push" switch list remove; do
            echo "## \`wt $cmd\`"
            echo
            echo '```'
            wt $cmd --help 2>&1 | strip_ansi
            echo '```'
            echo
            echo '---'
            echo
        done
    } > skills/done/references/worktrunk.md

# Fetch latest Claude plugin docs for plugin-forge
update-plugin-forge:
    mkdir -p skills/plugin-forge/references
    curl -sL "https://code.claude.com/docs/en/plugins.md" -o skills/plugin-forge/references/create-plugins.md
    curl -sL "https://code.claude.com/docs/en/plugins-reference.md" -o skills/plugin-forge/references/plugins-reference-raw.md
    curl -sL "https://code.claude.com/docs/en/plugin-marketplaces.md" -o skills/plugin-forge/references/plugin-marketplaces.md

# No external references required for pr-comment-triage; comment marker policy is in SKILL.md
update-pr-comment-triage:
    @true

# No external references required for pr-shepherd; it delegates to pr-comment-triage and smooth-rebase
update-pr-shepherd:
    @true

# No external references required for smooth-rebase
update-smooth-rebase:
    @true

update-exec-summary:
    @true

# No external references required for timeless-docs
update-timeless-docs:
    @true
