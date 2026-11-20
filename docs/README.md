# Documentation

Everything is one of four kinds, and the kind decides how it is maintained. Every document in
`docs/` is reachable from this page, and listed on it once.

| Kind | Directory | What it is | Update rule |
|---|---|---|---|
| **Reference** | [`reference/`](#reference) | How the system works **now** | Corrected in place; must be true at HEAD |
| **Guides** | [`guides/`](#guides) | How to do a thing | Corrected in place |
| **Decisions** | [`decisions/`](./decisions/README.md) | Why the system is built this way | Never edited — superseded by a later ADR, or given a dated amendment |
| **Records** | [`records/`](./records/README.md) | What was done, and when | Written once, never revised |

Plus [`backlog.md`](./backlog.md) for open work.

## When two documents disagree

**Code > decisions > reference > records.**

The code is the only thing that cannot be out of date. An ADR beats a reference doc because
it records a decision that was actually taken. A reference doc beats a record because a
record is a snapshot of a day that has passed. Where a record contradicts today's system, the
record is not wrong, it is history.

Every subject has **one** document that owns it (the table below). Anything else that
mentions the subject links here rather than restating it. Two documents explaining the same
thing is a bug in the docs.

An overview (the root `README.md`, an index, a landing page) owns what exists and how the
parts fit, never how a part works. It sums each part up in a line or two and links to the
document that owns it. When an overview section grows into a manual, move the detail to its
owner.

---

## Reference

How the system works today. If one of these disagrees with the code, the doc is wrong.

The root [README.md](../README.md), which every user reads first, owns the overview of the
harness: install, how it is split, how it holds, the docs system and the evals. It sums up
each hook in a line; how the hooks work is in [reference/hooks.md](./reference/hooks.md).
Each skill's rules are owned by its own `plugin/skills/<name>/SKILL.md`. The README sums up a
skill and links to it, rather than restating its rules.

The website in [`site/`](../site/index.html) is an introduction for new users. It owns no
subject: it sums up the README and the skills and links to them. The README's "Developing
Yotamake" section says how it is published and kept in step.

| Document | Owns |
|---|---|
| [reference/glossary.md](./reference/glossary.md) | Domain language: the harness's own words and what each means |
| [reference/hooks.md](./reference/hooks.md) | The hooks and `ask` rules: what each blocks, how the `Stop` and commit gates decide, and what gets past them |
| [reference/rules-and-enforcers.md](./reference/rules-and-enforcers.md) | Each rule in `CLAUDE.md` and what enforces it |
| [CHANGELOG.md](../CHANGELOG.md) | Release history: what changed in each version |

## Guides

Task recipes. Read the one that matches what you are doing.

- [guides/changing-the-harness.md](./guides/changing-the-harness.md) — keeping the
  repository in step when you change a project-owned template file, a `CLAUDE.md` section
  name, or a pointer between skills.

## Decisions

[**decisions/README.md**](./decisions/README.md) — the ADR register: the load-bearing,
hard-to-reverse choices, with the alternatives rejected and the trade-offs accepted.

## Records

[**records/README.md**](./records/README.md) — generated index of dated records. Regenerate it
with `node scripts/docs/generate-records-index.mjs` after adding one.

## Backlog

[**backlog.md**](./backlog.md) — **the** register of open engineering work. One `##` entry per
item, each with an **Added** date and a **Trigger to act**. Longer analysis goes in
`backlog/<slug>.md`, linked from the entry.

---

## Adding a document

1. **Decide the kind.** How something works → `reference/`. How to do something → `guides/`.
   A choice that constrains future work → `decisions/`. Work you did → `records/`. Something
   that needs doing → an entry in `backlog.md`.
2. **Check nothing already owns the subject.** If a reference doc covers it, extend that doc.
3. **Name it in kebab-case.**
4. **Link it from this page** — except records, whose index is generated.
5. **Run `node scripts/docs/lint-docs.mjs`.** It fails on a broken link or anchor, a stale
   records index, an inventory block that does not match the disk, or a document in `docs/`
   that nothing links to.

Every document carries `kind:` front-matter (`reference`, `guide`, `decision` or `record`),
plus `updated:` for reference and guides and `date:` for decisions and records. The linter
validates them. The `write-doc` skill has templates.

## Changing a document

| Kind | How it changes | Why |
|---|---|---|
| `reference/` | **Corrected in place**, `updated:` bumped | It describes the system now. A stale sentence is a bug. |
| `guides/` | **Corrected in place**, `updated:` bumped | A procedure that no longer works is simply wrong. |
| `decisions/` | **Never edited, only superseded or amended** | An ADR records a choice made on a date. Add one that supersedes it, or append a dated amendment. |
| `records/` | **Never revised** | A snapshot of a day that has passed. Promote it with a one-line `status:` edit, never a rewrite or a move. |

The one exception for records: a claim about what the system does *today* that has since
become false gets a short dated note, not a rewrite.
