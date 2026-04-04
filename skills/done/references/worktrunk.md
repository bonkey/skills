# Worktrunk (`wt`) Reference

Git worktree management for parallel AI agent workflows.
Docs: https://worktrunk.dev

---

## `wt merge`

```
wt merge - Merge current branch into target

Squash & rebase, fast-forward target, remove the worktree.

Usage: wt merge [OPTIONS] [TARGET]

Arguments:
  [TARGET]
          Target branch
          
          Defaults to default branch.

Options:
      --no-squash
          Skip commit squashing

      --no-commit
          Skip commit and squash

      --no-rebase
          Skip rebase (fail if not already rebased)

      --no-remove
          Keep worktree after merge

      --no-ff
          Create a merge commit (no fast-forward)

      --stage <STAGE>
          What to stage before committing [default: all]

          Possible values:
          - all:     Stage everything: untracked files + unstaged tracked changes
          - tracked: Stage tracked changes only (like git add -u)
          - none:    Stage nothing, commit only what's already in the index

  -h, --help
          Print help (see a summary with '-h')

Automation:
  -y, --yes
          Skip approval prompts

      --no-verify
          Skip hooks

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

Unlike git merge, this merges current into target (not target into current). Similar to clicking "Merge pull request" on 
GitHub, but locally. Target defaults to the default branch.

Examples

Merge to the default branch:

  wt merge

Merge to a different branch:

  wt merge develop

Keep the worktree after merging:

  wt merge --no-remove

Preserve commit history (no squash):

  wt merge --no-squash

Create a merge commit (semi-linear history):

  wt merge --no-ff

Skip committing/squashing (rebase still runs unless --no-rebase):

  wt merge --no-commit

Pipeline

wt merge runs these steps:

1. Commit — Pre-commit hooks run, then uncommitted changes are committed. Post-commit hooks run in background. With 
--no-squash, this is the only commit step; with squash (default), this is skipped and changes are staged during squash 
instead.
2. Squash — Combines all commits since target into one (like GitHub's "Squash and merge"). Use --stage to control what 
gets staged: all (default), tracked, or none. A backup ref is saved to refs/wt-backup/<branch>. With --no-squash, 
individual commits are preserved.
3. Rebase — Rebases onto target if behind. Skipped if already up-to-date. Conflicts abort immediately.
4. Pre-merge hooks — Hooks run after rebase, before merge. Failures abort. See wt hook.
5. Merge — Fast-forward merge to the target branch. With --no-ff, a merge commit is created instead (semi-linear history: 
rebased commits plus a merge commit). Non-fast-forward merges are rejected.
6. Pre-remove hooks — Hooks run before removing worktree. Failures abort.
7. Cleanup — Removes the worktree and branch. Use --no-remove to keep the worktree. When already on the target branch or 
in the primary worktree, the worktree is preserved.
8. Post-remove + post-merge hooks — Run in background after cleanup.

Use --no-commit to skip committing uncommitted changes and squashing; rebase still runs by default and can rewrite commits
 unless --no-rebase is passed. Useful after preparing commits manually with wt step. Requires a clean working tree.

Local CI

For personal projects, pre-merge hooks open up the possibility of a workflow with much faster iteration — an order of 
magnitude more small changes instead of fewer large ones.

Historically, ensuring tests ran before merging was difficult to enforce locally. Remote CI was valuable for the process 
as much as the checks: it guaranteed validation happened. wt merge brings that guarantee local.

The full workflow: start an agent (one of many) on a task, work elsewhere, return when it's ready. Review the diff, run wt
 merge, move on. Pre-merge hooks validate before merging — if they pass, the branch goes to the default branch and the 
worktree cleans up.

  [pre-merge]
  test = "cargo test"
  lint = "cargo clippy"

See also

- wt step — Run individual operations (commit, squash, rebase, push)
- wt remove — Remove worktrees without merging
- wt switch — Navigate to other worktrees
```

---

## `wt step`

```
wt step - Run individual operations

The building blocks of wt merge — commit, squash, rebase, push — plus standalone utilities.

Usage: wt step [OPTIONS] <COMMAND>

Commands:
  commit        Stage and commit with LLM-generated message
  squash        Squash commits since branching
  push          Fast-forward target to current branch
  rebase        Rebase onto target
  diff          Show all changes since branching
  copy-ignored  Copy gitignored files to another worktree
  eval          [experimental] Evaluate a template expression
  for-each      [experimental] Run command in each worktree
  promote       [experimental] Swap a branch into the main worktree
  prune         [experimental] Remove worktrees merged into the default branch
  relocate      [experimental] Move worktrees to expected paths

Options:
  -h, --help
          Print help (see a summary with '-h')

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

Examples

Commit with LLM-generated message:

  wt step commit

Manual merge workflow with review between steps:

  wt step commit
  wt step squash
  wt step rebase
  wt step push

Operations

- commit — Stage and commit with LLM-generated message
- squash — Squash all branch commits into one with LLM-generated message
- rebase — Rebase onto target branch
- push — Fast-forward target to current branch
- diff — Show all changes since branching (committed, staged, unstaged, untracked)
- copy-ignored — Copy gitignored files between worktrees
- eval — [experimental] Evaluate a template expression
- for-each — [experimental] Run a command in every worktree
- promote — [experimental] Swap a branch into the main worktree
- prune — Remove worktrees and branches merged into the default branch
- relocate — [experimental] Move worktrees to expected paths
- <alias> — [experimental] Run a configured command alias

See also

- wt merge — Runs commit → squash → rebase → hooks → push → cleanup automatically
- wt hook — Run configured hooks

Aliases [experimental]

Custom command templates configured in user config (~/.config/worktrunk/config.toml) or project config (.config/wt.toml). 
Aliases support the same template variables as hooks.

  # .config/wt.toml
  [aliases]
  deploy = "make deploy BRANCH={{ branch }}"
  port = "echo http://localhost:{{ branch | hash_port }}"

  wt step deploy                            # run the alias
  wt step deploy --dry-run                  # show expanded command
  wt step deploy --var env=staging          # pass extra template variables
  wt step deploy --yes                      # skip approval prompt

When defined in both user and project config, both run (user first, then project). Project-config aliases require command 
approval on first run (same as project hooks). User-config aliases are trusted.

Alias names that match a built-in step command (commit, squash, etc.) are shadowed by the built-in and will never run.
```

---

## `wt step commit`

```
wt step commit - Stage and commit with LLM-generated message

Usage: wt step commit [OPTIONS]

Options:
      --stage <STAGE>
          What to stage before committing [default: all]

          Possible values:
          - all:     Stage everything: untracked files + unstaged tracked changes
          - tracked: Stage tracked changes only (like git add -u)
          - none:    Stage nothing, commit only what's already in the index

      --show-prompt
          Show prompt without running LLM
          
          Outputs the rendered prompt to stdout for debugging or manual piping.

  -h, --help
          Print help (see a summary with '-h')

Automation:
  -y, --yes
          Skip approval prompts

      --no-verify
          Skip hooks

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

See LLM-generated commit messages for configuration and prompt customization.

Options

`--stage`

Controls what to stage before committing:

  Value                         Behavior                         
 ─────── ─────────────────────────────────────────────────────── 
 all     Stage all changes including untracked files (default)   
 tracked Stage only modified tracked files                       
 none    Don't stage anything, commit only what's already staged 

  wt step commit --stage=tracked

Configure the default in user config:

  [commit]
  stage = "tracked"

`--show-prompt`

Output the rendered LLM prompt to stdout without running the command. Useful for inspecting prompt templates or piping to 
other tools:

  # Inspect the rendered prompt
  wt step commit --show-prompt | less
  
  # Pipe to a different LLM
  wt step commit --show-prompt | llm -m gpt-5-nano
```

---

## `wt step push`

```
wt step push - Fast-forward target to current branch

Usage: wt step push [OPTIONS] [TARGET]

Arguments:
  [TARGET]
          Target branch
          
          Defaults to default branch.

Options:
      --no-ff
          Create a merge commit (no fast-forward)

  -h, --help
          Print help (see a summary with '-h')

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

Updates the local target branch (e.g., main) to include current commits.

Examples

  wt step push             # Fast-forward main to current branch
  wt step push develop     # Fast-forward develop instead

Similar to git push . HEAD:<target>, but uses receive.denyCurrentBranch=updateInstead internally.
```

---

## `wt switch`

```
wt switch - Switch to a worktree; create if needed

Usage: wt switch [OPTIONS] [BRANCH] [-- <EXECUTE_ARGS>...]

Arguments:
  [BRANCH]
          Branch name or shortcut
          
          Opens interactive picker if omitted. Shortcuts: '^' (default branch), '-' (previous), '@' (current), 'pr:{N}' 
          (GitHub PR), 'mr:{N}' (GitLab MR)

  [EXECUTE_ARGS]...
          Additional arguments for --execute command (after --)
          
          Arguments after -- are appended to the execute command. Each argument is expanded for templates, then POSIX 
          shell-escaped.

Options:
  -c, --create
          Create a new branch

  -b, --base <BASE>
          Base branch
          
          Defaults to default branch.

  -x, --execute <EXECUTE>
          Command to run after switch
          
          Replaces the wt process with the command after switching, giving it full terminal control. Useful for launching 
          editors, AI agents, or other interactive tools.
          
          Supports ]8;;@/hook.md#template-variables\hook template variables]8;;\ ({{ branch }}, {{ worktree_path }}, etc.) and filters. {{ base }} and {{ 
          base_worktree_path }} require --create.
          
          Especially useful with shell aliases:
          
            alias wsc='wt switch --create -x claude'
            wsc feature-branch -- 'Fix GH #322'
          
          Then wsc feature-branch creates the worktree and launches Claude Code. Arguments after -- are passed to the 
          command, so wsc feature -- 'Fix GH #322' runs claude 'Fix GH #322', starting Claude with a prompt.
          
          Template example: -x 'code {{ worktree_path }}' opens VS Code at the worktree, -x 'tmux new -s {{ branch | 
          sanitize }}' starts a tmux session named after the branch.

      --clobber
          Remove stale paths at target

      --no-cd
          Skip directory change after switching
          
          Hooks still run normally. Useful when hooks handle navigation (e.g., tmux workflows) or for CI/automation. Use 
          --cd to override.
          
          In picker mode (no branch argument), prints the selected branch name and exits without switching. Useful for 
          scripting.

  -h, --help
          Print help (see a summary with '-h')

Picker Options:
      --branches
          Include branches without worktrees

      --remotes
          Include remote branches

Automation:
  -y, --yes
          Skip approval prompts

      --no-verify
          Skip hooks

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

Worktrees are addressed by branch name; paths are computed from a configurable template. Unlike git switch, this navigates
 between worktrees rather than changing branches in place.

Examples

  wt switch feature-auth           # Switch to worktree
  wt switch -                      # Previous worktree (like cd -)
  wt switch --create new-feature   # Create new branch and worktree
  wt switch --create hotfix --base production
  wt switch pr:123                 # Switch to PR #123's branch

Creating a branch

The --create flag creates a new branch from the --base branch (defaults to default branch). Without --create, the branch 
must already exist. Switching to a remote branch (e.g., wt switch feature when only origin/feature exists) creates a local
 tracking branch.

Creating worktrees

If the branch already has a worktree, wt switch changes directories to it. Otherwise, it creates one, running hooks.

When creating a worktree, worktrunk:

1. Runs pre-switch hooks (blocking, fail-fast)
2. Creates worktree at configured path
3. Switches to new directory
4. Runs pre-start hooks (blocking)
5. Spawns post-start hooks (background)
6. Spawns post-switch hooks (background)

  wt switch feature                        # Existing branch → creates worktree
  wt switch --create feature               # New branch and worktree
  wt switch --create fix --base release    # New branch from release
  wt switch --create temp --no-verify      # Skip hooks

Shortcuts

 Shortcut            Meaning            
 ──────── ───────────────────────────── 
 ^        Default branch (main/master)  
 @        Current branch/worktree       
 -        Previous worktree (like cd -) 
 pr:{N}   GitHub PR #N's branch         
 mr:{N}   GitLab MR !N's branch         

  wt switch -                      # Back to previous
  wt switch ^                      # Default branch worktree
  wt switch --create fix --base=@  # Branch from current HEAD
  wt switch pr:123                 # PR #123's branch
  wt switch mr:101                 # MR !101's branch

Interactive picker

When called without arguments, wt switch opens an interactive picker to browse and select worktrees with live preview. The
 picker requires a TTY.

Keybindings:

      Key                  Action             
 ───────────── ────────────────────────────── 
 ↑/↓           Navigate worktree list         
 (type)        Filter worktrees               
 Enter         Switch to selected worktree    
 Alt-c         Create new worktree from query 
 Esc           Cancel                         
 1–5           Switch preview tab             
 Alt-p         Toggle preview panel           
 Ctrl-u/Ctrl-d Scroll preview up/down         

Preview tabs (toggle with number keys):

1. HEAD± — Diff of uncommitted changes
2. log — Recent commits; commits already on the default branch have dimmed hashes
3. main…± — Diff of changes since the merge-base with the default branch
4. remote⇅ — Diff vs upstream tracking branch (ahead/behind)
5. summary — LLM-generated branch summary (requires [list] summary = true and [commit.generation])

Pager configuration: The preview panel pipes diff output through git's pager. Override in user config:

  [switch.picker]
  pager = "delta --paging=never --width=$COLUMNS"

Available on Unix only (macOS, Linux). On Windows, use wt list or wt switch <branch> directly.

Pull requests and merge requests

The pr:<number> and mr:<number> shortcuts resolve a GitHub PR or GitLab MR to its branch. For same-repo PRs/MRs, worktrunk
 switches to the branch directly. For fork PRs/MRs, it fetches the ref (refs/pull/N/head or refs/merge-requests/N/head) 
and configures pushRemote to the fork URL.

  wt switch pr:101                 # GitHub PR #101
  wt switch mr:101                 # GitLab MR !101

Requires gh (GitHub) or glab (GitLab) CLI to be installed and authenticated. The --create flag cannot be used with pr:/mr:
 syntax since the branch already exists.

Forks: The local branch uses the PR/MR's branch name directly (e.g., feature-fix), so git push works normally. If a local 
branch with that name already exists tracking something else, rename it first.

When wt switch fails

- Branch doesn't exist — Use --create, or check wt list --branches
- Path occupied — Another worktree is at the target path; switch to it or remove it
- Stale directory — Use --clobber to remove a non-worktree directory at the target path

To change which branch a worktree is on, use git switch inside that worktree.

See also

- wt list — View all worktrees
- wt remove — Delete worktrees when done
- wt merge — Integrate changes back to the default branch
```

---

## `wt list`

```
wt list - List worktrees and their status

Usage: wt list [OPTIONS]
       wt list <COMMAND>

Commands:
  statusline  Single-line status for shell prompts

Options:
      --format <FORMAT>
          Output format (table, json)
          
          [default: table]

      --branches
          Include branches without worktrees

      --remotes
          Include remote branches

      --full
          Show CI, diff analysis, and LLM summaries

      --progressive
          Show fast info immediately, update with slow info
          
          Displays local data (branches, paths, status) first, then updates with remote data (CI, upstream) as it arrives.
           Use --no-progressive to force buffered rendering. Auto-enabled for TTY.

  -h, --help
          Print help (see a summary with '-h')

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

Shows uncommitted changes, divergence from the default branch and remote, and optional CI status and LLM summaries.

The table renders progressively: branch names, paths, and commit hashes appear immediately, then status, divergence, and 
other columns fill in as background git operations complete.

Full mode

--full adds columns that require network access or LLM calls: CI status (GitHub/GitLab pipeline pass/fail), line diffs 
since the merge-base, and LLM-generated summaries of each branch's changes. The table displays instantly and columns fill 
in as results arrive.

Examples

List all worktrees:

  $ wt list

Include CI status, line diffs, and LLM summaries:

  $ wt list --full

Include branches that don't have worktrees:

  $ wt list --branches --full

Output as JSON for scripting:

  $ wt list --format=json

Columns

 Column                                                Shows                                               
 ─────── ───────────────────────────────────────────────────────────────────────────────────────────────── 
 Branch  Branch name                                                                                       
 Status  Compact symbols (see below)                                                                       
 HEAD±   Uncommitted changes: +added -deleted lines                                                        
 main↕   Commits ahead/behind default branch                                                               
 main…±  Line diffs since the merge-base with the default branch (--full)                                  
 Summary LLM-generated branch summary (--full + summary = true, requires commit.generation) [experimental] 
 Remote⇅ Commits ahead/behind tracking branch                                                              
 CI      Pipeline status (--full)                                                                          
 Path    Worktree directory                                                                                
 URL     Dev server URL from project config (dimmed if port not listening)                                 
 Commit  Short hash (8 chars)                                                                              
 Age     Time since last commit                                                                            
 Message Last commit message (truncated)                                                                   

Note: main↕ and main…± refer to the default branch (header label stays main for compactness). main…± uses a merge-base 
(three-dot) diff.

CI status

The CI column shows GitHub/GitLab pipeline status:

 Indicator              Meaning              
 ───────── ───────────────────────────────── 
 ● green   All checks passed                 
 ● blue    Checks running                    
 ● red     Checks failed                     
 ● yellow  Merge conflicts with base         
 ● gray    No checks configured              
 ⚠ yellow  Fetch error (rate limit, network) 
 (blank)   No upstream or no PR/MR           

CI indicators are clickable links to the PR or pipeline page. Any CI dot appears dimmed when there are unpushed local 
changes (stale status). PRs/MRs are checked first, then branch workflows/pipelines for branches with an upstream. 
Local-only branches show blank; remote-only branches (visible with --remotes) get CI status detection. Results are cached 
for 30-60 seconds; use wt config state to view or clear.

LLM summaries [experimental]

Reuses the commit.generation command — the same LLM that generates commit messages. Enable with summary = true in [list] 
config; requires --full. Results are cached until the branch's diff changes.

Status symbols

The Status column has multiple subcolumns. Within each, only the first matching symbol is shown (listed in priority 
order):

    Subcolumn     Symbol                                          Meaning                                           
 ──────────────── ────── ────────────────────────────────────────────────────────────────────────────────────────── 
 Working tree (1) +      Staged files                                                                               
 Working tree (2) !      Modified files (unstaged)                                                                  
 Working tree (3) ?      Untracked files                                                                            
 Worktree         ✘      Merge conflicts                                                                            
                  ⤴      Rebase in progress                                                                         
                  ⤵      Merge in progress                                                                          
                  /      Branch without worktree                                                                    
                  ⚑      Branch-worktree mismatch (branch name doesn't match worktree path)                         
                  ⊟      Prunable (directory missing)                                                               
                  ⊞      Locked worktree                                                                            
 Default branch   ^      Is the default branch                                                                      
                  ∅      Orphan branch (no common ancestor with the default branch)                                 
                  ✗      Would conflict if merged to the default branch (with --full, includes uncommitted changes) 
                  _      Same commit as the default branch, clean                                                   
                  –      Same commit as the default branch, uncommitted changes                                     
                  ⊂      Content integrated into the default branch or target                                       
                  ↕      Diverged from the default branch                                                           
                  ↑      Ahead of the default branch                                                                
                  ↓      Behind the default branch                                                                  
 Remote           |      In sync with remote                                                                        
                  ⇅      Diverged from remote                                                                       
                  ⇡      Ahead of remote                                                                            
                  ⇣      Behind remote                                                                              

Rows are dimmed when safe to delete (_ same commit with clean working tree or ⊂ content integrated).

Placeholder symbols

These appear across all columns while the table is loading:

 Symbol                      Meaning                       
 ────── ────────────────────────────────────────────────── 
 ⋯      Data is loading                                    
 ·      Skipped — collection timed out or branch too stale 

──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

JSON output

Query structured data with --format=json:

  # Current worktree path (for scripts)
  wt list --format=json | jq -r '.[] | select(.is_current) | .path'
  
  # Branches with uncommitted changes
  wt list --format=json | jq '.[] | select(.working_tree.modified)'
  
  # Worktrees with merge conflicts
  wt list --format=json | jq '.[] | select(.operation_state == "conflicts")'
  
  # Branches ahead of main (needs merging)
  wt list --format=json | jq '.[] | select(.main.ahead > 0) | .branch'
  
  # Integrated branches (safe to remove)
  wt list --format=json | jq '.[] | select(.main_state == "integrated" or .main_state == "empty") | .branch'
  
  # Branches without worktrees
  wt list --format=json --branches | jq '.[] | select(.kind == "branch") | .branch'
  
  # Worktrees ahead of remote (needs pushing)
  wt list --format=json | jq '.[] | select(.remote.ahead > 0) | {branch, ahead: .remote.ahead}'
  
  # Stale CI (local changes not reflected in CI)
  wt list --format=json --full | jq '.[] | select(.ci.stale) | .branch'

Fields:

       Field           Type                                   Description                               
 ────────────────── ─────────── ─────────────────────────────────────────────────────────────────────── 
 branch             string/null Branch name (null for detached HEAD)                                    
 path               string      Worktree path (absent for branches without worktrees)                   
 kind               string      "worktree" or "branch"                                                  
 commit             object      Commit info (see below)                                                 
 working_tree       object      Working tree state (see below)                                          
 main_state         string      Relation to the default branch (see below)                              
 integration_reason string      Why branch is integrated (see below)                                    
 operation_state    string      "conflicts", "rebase", or "merge" (absent when clean)                   
 main               object      Relationship to the default branch (see below, absent when is_main)     
 remote             object      Tracking branch info (see below, absent when no tracking)               
 worktree           object      Worktree metadata (see below)                                           
 is_main            boolean     Is the main worktree                                                    
 is_current         boolean     Is the current worktree                                                 
 is_previous        boolean     Previous worktree from wt switch                                        
 ci                 object      CI status (see below, absent when no CI)                                
 url                string      Dev server URL from project config (absent when not configured)         
 url_active         boolean     Whether the URL's port is listening (absent when not configured)        
 summary            string      LLM-generated branch summary (absent when not configured or no summary) 
 statusline         string      Pre-formatted status with ANSI colors                                   
 symbols            string      Raw status symbols without colors (e.g., "!?↓")                         

Commit object

   Field    Type          Description         
 ───────── ────── ─────────────────────────── 
 sha       string Full commit SHA (40 chars)  
 short_sha string Short commit SHA (7 chars)  
 message   string Commit message (first line) 
 timestamp number Unix timestamp              

working_tree object

   Field    Type                 Description               
 ───────── ─────── ─────────────────────────────────────── 
 staged    boolean Has staged files                        
 modified  boolean Has modified files (unstaged)           
 untracked boolean Has untracked files                     
 renamed   boolean Has renamed files                       
 deleted   boolean Has deleted files                       
 diff      object  Lines changed vs HEAD: {added, deleted} 

main object

 Field   Type                       Description                      
 ────── ────── ───────────────────────────────────────────────────── 
 ahead  number Commits ahead of the default branch                   
 behind number Commits behind the default branch                     
 diff   object Lines changed vs the default branch: {added, deleted} 

remote object

 Field   Type          Description          
 ────── ────── ──────────────────────────── 
 name   string Remote name (e.g., "origin") 
 branch string Remote branch name           
 ahead  number Commits ahead of remote      
 behind number Commits behind remote        

worktree object

  Field    Type                                       Description                                      
 ──────── ─────── ──────────────────────────────────────────────────────────────────────────────────── 
 state    string  "no_worktree", "branch_worktree_mismatch", "prunable", "locked" (absent when normal) 
 reason   string  Reason for locked/prunable state                                                     
 detached boolean HEAD is detached                                                                     

ci object

 Field   Type                      Description                    
 ────── ─────── ───────────────────────────────────────────────── 
 status string  CI status (see below)                             
 source string  "pr" (PR/MR) or "branch" (branch workflow)        
 stale  boolean Local HEAD differs from remote (unpushed changes) 
 url    string  URL to the PR/MR page                             

main_state values

These values describe the relation to the default branch.

"is_main" "orphan" "would_conflict" "empty" "same_commit" "integrated" "diverged" "ahead" "behind"

integration_reason values

When main_state == "integrated": "ancestor" "trees_match" "no_added_changes" "merge_adds_nothing"

ci.status values

"passed" "running" "failed" "conflicts" "no-ci" "error"

Missing a field that would be generally useful? Open an issue at https://github.com/max-sixty/worktrunk.

See also

- wt switch — Switch worktrees or open interactive picker
```

---

## `wt remove`

```
wt remove - Remove worktree; delete branch if merged

Defaults to the current worktree.

Usage: wt remove [OPTIONS] [BRANCHES]...

Arguments:
  [BRANCHES]...
          Branch name [default: current]

Options:
      --no-delete-branch
          Keep branch after removal

  -D, --force-delete
          Delete unmerged branches

      --foreground
          Run removal in foreground (block until complete)

  -f, --force
          Force worktree removal
          
          Remove worktrees even if they contain untracked files (like build artifacts). Without this flag, removal fails 
          if untracked files exist.

  -h, --help
          Print help (see a summary with '-h')

Automation:
  -y, --yes
          Skip approval prompts

      --no-verify
          Skip hooks

Global Options:
  -C <path>
          Working directory for this command

      --config <path>
          User config file path

  -v, --verbose...
          Verbose output (-v: hooks, templates; -vv: debug report)

Examples

Remove current worktree:

  wt remove

Remove specific worktrees / branches:

  wt remove feature-branch
  wt remove old-feature another-branch

Keep the branch:

  wt remove --no-delete-branch feature-branch

Force-delete an unmerged branch:

  wt remove -D experimental

Branch cleanup

By default, branches are deleted when merging them would add nothing. This works with squash-merge and rebase workflows 
where commit history differs but file changes match.

Worktrunk checks five conditions (in order of cost):

1. Same commit — Branch HEAD equals the default branch. Shows _ in wt list.
2. Ancestor — Branch is in target's history (fast-forward or rebase case). Shows ⊂.
3. No added changes — Three-dot diff (target...branch) is empty. Shows ⊂.
4. Trees match — Branch tree SHA equals target tree SHA. Shows ⊂.
5. Merge adds nothing — Simulated merge produces the same tree as target. Handles squash-merged branches where target has 
advanced. Shows ⊂.

The 'same commit' check uses the local default branch; for other checks, 'target' means the default branch, or its 
upstream (e.g., origin/main) when strictly ahead.

Branches showing _ or ⊂ are dimmed as safe to delete.

Force flags

Worktrunk has two force flags for different situations:

        Flag          Scope                          When to use                         
 ─────────────────── ──────── ────────────────────────────────────────────────────────── 
 --force (-f)        Worktree Worktree has untracked files (build artifacts, IDE config) 
 --force-delete (-D) Branch   Branch has unmerged commits                                

  wt remove feature --force       # Remove worktree with untracked files
  wt remove feature -D            # Delete unmerged branch
  wt remove feature --force -D    # Both

Without --force, removal fails if the worktree contains untracked files. Without -D, removal keeps branches with unmerged 
changes. Use --no-delete-branch to keep the branch regardless of merge status.

Background removal

Removal runs in the background by default (returns immediately). Logs are written to .git/wt/logs/{branch}-remove.log. Use
 --foreground to run in the foreground.

Hooks

pre-remove hooks run before the worktree is deleted (with access to worktree files). post-remove hooks run after removal. 
See wt hook for configuration.

Detached HEAD worktrees

Detached worktrees have no branch name. Pass the worktree path instead: wt remove /path/to/worktree. wt switch 
/path/to/worktree also works.

See also

- wt merge — Remove worktree after merging
- wt list — View all worktrees
```

---

