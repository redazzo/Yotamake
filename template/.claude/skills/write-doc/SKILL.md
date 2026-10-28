---
name: write-doc
description: Add or change project documentation under docs/ using the four kinds (reference, guide, decision, record) plus the backlog — pick the kind, place and name the file, write its front-matter, link it, and run the docs linter. Use when writing a work record, an ADR, a backlog entry, or a reference or guide doc, or when a session needs to update the doc that owns a subject.
---

# Writing docs

`docs/README.md` is the rulebook and the index. Read its tables before adding anything. This
skill is the short form, plus the templates.

## 1. Pick the kind

| Writing about | Kind | Where | How it changes later |
|---|---|---|---|
| How the system works now | reference | `docs/reference/<name>.md` | Corrected in place, `updated:` bumped |
| How to do a task | guide | `docs/guides/<name>.md` | Corrected in place, `updated:` bumped |
| A choice that constrains future work | decision (ADR) | `docs/decisions/NNNN-<slug>.md` | Never edited; superseded or given a dated amendment |
| Work you did, and why | record | `docs/records/<year>/<YYYY-MM-DD>-<slug>.md` | Written once; only `status:` changes |
| Something that needs doing | backlog entry | a `##` entry in `docs/backlog.md` | Deleted when the work lands |

When two docs disagree: **code > decisions > reference > records.**

## 2. Check nothing already owns the subject

Search the "Owns" table in `docs/README.md`. If a reference doc covers the subject, extend it
rather than adding a second one. Two docs explaining the same thing is a bug.

## 3. Write it

Names are kebab-case. Every doc carries `kind:` front-matter, plus `updated:` (reference,
guides) or `date:` (decisions, records), as `YYYY-MM-DD`.

**Reference or guide**

```markdown
---
kind: reference            # or: guide
status: current
updated: YYYY-MM-DD
owns: [subject-one, subject-two]
---

# <Title>
```

Add a row for it to the "Owns" table (reference) or the guides list in `docs/README.md`.

**Record.** Date it when the work started. Use a directory with a `README.md` when the work
spans several documents. `status: current` while open, `historical` when complete.

```markdown
---
kind: record
date: YYYY-MM-DD
status: current
---

# <What was done>

**Date:** YYYY-MM-DD · **Status:** <open / live in <version or tag>>

<Why the work happened. What was built or fixed. What was decided and what was rejected.
What is left, with links to backlog entries.>
```

Then run `node scripts/docs/generate-records-index.mjs`. Never edit `docs/records/README.md`
by hand.

**Decision (ADR).** Ask the user before writing one. Number it one above the highest in
`docs/decisions/`. Use the template in `docs/decisions/README.md`, and add a row to that
file's index.

**Backlog entry.** One `##` heading per item in `docs/backlog.md`:

```markdown
## <Short title>

**Added:** YYYY-MM-DD · **Trigger to act:** <the observable condition that should make
someone pick this up>

<Enough to decide whether to open it. Longer analysis goes in docs/backlog/<slug>.md, linked
from here.>
```

An item with no trigger is a wish, not a backlog entry.

## 4. Lint

```bash
node scripts/docs/lint-docs.mjs
```

It fails on a broken link, a doc in `docs/` that nothing links to, bad front-matter, or a
stale records index. Fix every finding before reporting.
