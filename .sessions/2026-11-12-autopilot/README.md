# Autopilot for multi-session efforts — working memory

Started 2026-11-12. Adds an option to `multi-session` that runs every session after S0
without the user, on one mother branch, then reports and asks to merge into main.

**Setup:** Committed: this folder is committed; all sessions are commits on branch
`claude/multi-session-automation-merge-6bxczv` (a cloud session with an assigned branch).
It carries the work across context clears. Workflow: the `multi-session` skill.

The user resumes with: **"Read .sessions/2026-11-12-autopilot/README.md and start the next session."**

## Files

- `spec.md` — what must be true when the work is done.
- `plan.md` — sessions, their tasks, status, and where to clear context.
- `findings.md` — what the analysis found, with file:line references. Why each task exists.
- `decisions.md` — questions for the user and their answers. Check before asking again.
- `log.md` — one entry per session: what was done, commits, what is left, surprises.
- `docs.md` — the docs ledger: every change a durable doc must reflect, and whether it is
  done. Close-out works from it.
