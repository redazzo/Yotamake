---
name: spec
description: Agree what a new feature or behaviour change must do before any code is written — scope, non-goals and numbered acceptance criteria in one short spec.md — then hand over to simple-session or multi-session
disable-model-invocation: true
---

# Spec

A spec says what must be true when the work is done. It is one short file, agreed with the
user before any branch or edit. It is not a design: the plan and the code hold that. It may
end with a short list of tasks (step 3).

Use it for a new feature, or a change in behaviour where "done" is not yet clear. A bug fix,
a rename or a refactor does not need one. If the request is that small, say so and use
`simple-session` instead.

This skill needs no project command or rule, so it reads no `CLAUDE.md` section by name. It
reads **Project overview** and **Architecture** for context only; if they are unfilled, the
code answers instead. Whether the repository has a docs system is read from `docs/README.md`,
not from `CLAUDE.md`. The session it hands over to reads its own sections: its design step
checks the work against **Architecture**, so the spec does not repeat the design. If a
criterion could only be met by breaking a boundary, a constraint or an accepted ADR, raise that as a
question in step 2.

## 1. Read first

Read CLAUDE.md, the code the request touches, and the reference doc that owns the subject
(the "Owns" table in `docs/README.md`, if there is one). Do not ask what these already answer.

Read the glossary the **Domain language** line of the **Architecture** section names, if
it names one.

## 2. Ask, one question at a time

Ask only what changes what you build: who it is for, what is in and out, what happens on bad
input or failure. One question per message, each with your recommendation. Stop asking when
the answers would not change a criterion. If the user says to go ahead, record the rest as
open questions with your recommendation.

When the user uses a glossary word in another sense, or a vague word where a criterion
needs an exact one, make it the next question, by the rules in
`<this skill's directory>/../../reference/domain-language.md`. The criteria use the
glossary's words.

## 3. Write `spec.md`

Copy `../multi-session/templates/spec.md` (relative to this skill's directory) and fill it in.

Where it goes:

- If a `multi-session` folder for this work exists (`.scratchpad/` or `.sessions/`), put it
  there as `spec.md`, and move its open questions and **Tasks** out as `multi-session`,
  "Starting a new effort", says.
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
- Each one names its check: a test or a command that fails until the work is done. Use one
  manual step only where no command can see the result, and say why. When the check reads a
  value (a count, a size, a time, an output), write down the value it has now, so the check
  reads old against new.
- Cover the failure cases the user named, not every failure you can imagine.
- If something in the feature moves through states (an order, a job, an account), list the
  states and the allowed moves, each with its trigger. Write a criterion for each allowed
  move and for at least one move that is not allowed: "When <trigger> in <state>, …".
- More than about ten criteria means the work is probably several sessions. Say so.
- A term settled in step 2 that the glossary lacks goes under **Terms**, with its
  definition. Leave the section out when there are none.

**Tasks** are optional. Add them when the order of the work matters or the user asks for a
task list: a `## Tasks` section after the criteria, a short numbered list of steps, each
small enough to check and ending with the criteria it meets, e.g. `1. … (A1, A3)`. Every
criterion is met by some task.

## 4. Stop and ask

Show the user the spec, in full, and ask them to approve or change it. Do not branch or edit
code yet.

## 5. On approval: hand over

Run `simple-session`. Its size check decides whether the work fits one session; if not, it
offers `multi-session`, which moves the spec into its folder. In the session, make each
criterion's check a test where the project has tests; with `Test-first: yes`, each one comes
first (`simple-session`, "Do the work").

The spec does not outlive the work. When the work is done, behaviour that lasts goes into the
reference doc that owns it (or CLAUDE.md or `README.md` in a lite install), and its
**Terms** go into the glossary. Then the spec is deleted; ask before deleting it.
