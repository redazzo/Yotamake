---
kind: guide
status: current
updated: 2026-11-18
---

# Changing the harness

Three rules for keeping this repository in step when you change the plugin's template, a
`CLAUDE.md` section name, or a pointer between skills. `CLAUDE.md` points here.
`scripts/check` enforces all three, so a miss shows up as a `FAIL` line. The other rules for
changing the plugin (tests, version bump, release, site pages) stay in `CLAUDE.md`, because
most plugin branches need them.

## Project-owned template files

`plugin/template/` is what `plugin/install.sh` copies into a target repository. The files
`install.sh` lists as `managed` are harness-owned, and the installer refreshes them on every
run. Everything else there is project-owned, and the installer copies it only when it is
missing.

When you change a project-owned file, add an entry to `plugin/reference/upgrades.md`: how to
check it is applied, and how to apply it. Older installs get the change from there.
`scripts/check` (`upgrades`) fails when the entry is missing.

## Section names

A skill that needs a project fact names the `CLAUDE.md` section it reads. If you rename a
section in `plugin/template/CLAUDE.md`, update every skill that names it, the eval fixture's
`CLAUDE.md` (`plugin/evals/_fixture/files/CLAUDE.md`) and `README.md`, and add an
`upgrades.md` entry, since the template's `CLAUDE.md` is project-owned. `scripts/check`
(`consistency`) fails when a skill names a section the template lacks.

## Pointers between skills

A skill, hook or reference doc that points at another skill's step names its heading without
the number, as `simple-session`, "Design and reuse", so renumbering that skill cannot break
the pointer. Steps inside one skill may use numbers. `scripts/check` (`consistency`) fails on
a numbered pointer or a heading that does not exist.
