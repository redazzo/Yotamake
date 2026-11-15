# Reference doc template

For `docs/reference/<name>.md`: how the system works now. Copy what is inside the fence.

~~~markdown
---
kind: reference
status: current
updated: YYYY-MM-DD
owns: [subject-one, subject-two]
---

# <Subject>

<!-- Keep the sections that fit the subject and drop the rest. The order below works for most. -->

<One or two sentences: what this doc covers. Then what it does not cover, with a link to the
doc that owns each of those subjects, e.g. "How it is deployed is in
[deploy.md](../guides/deploy.md); this doc does not repeat it.">

## <Subject> in one paragraph

<!-- The whole thing in one paragraph: the parts, how they talk, and the one or two facts a
newcomer must know. Name the ADR behind each load-bearing choice inline, e.g. "(ADR-0004)".
A small ASCII diagram of the parts and the arrows between them often helps. -->

```
   <part A>  ──calls──►  <part B>  ──writes──►  <store>
```

## How it works

<!-- One `##` per part or per step of the flow, in the order a request or a piece of data
moves through it. Name the real files, functions and types in `code`, so a reader can find
them. Prefer a table to a long list when the rows share columns. -->

## States and transitions

<!-- Only when the subject has state. Name each state, then give a transition table:

| From | Event | To | Side effects |
|---|---|---|---|

Every row is a fact you checked in the code. -->

## Worked example

<!-- Only for an algorithm or a protocol. Follow one concrete input through every step
above, with the real values at each step. -->

## Invariants

<!-- The rules that hold everywhere, numbered, each with why it matters and where the code
enforces it. A change that breaks one of these is a design change. -->

1. **<Rule in bold.>** <Why, and where the code enforces it.>

## Known gaps and concerns

<!-- Facts about what is missing, weak or inconsistent today. Say when you last checked:
"Checked against the code on YYYY-MM-DD." When a gap is fixed, rewrite or remove its
entry and say when it was fixed. Planned work does not go here; it goes in
docs/backlog.md, and this section links to the entry. -->

## Key files

| File | What it holds |
|---|---|
| `<path>` | <one line> |

## Where to go next

| You want | Read |
|---|---|
| Why it is built this way | [ADR-NNNN](../decisions/NNNN-<slug>.md) |
| To change or run it | [<guide>](../guides/<guide>.md) |
~~~
