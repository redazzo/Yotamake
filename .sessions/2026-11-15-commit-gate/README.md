# Commit gate (ADR-0006) — working memory

Started 2026-11-15. Implement ADR-0006: replace the `Bash(git commit:*)` `ask` rule with a
project `PreToolUse` hook that fails closed, so opted-in worktree sessions commit without a
prompt and every other commit still asks. First prove the design holds (the ADR's "Before
acceptance" tests); build only if it does.

**Setup:** Committed: this folder is committed; all sessions are commits on branch
`ccr-41e6ce46-6hq1pm` (a cloud session's assigned branch).
It carries the work across context clears. Workflow: the `multi-session` skill.

The user resumes with: **"Read .sessions/2026-11-15-commit-gate/README.md and start the next
session."**

## Files

- `spec.md` — what must be true when the work is done.
- `plan.md` — sessions, their tasks, status, and where to clear context.
- `findings.md` — what the analysis found, with file:line references. Why each task exists.
- `decisions.md` — questions for the user and their answers. Check before asking again.
- `log.md` — one entry per session: what was done, commits, what is left, surprises.
- `docs.md` — the docs ledger: every change a durable doc must reflect, and whether it is
  done. Close-out works from it.
