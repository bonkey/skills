---
name: pr-comment-triage
description: "Reviews all comments on the current pull request, evaluates whether each one still needs action, and decides whether to address it or resolve it. Use when the user asks to triage PR comments, review feedback, resolve review threads, or decide which PR comments still matter."
---

# PR Comment Triage

Review every comment on the current PR and make a careful decision for each one: address it in code, reply for clarification, or resolve it when it is already handled. Resolve every review thread you have confirmed is handled, and always leave a short explanation reply when you resolve one.

## Scope

Use this skill when the user wants help with the current PR's feedback, including requests like:

- "go through the PR comments"
- "triage review feedback"
- "check whether these PR comments still need work"
- "resolve addressed review comments"

This skill is for the **current PR on the current branch**.

## Rules

- Be conservative about *whether* a thread is handled, but once you have confirmed it is, resolve it — do not leave verified-handled threads open.
- Always leave a short explanation reply on a thread before resolving it, regardless of why it is being resolved (fixed in code, invalid, obsolete, or settled by discussion).
- Mark every comment you post to the PR (thread replies and top-level comments alike) with a trailing attribution line: `🤖 Generated with Claude Code`. Put it on its own line at the end of the comment body.
- This skill is repeatable. Assume it may be run many times on the same PR, and each run fetch the live state fresh — never rely on a previous run's inventory. On every run, pick up comments added since last time and re-check open threads that the code may have made addressed or obsolete.
- Distinguish between **review threads** and **top-level PR comments**:
  - Review threads can be resolved.
  - Top-level PR conversation comments cannot be marked resolved in GitHub; they can only be replied to or left as-is.
- Never batch-resolve everything blindly.
- Read the current code and the surrounding discussion before deciding.
- If a comment is ambiguous, conflicts with other feedback, or would require a product/architecture decision, ask the user instead of guessing.

## Workflow

### 1. Identify the current PR

Get the current PR for the checked-out branch.

Preferred commands:

```sh
gh pr view --json number,title,url,comments,reviews
```

Use `gh api graphql` to fetch review threads, since `gh pr view` may not expose the full thread inventory you need.

Fetch:

- PR number, title, URL
- Review threads with:
  - thread id
  - resolved state
  - file path / line if available
  - all comments in the thread
- Top-level issue comments on the PR conversation

If no PR exists for the current branch, stop and tell the user.

### 2. Build a complete comment inventory

Collect **all human feedback** that may require action. Build this fresh on every run so repeated runs stay in sync with the live PR:

- Unresolved review threads — including any added since the last run
- Open threads whose concern the current code may now have addressed (resolve them) or made obsolete (the code they referenced was changed, moved, or removed)
- Resolved review threads that may have been resolved incorrectly
- Top-level PR comments in the conversation
- Review summaries when they include actionable requests

For each item, capture:

- comment/thread identifier
- author
- timestamp
- location in code if applicable
- raw comment text
- replies / thread context
- current resolved state

Ignore obvious bot noise unless the user asked to include it.

### 3. Evaluate each comment carefully

For every comment, classify it into one of these buckets:

1. **Address in code**
   - The feedback is valid and not yet handled.
   - A code/config/document change is still needed.

2. **Already addressed, safe to resolve**
   - The requested change is already present in the current branch.
   - Or the thread was superseded by a better implementation and the original concern is no longer applicable.

3. **Needs discussion / user decision**
   - The comment is ambiguous.
   - The request conflicts with other requirements.
   - The suggested fix is risky, architectural, or subjective.

4. **No action needed, but cannot be resolved automatically**
   - Usually applies to top-level PR comments, because GitHub does not support resolving them.
   - Optionally draft a reply explaining why no further change is needed.

### 4. Verify against the current code

Before deciding that something is addressed:

- Read the relevant files.
- Check whether the requested behavior is actually implemented.
- Check whether later commits or replies already handled the concern.
- Prefer evidence from the codebase over assumptions.

Do not treat "I think this is fine" as enough reason to resolve a thread.

### 5. Present a triage summary before acting

Produce a concise summary grouped by decision:

- **Address**
- **Resolve**
- **Needs user input**
- **Top-level comments with no further action**

For each item include:

- author
- short quote or paraphrase
- decision
- one-sentence rationale

If the user asked you to act, proceed after the summary unless a decision is ambiguous or risky.

## Acting on the decisions

### When a comment should be addressed

- Make the smallest correct change that resolves the underlying concern.
- Keep the fix scoped to the feedback.
- After changing code, re-check the thread against the new code, then resolve it with a short reply describing the fix (see below).

### When a review thread should be resolved

Resolve only review threads, not top-level PR comments.

**Always post a short explanation reply before resolving the thread**, regardless of why it is being resolved. One or two sentences is enough; the reply tells the reviewer what happened:

- **fixed in code** — name the change and, when useful, the commit or `file:line`
- **invalid** — explain why the concern does not apply to the actual implementation
- **obsolete** — the relevant code was removed or replaced
- **settled by discussion** — point to the reply or decision that resolved it

End every reply body with the attribution line `🤖 Generated with Claude Code` on its own line.

Required approach (do both, in this order):

1. Post the explanation reply on the thread.
2. Resolve the thread via GitHub GraphQL.

Example shape:

```sh
# 1. Reply with a short explanation (end the body with the attribution line)
gh api graphql -f query='mutation($threadId:ID!,$body:String!) { addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$threadId, body:$body}) { comment { id } } }' -F threadId='THREAD_ID' -F body='Fixed in <commit> — extracted the helper as requested.

🤖 Generated with Claude Code'

# 2. Resolve the thread
gh api graphql -f query='mutation($threadId:ID!) { resolveReviewThread(input:{threadId:$threadId}) { thread { isResolved } } }' -F threadId='THREAD_ID'
```

If the thread is already resolved, do not touch it unless you discovered it was resolved incorrectly; in that case, tell the user rather than silently changing history.

### When the item is a top-level PR comment

Top-level PR comments cannot be resolved. Instead:

- decide whether code changes are needed
- optionally draft or post a short reply
- report it as addressed / no action needed in your summary

Do not claim you resolved something GitHub does not allow you to resolve.

## Output format

Use a compact checklist or table with columns like:

- `kind` (`thread`, `top-level`, `review-summary`)
- `author`
- `location`
- `decision`
- `reason`
- `action`

## Decision standard

A thread is safe to resolve only when at least one of these is true:

- the requested change is now present in code
- the concern is invalid based on the actual implementation
- a later discussion explicitly settled the issue
- the thread is obsolete because the relevant code was removed or replaced

If none of those are clearly true, do not resolve it.

## Troubleshooting

- If `gh` is not authenticated, tell the user to run `gh auth login`.
- If GraphQL fields differ by GitHub version or API shape, fall back to a custom `gh api graphql` query.
- If the current branch has no PR, stop and tell the user.
- If you cannot determine whether a comment is addressed from the code alone, ask the user instead of guessing.
