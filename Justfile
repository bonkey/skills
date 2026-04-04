# Update all skill references
update-all: update-skills-manual update-claude-plugin-creator update-done

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

# Fetch latest Claude plugin docs for claude-plugin-creator
update-claude-plugin-creator:
    mkdir -p skills/claude-plugin-creator/references
    curl -sL "https://code.claude.com/docs/en/plugins.md" -o skills/claude-plugin-creator/references/create-plugins.md
    curl -sL "https://code.claude.com/docs/en/plugins-reference.md" -o skills/claude-plugin-creator/references/plugins-reference-raw.md
    curl -sL "https://code.claude.com/docs/en/plugin-marketplaces.md" -o skills/claude-plugin-creator/references/plugin-marketplaces.md
