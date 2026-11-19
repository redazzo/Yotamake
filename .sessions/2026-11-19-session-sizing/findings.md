# Findings

Source of truth for why each task exists. Verify a cited line before editing it; code moves.
Lines as of commit `1a279cd`.

## The rule itself

**F1 — Sizing rests on context capacity (medium).** A session is "one branch and one merge
that fits in one context" (`plugin/skills/simple-session/SKILL.md:8`,
`plugin/skills/multi-session/SKILL.md:11`, `:108-110`, `docs/reference/glossary.md:45`).
Current models have large windows, automatic compaction, and subagents for reading, so this
seldom binds, and less so over time. What still holds (review size, revert, decision points,
durable state) is not named.

**F2 — The fixed tests measure structure, not size (medium).** `simple-session/SKILL.md:61-68`.
Schema plus code is often best together; two small interfaces can be small; a cross-package
rename is trivial. They block changes that fit and pass a large change inside one package.
`docs/backlog.md:335` records this and asked to collect misjudged cases first; the user chose
to act now.

**F3 — "You would want to `/clear`" is self-report (medium).** `simple-session/SKILL.md:68`.
Models are likely poorly calibrated on context use up front, and compaction removes the urge.

**F4 — "Needs an ADR" routes to multi-session (low).** `simple-session/SKILL.md:67`, and
`:134` sends a later ADR need back to step 1 after step 1 has passed. A decision gate, not a
size gate.

**F5 — No check partway through (medium).** Nothing in `simple-session` steps 3–7 re-checks
size. Autopilot's `PAUSE` trigger "cannot finish within its plan" (`plugin/reference/autopilot.md:65-67`)
is undefined, and the pause path (`:36-40`) cannot split a session in `plan.md`.

**F6 — No measured estimate (low).** The check is judged with no stated numbers, so misjudged
cases are never recorded.

## Wording copies

**F7 — The definition is restated in about ten places, in four wordings (low).**
`multi-session/SKILL.md:3,11,109`; `multi-session/templates/plan.md:3-4` (no "merge");
`CLAUDE.md:10`, `plugin/template/CLAUDE.md:14`, `plugin/evals/_fixture/files/CLAUDE.md:6`
("one branch and one context"); `README.md:128,322`; `site/how-it-works.html:62,75`;
`site/skills.html:45,53`; `site/get-started.html:114`; `plugin/reference/autopilot.md:8,34`.

**F8 — The site restates all five tests (medium).** `site/how-it-works.html:64`. The site owns
nothing (`docs/README.md:39`), so this goes stale silently.

## Constraints on the change

**F9 — The template `CLAUDE.md` is project-owned.** `plugin/install.sh:9-10,53-54`. A new line
needs an `upgrades.md` entry (`scripts/consistency.mjs:377-386`). Precedent for a line with a
filled default: `**Test-first:** \`no\`` (`plugin/template/CLAUDE.md:65`, upgrade entry
`plugin/reference/upgrades.md:109-114`). A bold line is not a `##` heading, so the `sections`
lint (`consistency.mjs:119-140`) does not require a heading for it.

**F10 — Doctor fails `FILL IN` in sections simple-session lists (medium).**
`plugin/skills/doctor/SKILL.md:53-56`. A new limit must have a filled default, not a `FILL IN`.

**F11 — Pointers to "Check the size".** By name: `plugin/reference/harness-upgrades.md:26-27`;
descriptive: `plugin/skills/spec/SKILL.md:83`, `plugin/skills/improve-architecture/SKILL.md:112`;
by number inside the skill: `simple-session/SKILL.md:54,134`. Keeping the heading name avoids
breaking them (`docs/guides/changing-the-harness.md`, "Pointers between skills").

**F12 — No hook deals with size (info).** `plugin/hooks/steps.json` has no threshold rule; a
size rule would be a new kind of rule under ADR-0010. `steps.mjs` `branchFiles` (`:113-127`)
counts files, not lines.

**F13 — Evals (info).** Case 03 (`plugin/evals/03-too-big/`) grades too-big with a prompt that
asks for SQLite, migrations, an HTTP API, a CLI and docs; it should still be too big under the
new signals (several parts that ship alone). No case asserts a borderline change that should
fit. A new case needs a row in `README.md:387-411` (`consistency.mjs:163-171`).

**F14 — ADRs.** No accepted ADR defines a session; ADR-0005, 0007 and 0009 rely on "one branch,
one merge" and the `/clear` between sessions, which the new definition keeps. The definition
sits in about ten files and drives a skill's gate, which arguably meets the ADR bar
(`docs/decisions/README.md:7-9`).
