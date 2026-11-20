---
kind: record
date: 2026-11-20
status: historical
---

# Catching docs drift

**Date:** 2026-11-20 · **Status:** done on the mother branch `feat/docs-drift`; released as
0.40.0 on merge · **Design:** no new ADR. ADR-0010 is unchanged: docs-only branches still
need no review skill.

The README had grown into a reference manual and `plugin/README.md` had gone stale (it named
10 of 11 skills and three hooks), and every check stayed green: the docs linter checked
structure, not content, and docs-only branches got no review. Every repository on the
harness had the same gap. It ran as a multi-session effort on autopilot: S0 planned it, S1 to
S5 did the work on one mother branch, with one commit for the whole effort at the end (D5).

How it works now: the docs linter's header comment
(`plugin/template/scripts/docs/lint-docs.mjs`) for `broken-anchor` and `inventory`;
[`simple-session`](../../../plugin/skills/simple-session/SKILL.md), "Review", for the fit
read; [`write-doc`](../../../plugin/skills/write-doc/SKILL.md) for overviews and changing an
ADR; [docs/decisions/README.md](../../decisions/README.md) for the ADR lifecycle;
[hooks.md](../../reference/hooks.md) for the hooks. This record holds what was built, in what
order, and what was decided on the way.

## What was built

| Step | Branch | Commit | What |
|---|---|---|---|
| S0 | `feat/docs-drift` | — | Analysis (findings F1–F8), spec A1–A7, plan S1–S4 |
| S1 | `feat/docs-drift` | — | Docs linter rules `broken-anchor` (a `#fragment` into a `.md` file or the same page must name a heading slug or an HTML `id`/`name`) and `inventory` (`<!-- inventory: <glob> … -->` blocks compared with disk both ways); `scripts/test-install.sh` cases; `upgrades.md` 0.40.0 entry; `write-doc` step 4, both `docs/README.md`, README "Docs", site pages. The new rule found two dead backlog anchors in records, now plain text |
| S2 | `feat/docs-drift` | — | `simple-session`: a docs-only branch gets a fit read in "Review" and reports it. `write-doc` "Overviews" and an overview paragraph in both `docs/README.md`: an overview owns what exists and how it fits, not how a part works. Glossary "Fit read", `rules-and-enforcers.md` rows, eval 04 grader `fit-read-reported.md` |
| S3 | `feat/docs-drift` | — | The README's plugin and repository trees wrapped in inventory blocks; `plugin/README.md` names all 11 skills and 9 hook scripts, in inventory blocks |
| S4 | `feat/docs-drift` | — | Hook mechanics moved, not rewritten, from the README's "The three ideas" into new `docs/reference/hooks.md`. The README section became "How it holds": three short idea paragraphs and a guard table linking `hooks.md`. Owns table: the README owns the overview only |
| S5 | `feat/docs-drift` | — | ADR lifecycle: supersede instead of a third amendment or a changed numbered decision; a **Withdrawn** status; the index split into "In force" and "Superseded and withdrawn" (this repository and the template); `scripts/consistency.mjs` rule `adr index` |
| Close-out | `feat/docs-drift` | — | This record, two backlog entries, ledger check |

Tests: `scripts/test-install.sh` checks that the linter fails a broken anchor (in another
file and in its own) and checks an inventory block both ways. The `adr index` rule was shown
failing on five mismatches in a scratch copy, and passing on a stub ADR-0012. Eval case
`04-docs-only` covers the fit read; it was not run (it costs money).

## Decisions taken along the way

D0, D5 and D6 are the user's answers. Under autopilot, D1–D4 took the recommended answer
(`assumed`), for the user to confirm with the report.

- **Autopilot (D0, user)**, with one commit for the whole effort and one review on the
  whole diff after close-out (D5, user). The skill change for that runs on its own branch,
  `fix/autopilot-one-commit`.
- **What counts as an extra name in an inventory block (D1, assumed).** A token whose shape
  the glob's last part fits (same extension, or a trailing `/`) is a claimed name, and fails
  when it is not on disk. A `names` flag compares bare backticked names. S1 added: several
  globs per block; parent folders and siblings are not extras; a bare `*` file glob skips
  the extra-name check.
- **Refreshed repositories with broken anchors see `docs` fail (D2, assumed).** The anchors
  really are broken; `upgrades.md` says fix them or record them once with
  `--update-baseline`.
- **The fit read is an instruction, not a gate (D3, assumed).** A gate would need a judgment
  no hook can make, and ADR-0010 keeps docs-only branches free of review skills.
- **The trimmed README section is "How it holds" (D4, assumed).**
- **S5 added at the user's request (D6, user).**

## Changes from the plan

- S5 (ADR lifecycle, A8 and A9) was not in the first plan; the user added it.
- S2 added an eval grader for the fit read, beyond the plan.
- Per-session commits, reviews and bumps became one of each at the end (D5).
- `simple-session` is at 253 lines, past its 250-line target.

## What is left

- ADR-0012, on `fix/autopilot-one-commit`, supersedes ADR-0007 and ADR-0009. Whichever of
  the two branches merges second moves both rows to "Superseded and withdrawn"; `adr index`
  fails until then.
- Run eval case `04-docs-only` — the user decides (it costs money).
- An inventory name can be matched by prose in the same block —
  [backlog entry](../../backlog.md#inventory-names-found-in-prose)
- Docs linter line numbers skip the front-matter —
  [backlog entry](../../backlog.md#docs-linter-line-numbers-skip-the-front-matter)
