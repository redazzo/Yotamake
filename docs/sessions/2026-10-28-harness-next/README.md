# Harness: next round of improvements — working memory

Started 2026-10-28. Carries out the improvement list from the 2026-10-28 review of the
Yotamake plugin (after commit `931b499`): enforcement gaps, CI for this repo, installer
fixes, moving an application project onto the plugin, skill changes, smaller fixes, evals and a
design for a stale-docs check.

**This folder is committed, not git-ignored.** The work runs in ephemeral cloud containers, so
a git-ignored `.scratchpad/` would not survive between sessions. It is deleted at close-out,
as the skill says. Workflow: `plugin/skills/multi-session/SKILL.md`.

**Branches.** Yotamake sessions are separate commits on the assigned branch
`ccr-d55bc34c-zz3j4j`, not one branch per session. Video-vault sessions need a branch in that
repository (D4).

The user resumes with: **"Read docs/sessions/2026-10-28-harness-next/README.md and start the
next session."**

## Files

- `plan.md` — sessions, their tasks, status, and where to clear context.
- `findings.md` — what the analysis found, with file:line references. Why each task exists.
- `decisions.md` — questions for the user and their answers. Check before asking again.
- `log.md` — one entry per session: what was done, commits, what is left, surprises.
