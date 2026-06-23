---
name: pr-conflict-resolver
description: "Resolves pull request merge conflicts carefully and conservatively, asking the user whenever the correct resolution is unclear. Use when the user asks to fix PR conflicts, resolve merge conflicts, rebase a conflicted branch, or decide between base-branch structure and branch-specific content."
---

# PR Conflict Resolver

Resolve merge conflicts on the current branch carefully. Preserve intent, avoid silent guesses, and ask the user whenever the correct resolution is not clearly supported by the code or surrounding context.

## Scope

Use this skill when the user wants help with a conflicted PR or branch, including requests like:

- "fix PR conflicts"
- "resolve merge conflicts"
- "rebase and handle conflicts"
- "help me choose the right side of this conflict"

This skill is for conflict resolution in the current repository and current branch.

## Rules

- Be conservative. Do not pick a side blindly.
- Treat conflict resolution as a semantic merge task, not a text-editing task.
- Prefer keeping both sides when they are complementary.
- Ask the user whenever the right answer depends on product intent, architecture direction, ownership, or naming/structure conventions.
- If the base branch changed structure and the PR branch changed content, do not assume which one wins. Inspect both and ask if the answer is not obvious.
- Do not discard code without being able to justify why it is obsolete or incorrect.
- Keep the final file consistent, compilable, and stylistically aligned with the surrounding code.
- If conflict resolution rewrites branch history and a push is needed, use `git push --force-with-lease`, never a plain `--force`.

## When to ask the user

Stop and ask if any conflict involves uncertainty such as:

- base branch introduces a new structure, abstraction, or file layout
- PR branch contains business logic that no longer fits cleanly into the new structure
- both sides changed the same logic in different ways
- one side renames or moves code while the other side edits behavior
- either side may reflect a newer product decision or API contract
- conflict touches generated files, lockfiles, migrations, or large refactors where policy may vary by team

Typical questions to ask:

- "Should I preserve the structure from `main` and port this branch's behavior into it?"
- "This looks like a rename on one side and a logic change on the other. Do you want both combined?"
- "The base branch removed this code, but this branch expands it. Was the removal intentional?"

## Workflow

### 1. Inspect the conflict state

Start by identifying the merge/rebase state and conflicted files.

Useful commands:

```sh
git status --short
git diff --name-only --diff-filter=U
git ls-files -u
```

Determine whether the repo is currently in:

- merge
- rebase
- cherry-pick
- normal working tree with conflict markers already present

If there are no active conflicts, stop and tell the user.

### 2. Understand both sides before editing

For each conflicted file:

- read the conflict markers in the working tree
- inspect the surrounding file for structure and intent
- inspect the base, ours, and theirs versions if needed
- look at nearby code that references the conflicted symbols

Useful commands:

```sh
git show :1:path/to/file
git show :2:path/to/file
git show :3:path/to/file
```

Interpret stages carefully depending on merge vs rebase context.

### 3. Classify the conflict

For each file or hunk, decide what kind of conflict it is:

- **structure vs content** — one side reorganized code, the other changed logic
- **parallel logic edits** — both sides changed behavior in overlapping lines
- **rename/move vs edit** — one side moved code, the other modified it
- **deletion vs modification** — one side removed code, the other updated it
- **mechanical conflict** — imports, formatting, generated sections, lockfiles

Mechanical conflicts can often be resolved directly.
Semantic conflicts require stronger evidence and often a user question.

### 4. Resolve only what is clear

Resolve without asking only when the correct result is strongly supported by context, for example:

- duplicate imports or trivial ordering conflicts
- both sides can be safely combined
- one side is clearly stale or mechanically superseded
- a move/rename is obvious and the behavioral change can be ported cleanly

When resolving:

- preserve all required behavior
- preserve the current architecture unless the conflicting change clearly replaces it
- rewrite the merged result cleanly instead of stitching conflict markers together line-by-line

### 5. Ask for clarification on ambiguous conflicts

If one or more hunks are unclear, pause and present:

- conflicted file
- short explanation of the two sides
- what you think each side is trying to do
- the concrete decision you need from the user

Keep the question specific and decision-oriented.

### 6. Finalize carefully

After resolving all clear conflicts:

- ensure no conflict markers remain
- ensure the file reads as intentional code, not a textual splice
- if the repository is in merge/rebase/cherry-pick flow, remind yourself to stage the resolved files

If the user asked you to complete the process, stage the resolved files. Do not commit unless explicitly asked.

If the branch was rebased or otherwise had its history rewritten and the user asked you to update the remote branch, push with lease safety:

```sh
git push --force-with-lease
```

Use a normal `git push` only when history was not rewritten.

## Resolution heuristics

### Prefer combining both sides when:

- one side changes API shape and the other side changes behavior using the same concept
- imports, dependencies, or registrations from both sides are needed
- a new wrapper or abstraction from base can host the branch-specific logic cleanly

### Prefer base-branch structure when:

- base introduced a broader refactor adopted across nearby files
- the PR branch's code can be ported into the new structure with little ambiguity
- keeping the old structure would reintroduce obsolete patterns

### Prefer PR-branch content when:

- it contains the feature or fix under review
- base-side changes are mostly mechanical and can be incorporated around it
- dropping it would silently remove the branch's intended behavior

These are heuristics, not automatic rules. Ask when in doubt.

## Output format

For each conflicted file, summarize:

- `file`
- `conflict type`
- `decision`
- `reason`
- `needs user input` (`yes` or `no`)

If asking the user something, end with a short numbered list of the decisions you need.

## Troubleshooting

- If conflict markers remain, search for `<<<<<<<`, `=======`, and `>>>>>>>` before finishing.
- If stage meanings are confusing during rebase, inspect the file content and commit history rather than relying on assumptions.
- If the branch must be updated after a rebase, use `git push --force-with-lease` rather than `git push --force`.
- If a lockfile or generated file conflicts, prefer regenerating it only when the project has a clear standard workflow and the result is deterministic.
- If a file was deleted on one side and modified on the other, do not guess whether the deletion was intentional; inspect nearby code and ask if unclear.
