# Findings

Source of truth for why each task exists. Verify a cited line before editing it; code moves.

## Architecture as a project fact

**F1 — The Architecture section is an empty placeholder (high).** `plugin/template/CLAUDE.md:121`
has `## Architecture` with one `FILL IN` comment and no structure. The comment at
`plugin/template/CLAUDE.md:6` lists the sections skills read by name, and Architecture is not
one of them. So no project ever records its modules, boundaries or shared code in a form a
skill can act on.

**F2 — No skill acts on architecture (high).** `plugin/skills/spec/SKILL.md:18` reads
Architecture "for context only". `simple-session` (`plugin/skills/simple-session/SKILL.md:63`,
step 3) says "Follow CLAUDE.md" and nothing about design, boundaries or ADRs before editing.
ADRs are only mentioned as something to write, not something to obey.

**F3 — `setup` does not fill in Architecture (medium).** `plugin/skills/setup/SKILL.md`,
step 2, fills Project overview, Commands and Branching only.

## Reuse discipline

**F4 — Nothing asks Claude to look for existing code first (high).** No skill or template
line mentions reuse or duplication (grep for `reuse|duplicat` finds nothing outside drawio).
Claude may write a second copy of a helper that already exists.

**F5 — The review looks for bugs only (medium).** `plugin/skills/simple-session/SKILL.md:90`,
step 5, runs `/code-review` at low effort. That looks for correctness bugs. Duplication, design
drift and boundary breaks go unchecked. The built-in `/simplify` covers reuse and
simplification, and applies its fixes.

**F6 — No gate can enforce design (medium).** `plugin/template/scripts/check` has placeholders
for type-check, lint and tests only. Boundary rules and duplicate code could be gates
(e.g. dependency-cruiser, import-linter, jscpd), but there is no slot for them.

## Planning

**F7 — Multi-session plans have no design step (medium).** `plugin/skills/multi-session/SKILL.md`,
"Starting a new effort", step 2, does analysis and the spec, then `plan.md`. Nothing records
which modules change, what is reused, or which boundaries are at risk before the sessions
are cut.

## Tests and docs

**F8 — No eval covers design or reuse (medium).** `plugin/evals/` has cases 01–12; none tests
reuse or boundaries. The fixture (`plugin/evals/_fixture/files/`) has one function and no
Architecture section, so there is nothing to reuse and no boundary to respect.

**F9 — TDD is not part of the method (info).** No skill says to write tests first.
`simple-session` only expects tests to change with the code; `spec` step 5 says "write a test
for each criterion". Nothing to remove.

**F10 — README lists the sections skills read (low).** `README.md:105` names five sections;
Architecture must be added, and "The three ideas" needs the design idea.
