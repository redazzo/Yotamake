# Record template

For `docs/records/<year>/<YYYY-MM-DD>-<slug>.md`: what was done, and why. Copy what is inside the fence.

~~~markdown
---
kind: record
date: YYYY-MM-DD
status: current
---

# <What was done>

<!-- How a record may change later: `docs/README.md`, "Changing a document". -->

**Date:** YYYY-MM-DD<, or a range: YYYY-MM-DD to YYYY-MM-DD> · **Status:** <open / merged
into `<main branch>` (<version>) / live in <version or tag>>
<**Design:** [<spec or backlog detail doc>](<path>).> <**Before it:** [<earlier record in
the same effort>](<path>).>

<Why the work happened: the problem or the request, in two or three sentences.>

How it works now: [<reference doc, section>](<path#anchor>). This record holds what was
built, in what order, and what was decided on the way.

## What was built

<!-- One row per session, branch or step. For a single-branch change, a short list of the
changes is enough. -->

| Step | Branch | Commit | What |
|---|---|---|---|
| 1 | `<branch>` | `<short hash>` | <files, functions, routes, migrations> |

Tests: <which test files cover it and what they check>.

## Decisions taken along the way

<!-- Each choice made during the work, in bold, then why, and what was rejected. A choice
that constrains future work and is costly to reverse needs an ADR as well. Ask first. -->

- **<Choice.>** <Why, and the option rejected.>

## Changes from the plan

<!-- Where the result differs from the spec or the design, and why: hands-on testing, a
finding, the user's request. Drop this section when nothing changed. -->

## What is left

<!-- Every open item links to its entry in docs/backlog.md. "Nothing" is a fine answer. -->

- <Item> — [backlog entry](../../backlog.md#<anchor>)
~~~
