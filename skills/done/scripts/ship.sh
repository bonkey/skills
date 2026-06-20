#!/usr/bin/env bash
# ship.sh — deterministic fast path for the `done` skill.
#
# Gathers every ship-relevant fact in ONE pass, then either:
#   • completes the local-merge happy path (branch → local default → origin), or
#   • prints a structured HANDOFF/ERROR and exits so the agent takes over the
#     unusual cases (open PR, protected default, conflicts, divergence, …).
#
# Deciding WHAT to ship is judgment, so this script never stages or commits —
# it requires an already-committed, clean working tree and refuses to sweep in
# unrelated or stray changes. The agent commits deliberately (with review); the
# script does only the mechanical merge + push, with no model in the loop.
#
# Usage:  ship.sh
#
# Output: plain-text sections marked `=== SHIP: <KIND> ===` for the agent to
# parse. KINDs: STATE (always), MERGING/DONE (happy path), HANDOFF, ERROR.
# Exit 0 on success or handoff; non-zero only on a hard error.

set -uo pipefail

emit() { printf '%s\n' "$*"; }

fail() {        # fail <step> [detail...]
  emit "=== SHIP: ERROR ==="
  emit "step: $1"; shift
  [ "$#" -gt 0 ] && emit "detail: $*"
  exit 1
}

handoff() {     # handoff <suggested_path> <reason...>
  emit ""
  emit "=== SHIP: HANDOFF ==="
  emit "suggested_path: $1"; shift
  for r in "$@"; do emit "reason: $r"; done
  emit "(the STATE block above is complete — take over without re-gathering)"
  exit 0
}

# --- tooling + repo -------------------------------------------------------
command -v git >/dev/null 2>&1 || fail "tooling" "git not found"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "repo" "not inside a git work tree"

branch="$(git rev-parse --abbrev-ref HEAD)"
worktree="$(git rev-parse --show-toplevel)"

# default branch: origin/HEAD if known, else main
default="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
[ -z "$default" ] && default="main"

# --- refresh + read-only state (one pass) --------------------------------
git fetch origin --quiet 2>/dev/null || true

dirty_files="$(git status --porcelain 2>/dev/null | grep -c . || true)"
ahead="$(git rev-list --count "$default..HEAD" 2>/dev/null || echo '?')"
behind_origin="$(git rev-list --count "$default..origin/$default" 2>/dev/null || echo '0')"

if git merge-base --is-ancestor "$default" HEAD 2>/dev/null; then ff="yes"; else ff="no"; fi

op="none"
gitdir="$(git rev-parse --git-dir)"
{ [ -d "$gitdir/rebase-merge" ] || [ -d "$gitdir/rebase-apply" ]; } && op="rebase"
[ -f "$gitdir/MERGE_HEAD" ] && op="merge"
[ -n "$(git ls-files -u 2>/dev/null)" ] && op="conflicts"

pr_url=""
if command -v gh >/dev/null 2>&1; then
  pr_url="$(gh pr list --head "$branch" --state open --json url --jq '.[0].url // empty' 2>/dev/null || echo '')"
  protected="$(gh api "repos/:owner/:repo/branches/$default" --jq '.protected' 2>/dev/null || echo 'unknown')"
else
  protected="unknown"
fi

default_wt="$(git worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/$default" '
  /^worktree /{p=$2} /^branch /{ if ($2==b) print p }' | head -1)"

emit "=== SHIP: STATE ==="
emit "branch: $branch"
emit "default: $default"
emit "worktree: $worktree"
emit "dirty_files: $dirty_files"
emit "commits_ahead: $ahead"
emit "local_${default}_behind_origin: $behind_origin"
emit "ff_mergeable: $ff"
emit "op_in_progress: $op"
emit "pr_exists: ${pr_url:-none}"
emit "default_protected: $protected"
emit "default_checked_out_at: ${default_wt:-none}"

# --- guards: anything unusual → hand the wheel to the agent ---------------
[ "$branch" = "HEAD" ]      && handoff "manual"    "HEAD is detached — no branch to ship"
[ "$branch" = "$default" ]  && handoff "manual"    "currently on the default branch ($default) — nothing to ship"
[ "$op" != "none" ]         && handoff "resolve"   "a $op is in progress — finish or abort it first"
[ -n "$pr_url" ]            && handoff "update-pr" "an open PR already exists: $pr_url"
[ "$protected" = "true" ]   && handoff "create-pr" "$default is protected — open a PR instead of merging locally"
[ "$behind_origin" != "0" ] && handoff "manual"    "local $default is $behind_origin commit(s) behind origin/$default — reconcile first"
[ "$ff" != "yes" ]          && handoff "manual"    "branch diverged from $default (no fast-forward) — rebase or resolve manually"
[ "$ahead" = "?" ]          && handoff "manual"    "could not determine commits ahead of $default"

# --- ready check: must be committed and clean ----------------------------
# The script never stages, so whatever is uncommitted here is the agent's call:
# review for unrelated/stray files, commit what belongs, then re-run. This also
# means `wt merge --no-commit` below can never skip a forgotten change — there
# are none — and it catches files a pre-commit hook may have left behind.
if [ "$dirty_files" != "0" ]; then
  emit ""
  emit "uncommitted changes:"
  git status --short
  handoff "commit" "$dirty_files uncommitted change(s) — review (watch for unrelated/stray files), commit what you intend to ship, then re-run"
fi
[ "$ahead" = "0" ] && handoff "nothing" "clean tree and 0 commits ahead of $default — nothing to ship"

# --- happy path: fast-forward default to the branch, push ----------------
# --no-commit: merge only what is already committed (tree is verified clean
#              above), preserving the agent's commit(s) and message verbatim —
#              no re-squash, no LLM message regeneration.
# --no-remove: keep the worktree.
emit ""
emit "=== SHIP: MERGING ==="
old_main="$(git rev-parse "$default")"

merge_out="$(wt merge --no-commit --no-remove 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && { emit "$merge_out"; fail "wt-merge" "wt merge exited $rc"; }

push_out="$(git push origin "$default" 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && { emit "$push_out"; fail "push" "git push exited $rc"; }

new_main="$(git rev-parse "$default")"
stat="$(git diff --shortstat "$old_main" "$new_main" 2>/dev/null)"

emit ""
emit "=== SHIP: DONE ==="
emit "default: $default"
emit "old: $(git rev-parse --short "$old_main")"
emit "new: $(git rev-parse --short "$new_main")"
emit "changes:${stat:+ }$stat"
emit "worktree_preserved: yes"
emit "pushed_to: origin/$default"
