---
name: write-doc
description: Add or change project documentation under docs/ using the four kinds (reference, guide, decision, record) plus the backlog — pick the kind, place and name the file, write its front-matter, link it, and run the docs linter. Use when writing a work record, an ADR, a backlog entry, or a reference or guide doc, or when a session needs to update the doc that owns a subject.
---

# Writing docs

`docs/README.md` is the rulebook and the index. Read its tables before adding anything. This
skill is the short form, plus the templates.

If the repository has no `docs/README.md`, it has no docs system (a lite install, or one
never set up). Say so and ask where the doc should go; do not create the skeleton yourself.

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
guides) or `date:` (decisions, records), as `YYYY-MM-DD`. The one exception is a backlog
detail doc (`docs/backlog/<slug>.md`), which has none: its entry in `docs/backlog.md` carries
the dates.

Start from the template for the kind, in `templates/` in this skill's directory:
`reference.md`, `guide.md`, `record.md`, `decision.md`, and `backlog-detail.md` for
`docs/backlog/<slug>.md`. Each holds the front-matter, the sections that usually fit, and a
comment under each heading saying what goes there. Copy what is inside its `~~~markdown` fence (the fence keeps the
placeholder links out of the docs linter). Drop the sections that do not fit, and delete
every comment before you save.

**Reference.** Add a row to the "Owns" table in `docs/README.md`. The glossary
(where the **Domain language** line of `CLAUDE.md` points; `docs/reference/glossary.md` by
default) has a format of its own: follow
`<this skill's directory>/../../reference/domain-language.md`.

**Guide.** Add it to the guides list in `docs/README.md`.

**Record.** Date it when the work started. Use a directory with a `README.md` when the work
spans several documents. `status: current` while open, `historical` when complete. Then run
`node scripts/docs/generate-records-index.mjs`. Never edit `docs/records/README.md` by hand.

**Decision (ADR).** Offer one only when all three hold:

1. **Hard to reverse:** changing it later costs real work.
2. **Surprising without context:** a future reader would ask why it was done this way.
3. **A real trade-off:** there were real alternatives, and one was chosen for a reason.

Ask the user before writing one. Number it one above the highest in `docs/decisions/`, and
add a row to the index in `docs/decisions/README.md`.

**Avoid**, in every kind:

- plans, roadmaps or "future enhancements" in a reference doc or a guide (they go in
  `docs/backlog.md`);
- a table of contents, emoji in headings, or "(added YYYY-MM-DD)" in a heading (Git
  holds the dates);
- a reference doc that tells the story of how the system got this way (that goes in a
  record).

**Backlog entry.** One `##` heading per item in `docs/backlog.md`:

```markdown
## <Short title>

**Added:** YYYY-MM-DD · **Trigger to act:** <the observable condition that should make
someone pick this up>

<Enough to decide whether to open it. Longer analysis goes in docs/backlog/<slug>.md, linked
from here.>
```

An item with no trigger is a wish, not a backlog entry. The entry must say enough on its
own to decide whether to read the detail doc. Delete the detail doc with the entry when the
work lands.

## 4. Lint

```bash
node scripts/docs/lint-docs.mjs
```

It fails on a broken link, a doc in `docs/` that nothing links to, bad front-matter, or a
stale records index. Fix every finding before reporting.
