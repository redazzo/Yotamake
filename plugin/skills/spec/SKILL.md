---
name: spec
description: Agree what a new feature or behaviour change must do before any code is written — scope, non-goals and numbered acceptance criteria in one short spec.md — then hand over to simple-session or multi-session
disable-model-invocation: true
---

# Spec

A spec says what must be true when the work is done. It is one short file, agreed with the
user before any branch or edit. It is not a design and not a task list: the plan and the code
hold those.

Use it for a new feature, or a change in behaviour where "done" is not yet clear. A bug fix,
a rename or a refactor does not need one. If the request is that small, say so and use
`simple-session` instead.

## 1. Read first

Read CLAUDE.md, the code the request touches, and the reference doc that owns the subject
(the "Owns" table in `docs/README.md`, if there is one). Do not ask what these already answer.

## 2. Ask, one question at a time

Ask only what changes what you build: who it is for, what is in and out, what happens on bad
input or failure. One question per message, each with your recommendation. Stop asking when
the answers would not change a criterion. If the user says to go ahead, record the rest as
open questions with your recommendation.

## 3. Write `spec.md`

Copy `../multi-session/templates/spec.md` (relative to this skill's directory) and fill it in.

Where it goes:

- If a `multi-session` folder for this work exists (`.scratchpad/` or `.sessions/`), put it
  there as `spec.md`. Move the open questions into that folder's `decisions.md`.
- Otherwise it is a standalone spec: a single file named `spec-<yyyy-mm-dd>-<slug>.md`, not a
  folder, so it is never mistaken for a multi-session effort. Use the same rule as
  `multi-session` for where:
  - **Local** (the default): `.scratchpad/spec-<yyyy-mm-dd>-<slug>.md`. It is git-ignored,
    so writing it needs no branch.
  - **Committed**, when the work runs in an ephemeral environment (such as a cloud
    container) or the environment assigns a branch: `.sessions/spec-<yyyy-mm-dd>-<slug>.md`
    on that branch. When you stop for approval, also ask whether to commit and push it, so
    a later session can find it.

Rules for the criteria:

- Number them A1, A2, … Each one is a single observable result: "When <trigger>, <the system>
  <does what>." No implementation detail.
- Each one can be checked by a test or by one manual step.
- Cover the failure cases the user named, not every failure you can imagine.
- More than about ten criteria means the work is probably several sessions. Say so.

## 4. Stop and ask

Show the user the spec, in full, and ask them to approve or change it. Do not branch or edit
code yet.

## 5. On approval: hand over

Run `simple-session`. Its size check decides whether the work fits one session; if not, it
offers `multi-session`, which moves the spec into its folder. In the session, write a test
for each criterion where the project has tests.

The spec does not outlive the work. When the work is done, behaviour that lasts goes into the
reference doc that owns it (or CLAUDE.md or `README.md` in a lite install). Then the spec is
deleted; ask before deleting it.
