---
name: plugin-meister
description: "Installs, removes, updates, enables, and disables Claude Code plugins and marketplaces, and keeps the chezmoi run script that declares them in step, so the next chezmoi apply neither brings back a removed plugin nor loses an added one. Use when the user asks to install, add, remove, uninstall, update, enable, or disable a Claude Code plugin, add or remove a plugin marketplace, or asks which plugins are installed or declared in the dotfiles. Not for building or packaging plugins. Use plugin-forge for that."
---

# Plugin Meister

On a chezmoi-managed machine, Claude Code plugins have two sources of truth:

- **Live state:** what `claude plugin list --json` and `claude plugin marketplace list --json` report.
- **Declared state:** a chezmoi run script with `marketplaces=(owner/repo …)` and `plugins=(name@marketplace …)` arrays. Whenever `chezmoi apply` reruns it (`chezmoi update` runs `apply` too), it adds every marketplace and installs every plugin. It never uninstalls anything.

Every change updates both. The `claude plugin` command changes this machine now. The script change reaches the other machines on their next `chezmoi update`.

## Find the script

Run these as two separate commands. `SOURCE_PATH` stands for the output of the first one.

```sh
chezmoi source-path
grep -rl --include='run_*' --exclude-dir=.git 'claude plugin install' SOURCE_PATH
```

- **One match:** this is the script. Read its two arrays.
- **No chezmoi, or no match:** run only the `claude plugin` commands, and tell the user that nothing declares plugins on this machine.

## What the script owns

| Entry | Owner | What to do |
|---|---|---|
| `name@marketplace` at user scope, listed in `plugins` | the script | keep in step |
| `name@marketplace` at user scope, not listed in `plugins` | the user, on purpose (often a trial) | leave alone, and mention only in a status table |
| `*@skills-dir` | skills tooling (symlinks in `~/.claude/skills`) | leave alone |
| built-in marketplaces `claude-plugins-official` and `anthropic-plugin-directory` | Claude Code | never add to `marketplaces` |
| `--scope project` or `--scope local` | the project's `.claude/settings*.json` | run the command only |

## Operations

For flags, run `claude plugin <command> --help`.

### Status

Show a table of user-scope plugins, skipping `*@skills-dir`, with these columns: id, version, enabled, declared. Call out only two things:

- a plugin that is declared but not installed
- a marketplace that is declared but not configured

The next `chezmoi apply` installs or adds them. An undeclared plugin gets "no" in the declared column and no comment. The status table is the whole answer. The Report section applies to changes only.

### Install or add

1. **Find the marketplace.** `claude plugin marketplace list --json` maps each `name` to its `repo`. If the marketplace isn't configured, run `claude plugin marketplace add owner/repo`, then read its `name` from `marketplace list --json` again. The plugin id uses that `name`, which can differ from the repo name.
2. **Install:** `claude plugin install name@marketplace`.
3. **Declare it.** Append the id to `plugins`. Append `owner/repo` to `marketplaces` unless the marketplace is built in or already listed.

If the user frames it as a trial ("try", "test", "for a bit", "just on this machine"), skip step 3 and say that it is not declared.

Before you add a marketplace to `marketplaces`, check that the dotfiles can publish it. Run `gh repo view owner/repo --json visibility`, and run `gh repo view` on the URL from `git -C SOURCE_PATH remote get-url origin`. If the dotfiles repo is public and the marketplace is private, internal, or not on GitHub, ask before you declare it. Never put `--config` values or secrets in the script.

### Remove or uninstall

1. Remove the plugin's line from `plugins` first. Otherwise the next `chezmoi apply` reinstalls it.
2. Run `claude plugin uninstall name@marketplace`.
3. If the marketplace isn't built in, and no plugin left in `claude plugin list --json` or in `plugins` comes from it, remove its `owner/repo` line from `marketplaces`. Then run `claude plugin marketplace remove name`, using the `name` that `marketplace list --json` gives for that repo.

The script never uninstalls, so other machines keep the plugin until someone runs the same uninstall there. Say this in the report.

### Disable or enable

`claude plugin disable` and `claude plugin enable` change this machine's settings only. The script doesn't record whether a plugin is enabled, and `claude plugin install` re-enables a disabled plugin. For a plugin the script declares:

- **Temporary** ("for now", "for a while"): disable it, leave the script alone, and tell the user that the next `chezmoi apply` enables it again.
- **Off on every machine:** that is a removal. Ask whether to take it out of the script and uninstall it.

### Update

Run `claude plugin marketplace update [name]`, then `claude plugin update name@marketplace`. The script doesn't change.

## Editing the script

- Edit the file in the source directory directly. `chezmoi edit` can commit on its own when `autoCommit` is set.
- One entry per line, with the array's existing indentation, appended at the end.
- Change only the two arrays. Leave the rest of the script as it is.
- Leave the change uncommitted. Show `git -C SOURCE_PATH diff` and stop there. Don't commit or push it, because the user reviews it first.
- Don't run `chezmoi apply` or `chezmoi update`. The `claude plugin` commands have already changed this machine, and the script can run other updates, such as `claude update`.
- Don't edit `~/.claude/settings.json` by hand. The `claude plugin` commands manage it.

## Report

After a change, end with these four parts:

1. The `claude plugin` commands you ran, and their results.
2. The script diff, marked as uncommitted.
3. What the next `chezmoi apply` changes, here and on other machines. For example, it re-enables a declared plugin you disabled, and a removed plugin stays on other machines.
4. The line "Restart Claude Code sessions to load the change."

## Common mistakes

| Mistake | Result |
|---|---|
| Uninstalling without removing the declaration | The plugin comes back on the next `chezmoi apply` |
| Removing the declaration for a temporary disable | New machines stop getting it, and nothing brings it back |
| Adding `claude-plugins-official` to `marketplaces` | A redundant entry, because it is built in |
| Committing or pushing the script change | The user loses the review step |
| Bringing up undeclared plugins unasked | Noise, because they are often trials |
| Touching `*@skills-dir` entries | They are skills, and the skills tooling manages them |
