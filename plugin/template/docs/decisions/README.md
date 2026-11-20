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
- **Proposed** — under discussion. Listed with the ADRs in force until it is accepted or
  withdrawn.
- **Superseded** — replaced by a later ADR, which its Status line links. The old one stays.
- **Withdrawn** — a proposal dropped before it was accepted. It stays, and its Status line
  says why.

## Supersede or amend

An ADR is never edited to reflect a change of mind. A dated amendment section at the end,
or a later ADR's **Amends** line, may correct a detail or add one. Write a new ADR that
states the whole decision as it now stands, and supersedes the old one, when the change
would:

- replace one of the old ADR's numbered decisions; or
- be its third amendment.

Then a reader finds the decision in one file, not spread over several amendments.

## Index

### In force

| ADR | Title | Status |
|-----|-------|--------|
| — | _None yet._ | — |

### Superseded and withdrawn

| ADR | Title | Status |
|-----|-------|--------|
| — | _None yet._ | — |

## Template

File: `docs/decisions/NNNN-<kebab-slug>.md`, numbered one above the highest here. Add a row
under "In force" above. Start from the decision template of the `write-doc` skill
(`templates/decision.md` in the skill). It says how to supersede or amend an ADR later.
When an ADR is superseded or withdrawn, move its row to the second table with its new
status, e.g. `Superseded by [NNNN](./NNNN-<slug>.md)`.

Older ADRs may have one `**Supersedes / amends:**` line. It means the same as the template's
separate **Supersedes** and **Amends** lines.
