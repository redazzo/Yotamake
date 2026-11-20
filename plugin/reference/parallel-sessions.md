# Running sessions in parallel

The `multi-session` skill sends you here ("Running sessions in parallel") when the user wants
a session to run beside the current one, or when a session runs in its own worktree.

Two sessions may run at the same time, each in its own git worktree with its own Claude Code
conversation (the harness's ADR-0005 has the reasons). Only when all of these hold:

- the effort uses the local setup, not a committed folder;
- every session each one needs (its `Needs:` line) is `done`;
- they change different files.

When the user wants a session to run beside the current one, start it like this:

1. From the main worktree, on an up-to-date main branch, add the worktree as a sibling
   folder on the session's branch: `git worktree add ../<repo>-s<N> -b <prefix>/<slug>`.
2. Do the project's worktree setup there: the `Worktree setup` line in CLAUDE.md, **Branching
   and releases** (copy `.env`, install dependencies). If the line is missing, say so and
   ask the user what the checks need; do not guess.
3. Set the session's status in `plan.md` to `in progress (worktree ../<repo>-s<N>)`.
4. Give the user the command to open Claude Code there (`cd ../<repo>-s<N> && claude`) and a
   resume line with the folder's absolute path: "Read <absolute path>/README.md and start
   S<N>." The working folder stays in the main worktree; the new one has no copy, since it is
   git-ignored.

Inside a worktree session:

- The branch is already cut: skip the cut (`simple-session`, "Branch").
- Edit only your own `## S<N>` section of `plan.md`. Only append to `log.md` and `docs.md`;
  never rewrite another session's rows. If an edit fails because the file changed, read it
  again and redo the edit.
- **Commits.** If the effort opted in to worktree commits (a row in `decisions.md` saying
  so), commit on the session's branch as soon as the checks and the review pass, then report.
  The opt-in is the user's yes, so no prompt follows; the commit gate still refuses a commit
  before the check and the review. Without that row, stop and ask as usual.
  Merge, push, rebase, `reset --hard`, tag and the release always keep their stop.

Merging, one branch at a time:

1. In the worktree, if the main branch has moved since the branch was cut, merge it into the
   branch (`git merge <main-branch>`), fix any conflict, and run `scripts/check` again.
2. Then do the project's release steps (CLAUDE.md, **Branching and releases**), never
   earlier, so two branches do not claim the same version.
3. Merge into the main branch from the main worktree, as `simple-session`, "On yes: commit,
   bump, integrate" says (`git -C <main worktree> merge --no-ff <branch>` works from the
   worktree).
4. After the merge, remove the worktree: `git worktree remove ../<repo>-s<N>`. Delete the
   branch only if the user asks.
