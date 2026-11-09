---
kind: decision
date: 2026-11-09
status: current
---

# ADR-0003: Stop points are enforced by permission ask rules

- **Status:** Accepted
- **Date:** 2026-11-09 (written after the fact; in force since 2026-10-28)
- **Work record:** none
- **Supersedes / amends:** none

## Context

The method says Claude stops and asks before commit, version bump, merge and deploy. A skill
can say so, but a skill may not fire, and its text can lose to a user's "don't ask" or to a
long context. The stop points guard the actions that are hard to undo or reach other people.

This ADR records a choice already in the installer's settings and `README.md`. The rationale
is inferred from them, except where a test is cited.

## Decision

In the context of keeping a person in the loop before outward-facing git actions, facing
skills that are only instructions, we decided to enforce the stop points with Claude Code
permission rules, and against relying on the skills alone. The installer merges `ask` rules
for `git commit`, `merge`, `push`, `rebase`, `reset --hard` and `tag` into the repository's
`.claude/settings.json`, so Claude Code asks every time, whatever a skill says. Projects add
their deploy command to the same list.

This rests on `ask` winning over a matching `allow` rule, including a broad one such as
`Bash(git:*)` and one from a higher-priority settings source. That was tested on 2026-10-28
with Claude Code 2.1.312.

We accept an approval prompt on every commit and push, and that the rules match command
text, so other commands with the same effect are covered only by the rule in `CLAUDE.md`,
Conventions, not to work around them.

## Consequences

- A stop point holds even when no skill fired.
- The guarantee depends on Claude Code's permission precedence; a change there would need
  re-testing.
- Skills and `CLAUDE.md` tell Claude not to use other commands to the same effect, since the
  rules cannot catch every form.

## References

- `plugin/install.sh` (settings merge)
- [README.md](../../README.md), "Stop points are enforced, not just asked for" and "What the
  hooks do not cover"
