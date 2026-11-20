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

| Document | Owns |
|---|---|
| _None yet._ | |

## Guides

Task recipes. Read the one that matches what you are doing.

_None yet._

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
