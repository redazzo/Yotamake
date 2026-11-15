# Architecture Decision Records (ADRs)

This directory records the **architecturally significant decisions** behind the project: the
choices that are load-bearing, costly to reverse, and that constrain how the rest of the
system is built. Each ADR captures one decision, the alternatives considered, and the
trade-offs accepted, so future contributors can see which invariants are deliberate.

**The bar.** Write an ADR when reversing the choice later would mean touching many files,
migrating data, or breaking callers. A local implementation choice belongs in a record, not
here. Ask the user before writing one.

## Status legend

- **Accepted** — in force; the system is built this way today.
- **Superseded** — replaced by a later ADR. The old one stays.
- **Proposed** — under discussion.

An ADR is never edited to reflect a change of mind. It is superseded by a new one, or given a
dated amendment section at the end.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| — | _None yet._ | — |

## Template

File: `docs/decisions/NNNN-<kebab-slug>.md`, numbered one above the highest here. Add a row
to the index above. Start from the decision template of the `write-doc` skill
(`templates/decision.md` in the skill). It says how to supersede or amend an ADR later.

Older ADRs may have one `**Supersedes / amends:**` line. It means the same as the template's
separate **Supersedes** and **Amends** lines.
