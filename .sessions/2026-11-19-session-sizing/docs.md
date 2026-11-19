# Docs ledger

Every change a durable doc must reflect, logged by the session that made it. Close-out
works through this file; nothing here may be left `open` when the folder is deleted.

Status values: `done` (the doc was changed in that session), `open` (still to do; say who
does it), `none` (checked; no doc needs it, and why).

## Changes

| Session | What changed | Doc that owns it | Status |
|---|---|---|---|
| S1 | New session definition decided: review, revert, decisions; context as backstop; signals; limit as project fact; mid-session stop; ADR first | `docs/decisions/0011-session-sized-by-review-revert-and-decisions.md` (Proposed; user accepts at the end) | done |
| S1 | ADR index gains 0011 | `docs/decisions/README.md` | done |
| S1 | ADR-0011 status Proposed → Accepted once the user accepts it | `docs/decisions/0011-…` and `docs/decisions/README.md` | open (close-out) |
| S2 | New `**Session size:**` line (default about 400 changed lines or 15 files) in **Branching and releases**; "How to work here" points to `simple-session`, "Check the size" (D7) | `plugin/template/CLAUDE.md`, `CLAUDE.md`, `plugin/evals/_fixture/files/CLAUDE.md` | done |
| S2 | Older installs get the line and the wording | `plugin/reference/upgrades.md` (0.38.0 entry) | done |
| S2 | Installer test checks the installed line | `scripts/test-install.sh` | done |
| S2 | Site lists what **Branching and releases** holds | `site/get-started.html` | done |
| S2 | README names the `Session size` line where it names `Worktree setup` and `Docs-only` | `README.md` | open (S6) |
| S2 | Doctor: no change; the filled default has no `FILL IN`. A repository whose version is older than 0.38.0 and lacks the line fails step 2 (pending upgrade), as for any pending entry | `plugin/skills/doctor/SKILL.md` | none |
| S2 | Template "Work that spans several contexts" convention still sizes by context | `plugin/template/CLAUDE.md` | done (S4) |
| S2 | `/yotamake:setup` keeps the line's default unless the user names another | `plugin/skills/setup/SKILL.md` | done |
| S2 | Changelog line for the new line and wording | `CHANGELOG.md` (`## Unreleased`) | done |
| S3 | Session definition (review, revert, decisions; context as backstop) at the top and in the description; "Check the size" rewritten: one-line estimate, `Session size` limit with its default, A2 signals, ADR first; "Stop partway" in "Do the work"; estimate beside real size in the report | `plugin/skills/simple-session/SKILL.md` | done |
| S3 | Glossary "Session" uses the new definition and points to the skill | `docs/reference/glossary.md` | done |
| S3 | Lite-install docs path moved out of `simple-session` to stay under the 250-line cap | `plugin/reference/missing-setup.md` | done |
| S3 | Changelog line for the new size check and the stop partway | `CHANGELOG.md` (`## Unreleased`) | done |
| S3 | README and site still state the old definition and the five fixed tests | `README.md`, `site/how-it-works.html`, `site/skills.html`, `site/get-started.html` | open (S6) |
| S3 | `multi-session` and autopilot still size by context and pause on "cannot finish within its plan"; they should point at "Check the size" and the stop partway | `plugin/skills/multi-session/SKILL.md`, `plugin/reference/autopilot.md` | done (S4) |
| S4 | `multi-session`: description and definition use the new session definition; S0 step 4 sizes sessions by `simple-session`, "Check the size", not by context | `plugin/skills/multi-session/SKILL.md` | done |
| S4 | `plan.md` template's opening line uses the new definition | `plugin/skills/multi-session/templates/plan.md` | done |
| S4 | Autopilot pauses on "Stop partway" signals instead of "cannot finish within its plan"; on a size pause, after the user agrees, the main conversation splits the session in `plan.md` | `plugin/reference/autopilot.md` | done |
| S4 | Template **Conventions** "Work that spans several contexts" → "Work too big for one session" (not in the fixture or this repository's `CLAUDE.md`); upgrade step | `plugin/template/CLAUDE.md`, `plugin/reference/upgrades.md` (0.38.0) | done |
| S4 | Changelog line for multi-session sizing and autopilot pauses | `CHANGELOG.md` (`## Unreleased`) | done |
| S4 | Pointers to "Check the size" (`harness-upgrades.md`, `spec`, `improve-architecture`) still read true | — | none |
| S4 | ADR-0007's pause on "cannot finish within its plan" now has named triggers and a split path; ADR-0011 already says so ("Builds on") | `docs/decisions/0011-…` | none |
| S4 | README skill tree still says `multi-session` is "work across several contexts" (`README.md:129`) | `README.md` | open (S6) |

## Renames and removals

Old names that docs may still use. Close-out greps `docs/` and CLAUDE.md for each one.

| Session | Old name | New name, or "removed" |
|---|---|---|

## For close-out

- **Record:** —
- **Backlog:** the commit gate's review window restarts at each stop-hook message, which counts as a user prompt (S3; trigger: it forces a re-review again). middle tier between simple-session and multi-session (D0). Size warning hook (D3): a non-blocking PostToolUse warning when the diff passes the
  `Session size` limit; trigger: reports show sessions that passed the limit without the
  skill's "Stop partway" firing (a new kind of rule under ADR-0010).
- **ADR candidates:** the session definition (S1, D1).
