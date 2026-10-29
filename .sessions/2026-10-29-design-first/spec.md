# Spec — Design first

Agreed 2026-10-29. What must be true when this work is done. One page at most.

## Problem

Yotamake controls process (branches, one gate, stop points, docs) but not design. Claude can
cross a module boundary, ignore an ADR or write a second copy of a helper, and nothing
catches it. The user wants the method driven by good architecture, design adherence and code
reuse, not by test-first.

## Scope

- A structured `Architecture` section in the template `CLAUDE.md`, read by name by the skills.
- A design-and-reuse step before code in `simple-session`, and a design check in its review.
- A design section in `multi-session` plans; `setup` fills in Architecture.
- Placeholders in `scripts/check` for boundary and duplicate-code checks.
- Two eval cases, the fixture to support them, README and version.

## Not in scope

- Bundling a boundary or duplicate-code tool. They stay project-chosen placeholders.
- A separate design skill (decided: fold into the existing skills).
- Removing tests from the method. Tests still change with the code.
- A hook that blocks boundary breaks on edit.

## Acceptance criteria

- **A1** — When `install.sh` runs on a new repo, its `CLAUDE.md` has an `## Architecture`
  section with `Modules`, `Boundaries`, `Shared code` and `Patterns` lines, and the header
  comment lists Architecture among the sections skills read.
- **A2** — When `/yotamake:setup` fills in facts, it proposes Architecture entries from the
  repo's layout, or leaves them `FILL IN` and lists them in the report.
- **A3** — When `simple-session` is about to write new code, it first looks for existing code
  that does the job (the `Shared code` places first), and reuses or extends it. The report
  has a "Reused:" line and a "New, because:" line.
- **A4** — When a change would cross a listed boundary, go against an accepted ADR, or bring
  in a pattern the `Patterns` line does not cover, `simple-session` stops before editing and
  asks, with options. It does this every time, whatever the user's wording.
- **A5** — If the Architecture section is missing or unfilled, `simple-session` says so once in
  the report and follows the structure and patterns already in the code.
- **A6** — When `simple-session` reviews a code change, it checks the diff against the
  boundaries, ADRs and patterns, and for duplicated logic, and fixes or reports each finding.
- **A7** — When `multi-session` starts an effort that changes code, `plan.md` has a Design
  section (modules touched, code reused, new interfaces, boundaries at risk), agreed with the
  user before S1.
- **A8** — The template `scripts/check` has commented placeholders for a boundary check and a
  duplicate-code check.
- **A9** — Eval cases `13-reuse` and `14-boundary` exist, `claude plugin validate` passes, and
  (with the user's yes to the cost) each passes at least 2 of 3 runs.
- **A10** — `README.md` describes the design method, the version is bumped in both manifests,
  and `install.sh` plus `scripts/check --all` pass on a scratch repo.
