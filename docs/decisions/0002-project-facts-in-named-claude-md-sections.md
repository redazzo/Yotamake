---
kind: decision
date: 2026-11-09
status: current
---

# ADR-0002: Skills read project facts only from named CLAUDE.md sections

- **Status:** Accepted
- **Date:** 2026-11-09 (written after the fact; in force since the plugin's first release,
  2026-10-28)
- **Work record:** none
- **Supersedes / amends:** none

## Context

The plugin serves many repositories with different stacks, check commands, branch rules,
migration tools and deploy steps. The skills need those facts, but one plugin cannot hold
them. Yotamake started as skills inside one application project that had those
facts written into them.

This ADR records a choice already in the code and `README.md`. Most of the rationale is
inferred from them. One alternative was weighed on record: when the first project's
`CLAUDE.md` headings did not match what the skills read, the choice was to rename its
headings rather than teach every skill aliases (multi-session working folder
`docs/sessions/2026-10-28-harness-next/`, decision D3, since deleted).

## Decision

In the context of a generic plugin used by many projects, facing project facts that differ
per repository, we decided that the skills hold the method and read project facts only from
named sections of the repository's `CLAUDE.md` (Checks, Branching and releases, Migrations,
Deploying, Conventions, Architecture), and against facts in the skills, per-skill config
files, or heading aliases. A skill names the sections it reads in bold, and says what to do
when one is missing or still holds a `FILL IN` placeholder: use a stated default, or stop and
ask. It never guesses a deploy or migration command.

We accept that section names are an interface: renaming one is a breaking change.

## Consequences

- The plugin stays generic; anything specific to one stack goes in the target's `CLAUDE.md`
  or `scripts/check` as a `FILL IN` placeholder (`CLAUDE.md`, Architecture, Boundaries).
- Renaming a section in `plugin/template/CLAUDE.md` means updating every skill that names
  it, the eval fixture's `CLAUDE.md` and `README.md`, plus an `upgrades.md` entry.
  `scripts/consistency.mjs` checks that the names agree.
- One file holds every fact a person or Claude needs, and `/yotamake:setup` can propose the
  lines from the repository.

## References

- `plugin/template/CLAUDE.md`
- `scripts/consistency.mjs`
- [README.md](../../README.md), "The three ideas"
