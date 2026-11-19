# Missing setup and tools

The `simple-session` skill sends you here ("Missing setup and tools") from the step where it
finds part of the project's setup missing, or a tool the review needs not available. A full
install with every section filled never needs this file; a lite install needs only "No docs
system".

## The project

- **Architecture unfilled.** The **Architecture** section of `CLAUDE.md` is missing or still
  holds `FILL IN` placeholders. In "Design and reuse", follow the structure and patterns
  already in the code. Say once in the report that the section is unfilled, and that
  `/yotamake:setup` can fill it in.
- **No `scripts/check`.** In "Run the checks", run the commands the **Checks** section of
  `CLAUDE.md` lists instead. Say in the report that the project has no single gate.
- **No docs system.** The repository has no `docs/README.md` (a lite install). In "Do the
  work", fix `CLAUDE.md` or `README.md` where they describe the change.
- **An empty gate.** `scripts/check` exists but has no checks yet. Say in the report that the
  gate is empty and that `/yotamake:setup` can add them.

## The review

These are only for a tool that is really not available, never for a diff that looks too
small to review. Say in the report which one was missing.

- **No `/simplify`.** Check reuse by hand: for each new function or block, search for code
  that already does the same, and reuse it.
- **No Agent tool.** Do the design read yourself: read the diff against the **Architecture**
  section and the accepted ADRs it touches, looking for the same conflicts the brief lists.
- **No `/code-review`.** Say so in the report and carry on.
