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
  there. Move the open questions into that folder's `decisions.md`.
- Otherwise put it in `.scratchpad/<yyyy-mm-dd>-<slug>/spec.md`. That folder is git-ignored,
  so writing it needs no branch.

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

Run the size check from `simple-session`, step 1.

- **Fits one session:** run `simple-session`. Read `spec.md` first. Write a test for each
  criterion where the project has tests. In the report, list each criterion and how it was
  checked (test name, or the manual step).
- **Too big:** offer `multi-session`. Its folder keeps this `spec.md`, and its `plan.md` tasks
  cite the criteria each session delivers.

The spec does not outlive the work. When the work is done, behaviour that lasts goes into the
reference doc that owns it (or CLAUDE.md or `README.md` in a lite install). Then the spec is
deleted with its folder; ask before deleting it.
