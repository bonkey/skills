# Update all skill references
update-all: update-skills-manual update-claude-plugin-creator

# Fetch latest Anthropic skill builder guide for skills-manual
update-skills-manual:
    curl -sL "https://gist.githubusercontent.com/joyrexus/ff71917b4fc0a2cbc84974212da34a4a/raw" -o skills/skills-manual/references/skill-builder-guide.md

# Fetch latest Claude plugin docs for claude-plugin-creator
update-claude-plugin-creator:
    mkdir -p skills/claude-plugin-creator/references
    curl -sL "https://code.claude.com/docs/en/plugins.md" -o skills/claude-plugin-creator/references/create-plugins.md
    curl -sL "https://code.claude.com/docs/en/plugins-reference.md" -o skills/claude-plugin-creator/references/plugins-reference-raw.md
    curl -sL "https://code.claude.com/docs/en/plugin-marketplaces.md" -o skills/claude-plugin-creator/references/plugin-marketplaces.md
