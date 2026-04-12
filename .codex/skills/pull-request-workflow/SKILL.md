---
name: pull-request-workflow
description: Use this skill when the user wants to commit work, push a branch, open or update a pull request, rebase a branch, or avoid merge conflicts in this repo. This skill keeps pull requests small, starts from fresh main, syncs the branch before PR creation, and stops when the worktree has unrelated changes.
---

# Pull Request Workflow

## Use this skill when

- The user wants Codex to create or update a pull request in this repo.
- The user wants Codex to commit and push local changes.
- The user wants Codex to rebase a branch or reduce merge conflicts.

## Goal

- Ship a small clean pull request that is easy to review and safe to merge.
- Keep `main` clean and keep unrelated changes out of the pull request.
- Keep each coding agent isolated so one agent cannot overwrite another agent's work.

## Steps

1. Check the current branch and worktree first.
   - Run `git status -sb`.
   - If the worktree has unrelated changes, stop and show them to the user.
   - Do not stage or carry unrelated files into the pull request.
   - For any code writing task that may end in a commit, push, or pull request, do not work from a shared checkout. Create a dedicated git worktree for that task first.
2. Start from fresh `main` in a dedicated worktree for new work.
   - Run `git fetch origin`.
   - Create a short lived branch named `codex/<task-name>`.
   - Create a dedicated worktree for that branch from `origin/main`.
   - Do all code changes, commits, pushes, and pull request work from that dedicated worktree.
3. Keep the branch focused.
   - Make one pull request for one job.
   - Do not mix feature work, refactors, formatting, cleanup, and docs unless the user asked for all of it together.
   - Do not edit unrelated files.
4. Sync the branch before push or PR creation.
   - Run `git fetch origin` again.
   - Rebase the branch onto `origin/main` when the branch is behind.
   - Push the branch after the rebase.
   - Use `git push --set-upstream origin <branch-name>` for a new branch.
   - Use `git push --force-with-lease` for an existing branch that was rebased.
   - If the branch is badly stale or the conflicts are wide, stop fighting the branch. Create a fresh branch from current `main` and re-apply the intended change.
5. Resolve conflicts with a strict rule.
   - Keep `main` when the pull request was not meant to change that code.
   - Keep the branch when the pull request was meant to change that code.
   - If both sides matter, rewrite the block by hand and run the relevant tests.
   - If the right result is not clear, stop and ask the user.
6. Validate before opening the pull request.
   - Run the smallest relevant test set first.
   - Run the repo checks needed for the changed files.
   - If a commit is requested, make sure `rubocop` passes before the commit.
   - After all code changes are done, read the changed code again before PR creation.
   - Look for obvious errors, missed edge cases, and code that does not follow normal Rails or repo standards.
   - If you find non standard code, stop and show it to the user before creating the pull request.
7. Open the pull request only after the branch is synced and validated.
   - Prefer a draft pull request unless the user asked for ready for review.
   - Use a clear title and body that only describe the intended change.
   - Push the final branch state to GitHub before pull request creation.
   - Open the pull request from that branch in GitHub.
   - Prefer squash merge when the pull request is merged.

## Rules

- `main` is the source of truth.
- Use one worktree per coding agent and one branch per worktree.
- Do not let multiple coding agents share the same checkout for code changes.
- Do not guess during merge conflicts.
- Do not use `git add -A` when the worktree is mixed.
- Do not open a pull request from a stale branch when a fresh branch would be cleaner.
- Do not use merge commits unless the user asked for that flow.
- Do not resolve conflicts by keeping both sides unless the final code is still small and clear.
- Do not create a pull request until the final code review pass is complete.
- Do not create or update a pull request from the shared repo root when a dedicated worktree should be used instead.

## Default Commands

```bash
git status -sb
git fetch origin
git worktree add ../therasaurus-rails-<task-name> -b codex/<task-name> origin/main
cd ../therasaurus-rails-<task-name>
```

```bash
git push --set-upstream origin codex/<task-name>
```

```bash
git fetch origin
git rebase origin/main
git push --force-with-lease
```

```bash
git status -sb
git fetch origin
git rebase origin/main
git push --force-with-lease
```

## Parallel Agent Setup

Use this when more than one coding agent will work on separate pull requests at the same time.

```bash
git fetch origin
git switch main
git pull --ff-only origin main

git worktree add ../therasaurus-rails-<task-a> -b codex/<task-a> origin/main
git worktree add ../therasaurus-rails-<task-b> -b codex/<task-b> origin/main
```

- Run each coding agent inside its own worktree folder.
- Give each agent exactly one task.
- Have each agent commit only its own files, push its own branch, and open its own draft pull request.
- If an agent is only reading code or planning work, a separate worktree is optional.

## Notes

- If a branch has been open long enough that the conflict is confusing, rebuild the change on a new branch from fresh `main`.
- When the user asks Codex to publish work, follow this skill instead of a looser generic publish flow.
- When the user asks Codex to create a pull request, the safe default is: create a dedicated worktree, make the change there, push the branch, and open a draft pull request in GitHub.
