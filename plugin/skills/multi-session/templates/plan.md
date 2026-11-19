# Plan

<N> sessions after S0. Clear context between them (marked ✂). Each session is one branch
(or, on an assigned branch, one set of commits), sized by `simple-session`, "Check the size".
Order: <why this order>.

Status values: `todo`, `in progress`, `done`, `skipped`.

## Design

<!-- For an effort that changes code. Agreed with the user before S1. Delete for a review or
  docs-only effort. Read CLAUDE.md's Architecture section and the ADRs first. -->

- **Style:** <the Architecture style the new parts follow, and how; or a change to it, with
  its ADR>
- **Modules touched:** <which modules change, and what each change is>
- **Reused:** <existing code to reuse or extend, and where it lives>
- **New:** <new interfaces, modules or shared code, and why nothing existing fits>
- **Boundaries and constraints at risk:** <Architecture boundaries, constraints or ADRs this
  work comes near, and how it keeps them; or "none">

---

## S0 — Analysis and planning — `in progress`

## S1 — <title> (<finding IDs>, <criterion IDs if there is a spec>) — `todo`

Branch: `<type>/<slug>` <!-- or "the assigned branch" in a committed setup -->
Needs: none <!-- or the sessions this one depends on, e.g. "S1, S2" -->

Ask <decision IDs> first.

1. Verify <finding> still holds (read <files>).
2. <task>
3. Update the docs that own what changed, and add this session's rows to `docs.md`.
4. `scripts/check` and the review, then propose commit, version bump (if the project uses
   one) and merge or pull request.

User involvement: <approvals, manual tests>.

✂ **Clear context.**
