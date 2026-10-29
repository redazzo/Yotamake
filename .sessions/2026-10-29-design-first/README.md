# Design first — working memory

Started 2026-10-29. Make Yotamake driven by good architecture, strong design adherence and
code reuse discipline, instead of leaving design to chance. Yotamake applied to itself.

**Setup:** Committed: this folder is committed; all sessions are commits on branch
`ccr-a2810672-dyj24j`. It carries the work across context clears. Workflow: the
`multi-session` skill.

This repo has no `scripts/check` (it is the harness, not a project that uses it). The gate is
the "Before committing" list in the root `CLAUDE.md`. There is no `docs/` system either, so
close-out moves what lasts into `README.md` (as in a lite install).

The user resumes with: **"Read .sessions/2026-10-29-design-first/README.md and start the next
session."**

## Files

- `spec.md` — what must be true when the work is done.
- `plan.md` — sessions, their tasks, status, and where to clear context.
- `findings.md` — what the analysis found, with file:line references. Why each task exists.
- `decisions.md` — questions for the user and their answers. Check before asking again.
- `log.md` — one entry per session: what was done, commits, what is left, surprises.
