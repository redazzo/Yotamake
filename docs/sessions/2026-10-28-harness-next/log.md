# Log

## 2026-10-28 — S0: analysis and planning

- Analysed Yotamake at `931b499` and video-vault at `7e7c1e3` against the improvement list
  from the review. Findings F1–F20 are in `findings.md`.
- Surprises that changed the plan:
  - Video-vault already has its own docs scripts, and its records index names them in its
    header, so installing the harness's copies would fail the docs check (F8). The installer
    needs an opt-out before video-vault can move (now S3, before S4).
  - Video-vault's CLAUDE.md has none of the section names the skills read (F9).
  - Video-vault explicitly allows `git commit` in its local settings, so the `ask` vs
    `allow` question (F2) decides whether its stop points work at all.
- Wrote `plan.md` (S1–S9) and `decisions.md` (D1–D10; D0 answered).
- Adapted the skill for a cloud session (folder committed, sessions as commits on the
  assigned branch). That gap is itself F15, fixed in S6.
- Next: S1.
