# Session sizing — working memory

Started 2026-11-19. Rework how the harness sizes a session: define it by review size,
independent revert and decision points, with "fits in one context" kept as a backstop;
replace the five fixed size tests with signals, a scoping estimate and a project-set limit;
add a stop partway through when a session outgrows the limit.

**Setup:** Committed: this folder is committed; all sessions are commits on branch
`ccr-670642ff-1n2a64` (assigned by the cloud environment). Push after each session.
Autopilot: on (2026-11-19), mother branch `ccr-670642ff-1n2a64`.
It carries the work across context clears. Workflow: the `multi-session` skill.

The user resumes with: **"Read .sessions/2026-11-19-session-sizing/README.md and continue autopilot."**

## Files

- `spec.md` — what must be true when the work is done.
- `plan.md` — sessions, their tasks, status, and where to clear context.
- `findings.md` — what the analysis found, with file:line references. Why each task exists.
- `decisions.md` — questions for the user and their answers. Check before asking again.
- `log.md` — one entry per session: what was done, commits, what is left, surprises.
- `docs.md` — the docs ledger: every change a durable doc must reflect, and whether it is
  done. Close-out works from it.
- `report.md` — autopilot only: the report of the whole effort, written at the end.
