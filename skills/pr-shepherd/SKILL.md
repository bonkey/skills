---
name: pr-shepherd
description: "Carries the current pull request toward mergeable: reads what the base branch actually requires — required checks, approvals, thread resolution, linear history — finds every unmet requirement, fixes what it can, then registers a monitor and hands the watch back to the agent. Use when the user asks to monitor or babysit a PR, get a PR ready to merge, unblock a PR, fix red checks, or make a PR green. Never merges unless the user says to."
---

# PR Shepherd

Take the current PR from blocked to ready-to-merge. Read what the base branch actually requires, check the PR against each requirement, fix what code changes can fix, and for anything that needs waiting — CI runs, reviewer replies — register a monitor and hand the watch back to the agent. Every requirement ends the run in exactly one state: already met, fixed, rejected with the reasoning posted, or open with an owner named.

This skill does not loop. One run gathers state, fixes, pushes, arms the monitor, and reports. The agent resumes when the monitor fires.

Merging is not part of the job unless the user says it is. See [step 0](#0-settle-merge-intent-first).

## Scope

Use this skill when the user wants a PR carried to a mergeable state:

- "monitor the PR and fix whatever comes up"
- "get this PR ready to merge"
- "checks are red, sort them out"
- "babysit this PR"
- "why can this PR not merge?"

The target is the **current PR on the current branch**, unless the user names another PR or branch.

Related skills do parts of this job. Call them instead of re-implementing them:

- `pr-comment-triage` — evaluate, reply to, and resolve review comments
- `smooth-rebase` — rebase onto the default branch and resolve conflicts
- `pr` — create or update the PR itself

## Rules

- **Never merge by default.** Merge only when the user's instruction for this run clearly says to, or after you asked and they said yes. Enabling auto-merge counts as merging — the same rule applies.
- Ask about the end state once, at the start of the run, not after the work is done. See step 0.
- Read the merge requirements before deciding anything is a blocker. Which checks are required, whether every thread must be resolved, and how many approvals are needed are repository settings — read them, do not assume them. See step 2.
- Every requirement ends the run in exactly one state: **already met**, **fixed**, **rejected** with the reasoning posted, or **open** with an owner and what would unblock it. Nothing is left unaccounted for. The four states are defined in step 3 and reported in step 6.
- Fix the cause, not the symptom. Never make CI green by deleting a test, loosening an assertion, skipping a job, or marking a check non-required.
- Read every page of every API response. GitHub caps list responses at 100 items, so pass `--paginate` and follow cursors to the end; see `pr-comment-triage` for the paginated comment queries.
- Batch the fixes. Collect everything the PR needs, then push once, so one CI cycle covers the lot instead of one per edit.
- Rebase before you trust CI. A branch that is behind or conflicted produces check results about code that will not be merged.
- Never force-push a branch that carries commits you did not make without telling the user first.
- Stop at the human wall. Required approvals, `CODEOWNERS` sign-off, product decisions, and repository settings are not yours to satisfy — name them and hand them back.
- Mark every comment you post to the PR with a trailing attribution line on its own line: `🤖 Generated with Claude Code`.
- Report each posted comment with the URL the API returned at post time. Never reconstruct a link.
- Each run reads live state fresh. Assume the skill runs many times on the same PR and that both the code and the comments moved since the last run.

## Workflow

### 0. Settle merge intent first

Before touching anything, decide which end state this run is aiming for:

1. **Stop at green** — get the PR mergeable and report. This is the default.
2. **Merge when green** — the user said so explicitly this run.

If the user's request does not make the end state clear, ask once, up front, and include the merge method in the question when the repository allows more than one. Do not ask again later in the same run.

Never treat "get it ready", "unblock it", "make it green", or "fix the PR" as permission to merge.

### 1. Read the full PR state

```sh
gh pr view --json number,title,url,isDraft,mergeable,mergeStateStatus,reviewDecision,autoMergeRequest,baseRefName,headRefName,statusCheckRollup
gh pr checks --json name,state,bucket,link,description,workflow
```

`mergeStateStatus` names the blocker directly:

| Value      | Meaning                                          | Action                                            |
|------------|--------------------------------------------------|---------------------------------------------------|
| `CLEAN`    | mergeable, checks passing                        | nothing to fix; report                            |
| `UNSTABLE` | mergeable, but a non-required check is failing   | fix the failing check or say why it is acceptable |
| `BLOCKED`  | a branch-protection rule is unmet                | usually approvals or a required check             |
| `BEHIND`   | the base branch moved ahead                      | run `smooth-rebase`                               |
| `DIRTY`    | merge conflicts                                  | run `smooth-rebase`                               |
| `DRAFT`    | still a draft                                    | ask before marking ready for review               |
| `UNKNOWN`  | GitHub is still computing it                     | re-query in a few seconds                         |

`mergeable` and `mergeStateStatus` are computed asynchronously. `UNKNOWN` means "ask again", not "no blocker".

### 2. Determine what merge actually requires

Never guess the requirements. Read them for the base branch — they decide which red check blocks the merge and which is noise, and whether an unresolved thread is fatal or cosmetic.

```sh
BASE=$(gh pr view --json baseRefName -q .baseRefName)

# Effective rules for the base branch. Works with plain read access.
gh api "repos/OWNER/REPO/rules/branches/$BASE"

# Classic branch protection. Richer, but needs admin on the repository.
gh api "repos/OWNER/REPO/branches/$BASE/protection"
```

Map each rule to the work it implies:

| Rule (ruleset `type` / `parameters`) | Requirement | How you satisfy it |
|---|---|---|
| `required_status_checks` | the named checks must pass | fix these first; other red checks are advisory |
| `pull_request.required_approving_review_count` | N approvals | request review, then report; you cannot approve for a human |
| `pull_request.required_review_thread_resolution` | every review thread resolved | drive each thread to resolved with `pr-comment-triage` |
| `pull_request.require_code_owner_review` | a `CODEOWNERS` approval | read `.github/CODEOWNERS`, request the owning reviewer |
| `pull_request.require_last_push_approval` | approval after the last push | land all fixes in one push, then re-request review once |
| `pull_request.dismiss_stale_reviews_on_push` | a push drops existing approvals | batch fixes; warn the user before a push that costs an approval |
| `required_linear_history` | no merge commits | rebase; never merge the base branch in |
| `required_signatures` | signed commits | keep signing configured; never bypass it to get a commit through |
| `merge_queue` | merge through the queue | do not push or re-trigger once queued |
| `required_deployments` | a deployment succeeded first | report it; usually not yours to trigger |

Classic protection uses different names for the same things: `required_status_checks.contexts`, `required_pull_request_reviews.*`, and `required_conversation_resolution.enabled`.

If both API calls are denied, infer the requirements from what the PR exposes — `mergeStateStatus`, `reviewDecision`, the required flag on each `statusCheckRollup` entry, and `.github/CODEOWNERS` — and state in the report that they were inferred rather than read.

### 3. Work the requirement list

Turn step 2 into a list of concrete items, each with its current state, before fixing anything:

- **Required checks** (`check`) — every required check that is not passing, with the failing job and its log
- **Advisory checks** (`check`) — red checks that are not required; fix them or record why they are acceptable
- **Review threads** (`comment`) — every unresolved thread and actionable top-level comment, fetched fresh and fully paginated
- **Approvals** (`approval`) — how many are required against `reviewDecision` and `latestReviews`, plus any `CODEOWNERS` gap
- **Branch state** (`branch`) — `DIRTY`, `BEHIND`, or a linear-history rule the branch breaks
- **Other gates** (`gate`) — merge queue, required deployments, signature rules, draft state
- **Hygiene** (`hygiene`) — a description that no longer matches the PR, or labels the repository expects

Then drive each item to exactly one of these four states, and never skip one silently:

- **already met** — satisfied before this run started. Record it so the list stays complete.
- **fixed** — the requirement is now met, with the commit or thread that met it
- **rejected** — the request is wrong, obsolete, or does not apply. Post the reasoning on the thread, resolve it where resolution is yours to do, and record the rejection.
- **open** — nothing you can do: it needs an approval, a permission, a product decision, or a repository setting change. Record who owns it and what would unblock it.

An item you cannot fix is a reported item, never a dropped one.

Ignore bot noise unless the bot owns a required check or the user asked to include it.

### 4. Fix in this order

1. **Conflicts and staleness.** Invoke `smooth-rebase`. Push the rebased branch, then re-read state — the rebase alone can clear later blockers.
2. **Failing checks.** Required checks first, advisory ones after. Get the real error before editing anything:

   ```sh
   gh pr checks --json name,bucket,link            # find the failing run
   gh run view RUN_ID --log-failed                 # read only the failing step's log
   gh run view RUN_ID --job JOB_ID --log           # full log for one job when needed
   ```

   Reproduce locally where the repository makes that possible, fix the cause, and keep the change scoped to the failure.
3. **Review comments.** Invoke `pr-comment-triage`. It decides what to address, replies, and resolves threads.
4. **Hygiene.** Update the description or labels only when the repository or the user requires it.
5. **Approvals and gates.** These are not yours to satisfy. Request the review or name the gate, then record the item as open.

Then push once, and note the commit you pushed — the monitor watches the run it triggers.

### 5. Arm the monitor and hand over

Do not sit in a polling loop inside this run. Register the watch, then return control to the agent.

Set up whichever of these fits the harness:

- **Background wait on checks** — run this as a background command so the agent is re-invoked when it exits:

  ```sh
  gh pr checks --watch --fail-fast
  ```

  It exits non-zero as soon as a check fails, and zero when they all pass.
- **Condition monitor** — if the harness has a monitor tool (Claude Code: `Monitor`), register the condition there instead, for example "`gh pr view --json mergeStateStatus` reports `CLEAN` or a check bucket turns `fail`".
- **Fixed cadence** — when the user wants repeated sweeps over time rather than a single wait, hand the recurrence to the harness scheduler (Claude Code: `/loop`) with this skill as the prompt. Do not build the interval into the run.

New comments have no watch API. When the run is waiting on reviewers rather than CI, say so and set the next sweep on a cadence instead of a blocking wait.

Tell the user, in the handover, exactly what is being watched and what happens when it fires.

### 6. Report

Give one row per requirement from step 2 — including the ones that were already met:

| Requirement | Kind | Required by | State | Action taken | Owner |
|---|---|---|---|---|---|

`Kind` is one of `check`, `comment`, `approval`, `branch`, `gate`, `hygiene`. `Required by` is the rule that demands it, or `advisory`. `State` is `already met`, `fixed`, `rejected`, or `open`, in the step 3 sense. `Owner` is `agent`, `reviewer`, or `user`.

Say plainly whether the requirements were read from the API or inferred.

Then, in this order:

1. **Fixed this run** — one line each, with the commit.
2. **Rejected** — what you declined and why, with the thread where you said so.
3. **Watching** — what the monitor covers and when it fires.
4. **Still open** — approvals, decisions, permissions, and repository settings, each with its owner and what would unblock it.
5. **Comments posted** — one bullet each, one or two sentences plus the API-returned link.

### 7. Merge only on an explicit yes

When step 0 established "merge when green", and the PR is genuinely mergeable, merge with the method the user named:

```sh
gh pr merge PR_NUMBER --squash            # or --merge / --rebase, as the user asked
gh pr merge PR_NUMBER --squash --auto     # queue it, only when the user asked for auto-merge
```

Before merging, confirm from live state — not from an earlier read in the same run — that `mergeStateStatus` is `CLEAN` and `reviewDecision` is `APPROVED`. If either changed, stop and report instead of merging.

Never delete the branch unless the user asked or the repository does it automatically.

## Definition of done

The PR is mergeable when every requirement read in step 2 is met — not when a generic checklist is met. In practice that usually means:

- `mergeStateStatus` is `CLEAN`
- every required check passes, and every red advisory check is fixed or explained
- every review thread is resolved where the repository requires resolution; otherwise no open thread still asks for a change
- the required approval count is met, `CODEOWNERS` included
- the PR is not a draft, and the description matches what it now does

The run is done when every item on the list carries one of the four step 3 states — `already met`, `fixed`, `rejected`, or `open` with an owner. A requirement you cannot meet does not stop the run; an unreported one does.

## Troubleshooting

- **`mergeable` is `UNKNOWN`** — GitHub is still computing it. Wait and re-query; do not report the PR as blocked or clean on that value.
- **A check has no logs** — an external check reports through the API only. Follow its `link` and report what it says rather than guessing.
- **A check fails only in CI** — compare the CI environment against local: runner OS, tool versions, environment variables, and test ordering.
- **A flaky check** — re-run it once (`gh run rerun RUN_ID --failed`). If it fails again, treat it as a real failure. Never re-run in a loop to chase a green.
- **`BLOCKED` with all checks green** — branch protection wants approvals, a `CODEOWNERS` review, or a conversation resolved. Name the missing requirement; you cannot satisfy it.
- **The PR sits in a merge queue** — do not push or re-trigger while it is queued. Report the queue position and wait.
- **The rules API returns 403 or 404** — you lack the access, or the branch has no ruleset. Fall back to the PR's own fields, and label the requirements as inferred.
- **`gh` is not authenticated** — tell the user to run `gh auth login`.
- **No PR for the current branch** — stop and tell the user; suggest the `pr` skill if they want one created.
