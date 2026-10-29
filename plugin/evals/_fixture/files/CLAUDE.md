# CLAUDE.md

## How to work here

Every change to code, tests or docs runs as a session, however small: use the
`yotamake:simple-session` skill. If the change will not fit one branch and one context, use
`yotamake:multi-session` instead. This holds when the user names the branch or spells out
the exact edit too: the skill covers working on a named branch, and its checks, doc update and
stop before commit still apply. Questions and explanations need no session.

## Project overview

Greeter: a tiny Node library. `greet(name)` is in `src/greet.js`; shared text helpers are in
`src/text.js`. Tests are in `test/`, run with Node's built-in test runner.

**Docs:** [docs/README.md](./docs/README.md) (index and the "Owns" table) ·
[docs/backlog.md](./docs/backlog.md) (open work)

## Commands

```bash
npm test    # run the tests
```

## Checks

**`scripts/check` is the one gate.** It runs the tests and the docs linter.

## Branching and releases

- **Main branch:** `main`. Work on branches cut from it.
- **Branch prefixes:** `feat/`, `fix/`, `refactor/`, `perf/`, `docs/`, `test/`, `chore/`.
- **Commits:** Conventional Commits, `type(scope): summary`.
- **Integration:** local `git merge --no-ff` into main.
- **Version bump:** code changes get `npm version patch --no-git-tag-version` as their own
  commit, `chore(release): bump version to X.Y.Z`. Docs-only branches do not.

## Conventions

**Trivial side-fix policy.** Fix trivial, side-effect-free issues you pass and note them.
Raise anything with behavioural reach first.

**One owner per subject.** A change in behaviour updates the doc that owns it (the "Owns"
table in `docs/README.md`) in the same branch.

## Architecture

The design every change follows. Before writing code, look in **Shared code** for something
to reuse or extend. A change that would cross a **Boundary**, go against an accepted ADR, or
bring in a way of doing things that **Patterns** does not list stops before any edit and is
raised with the user, whoever asked for it.

- **Modules:** `src/greet.js` the greeting; `src/text.js` shared text helpers.
- **Boundaries:** `src/` is pure: it never reads `process.env`, files, the network or the
  console. Input and output belong to the caller, which passes values in as arguments.
- **Shared code:** `src/text.js`.
- **Patterns:** named exports only; each function takes its inputs as arguments and returns a
  string; each `src/` file has a test file of the same name in `test/`.
- **Decisions:** accepted ADRs in `docs/decisions/` are part of the design.
