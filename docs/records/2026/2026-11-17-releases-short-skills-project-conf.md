---
kind: record
date: 2026-11-17
status: historical
---

# The second Medium backlog: changelog and tags, empty gate, case 23, short skills, project.conf

**Date:** 2026-11-17 · **Status:** open, on `feat/medium-backlog`; released as 0.35.0 when it
merges into `main` · **Before it:** [the first Medium backlog
effort](./2026-11-12-medium-backlog.md).

**Why.** Six backlog entries carried **Priority: Medium**: tag releases and keep a
changelog, an empty gate that still wrote the pass stamp, LLM judges failing case 23, skills
too long to keep in context, a facts file hooks can read, and session overhead on small
changes. They ran as one eight-session effort on autopilot, one commit per session on the
mother branch. Session overhead was left out (D1): its trigger needs the cost numbers of the
Δ run, which waits on the eval sandbox bug.

How it works now: [CHANGELOG.md](../../../CHANGELOG.md), `CLAUDE.md`, "Branching and
releases", [ADR-0008](../../decisions/0008-facts-hooks-read-in-project-conf.md), and in
[README.md](../../../README.md) "Claude cannot end a turn with unchecked code" and
"Developing Yotamake". This record holds what was built, in what order, and what was
decided on the way.

## What was built

| Step | Branch | Commit | What |
|---|---|---|---|
| S1 | `feat/medium-backlog` | `0ba9a90` | `CHANGELOG.md`, backfilled 0.11.3–0.34.1 with an `## Unreleased` section; `checkVersion()` in `scripts/consistency.mjs` fails when the version has no entry; CLAUDE.md Version bump writes the entry and Release tags `vX.Y.Z` from 0.35.0; `simple-session` does any after-merge step the release line lists; `ci.yml` runs weekly and on demand with `@latest` Claude Code, pushes keep the pin |
| S2 | `feat/medium-backlog` | `71b8317` | Both `scripts/check` copies write no pass stamp when no check ran, and print a note naming `/yotamake:setup`; `stop-check-ran.sh` says what to do then; `upgrades.md` entry; `simple-session` reports it |
| S3 | `feat/medium-backlog` | `d7e9636` | Case 23 graders `rating`, `drift` and `asks-which` became regexes on the final message; case 04 `guide-fixed` a regex on the guide file |
| S4 | `feat/medium-backlog` | `4807915` | `multi-session` "Autopilot" and "Running sessions in parallel" moved to `plugin/reference/autopilot.md` and `parallel-sessions.md` behind stub headings (312 to 193 lines). Also fixed S2's note, which `--staged` printed and which assumed an empty gate |
| S5 | `feat/medium-backlog` | `2a93551` | `simple-session` "Harness upgrades", "Findings not acted on" and "On yes" detail moved to `plugin/reference/harness-upgrades.md`, `findings-not-acted-on.md` and `integrate.md` (320 to 250 lines); consistency rule "skill length" fails a `SKILL.md` over 250 lines |
| S6 | `feat/medium-backlog` | `de14508` | ADR-0008, written Proposed and accepted by the user before S7 |
| S7 | `feat/medium-backlog` | `28eba10` | `read_fact` in `plugin/hooks/lib.sh`; `guarded_main_branch` and `post-edit-mark.sh` read `.claude/yotamake/project.conf`, falling back to `CLAUDE.md` and the default docs rule; `session-context.sh` and both `scripts/check` copies read `main-branch`; template and this repository's `project.conf`; `setup` fills it, `doctor` check 6 compares it; consistency rule "project conf"; `upgrades.md` entry |
| S8 | `feat/medium-backlog` | — | Close-out: this record, backlog, glossary |

Tests: `scripts/test-install.sh` checks that a full install writes the stamp, that a lite
install's empty gate does not, and that `--staged` stays quiet. `scripts/test-hooks.sh`
covers `project.conf` for the main-branch guard and the edit marker, the fallback without
it, and that the template conf gives the same answers as the built-in default.

## Decisions taken along the way

Under autopilot, D1–D9 took the recommended answer (`assumed`). The user answered D11 (one
paid run) and D12 (accept ADR-0008).

- **Changelog backfilled from 0.11.3, tags only from 0.35.0 (D2, D3).** Past tags can be
  added in one go if someone asks to pin an old version. The tag step lives in this
  repository's Release line; the skill only says to do what that line lists, so the
  template stays generic (D4).
- **One CI job, not two.** `/simplify` merged a separate `check-latest` job into the main
  one, which picks the Claude Code version by event.
- **An empty gate writes no stamp (D5)**, rather than keeping the stamp and only reporting
  it. The `Stop` hook then blocks once on each turn that edits code until checks exist.
- **Regexes instead of LLM judges for case 23 (D6).** The paid run ($0.90) passed the
  `rating` regex 3 of 3, while the judges still split on `drift` and `asks-which` though
  every message met them; those two became regexes as well. The judges' failure is not
  explained.
- **Stub headings for moved sections (D7)**, so every pointer and the step-refs check stay
  valid; a 250-line limit per `SKILL.md` (D8).
- **`project.conf` holds a copy, not the source (D9, ADR-0008).** `CLAUDE.md` stays the
  source for skills and people; only `main-branch` and `docs` are in the file; hooks fall
  back to today's parsing without it. Rejected: a fork-free reader (saves 1–2 ms per edit)
  and dropping the fallback.

## Changes from the plan

- S5 moved the whole of "On yes: commit, bump, integrate", not only the pull-request path:
  the named moves left `simple-session` at 277 lines, over the limit.
- S3's last regex changes were checked against saved messages, not by a second paid run.
- S4's review found and fixed a bug S2 introduced.

## What is left

- `simple-session` sits at 250 of 250 lines, and this repository's `CLAUDE.md` is still
  read whole — [backlog entry](../../backlog.md#keep-skills-short)
- Why the judges failed case 23 — [backlog
  entry](../../backlog.md#llm-judges-fail-case-23-on-text-that-meets-them)
- Session overhead on small changes, not started —
  [backlog entry](../../backlog.md#session-overhead-on-small-changes)
- Tag releases from CI — [backlog entry](../../backlog.md#tag-releases-from-ci)
- Keep the main-branch reader copies in step —
  [backlog entry](../../backlog.md#copies-of-the-main-branch-reader)
- No eval case was run after the changes except case 23 in S3; the gate names all of 01–23 as covering the effort.
