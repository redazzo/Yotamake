# Guide template

For `docs/guides/<name>.md`: how to do one task. Copy what is inside the fence.

~~~markdown
---
kind: guide
status: current
updated: YYYY-MM-DD
---

# <Do the task, as a verb phrase>

<!-- A guide is a recipe for one task. How the system works belongs in a reference doc, so link
to it rather than explaining it here. -->

<One sentence: what this guide gets you, and when to use it. Then what it owns and what it
leaves to other docs, with links, e.g. "What a deploy does is in
[deployment.md](../reference/deployment.md); this guide is only the steps.">

## Before you start

<!-- Tools with versions, accounts, access and files the reader needs. Give a command that
checks each one when there is one. Mark one-time setup as "first time only". -->

- <Tool, version> — check with `<command>`

## Steps

<!-- Numbered steps, one action each. Each step gives the exact command to run in a fenced
block, says where to run it from, and says what success looks like. Steps the reader skips
in some cases say so at the start ("First time only:", "If you changed the schema:"). -->

### 1. <Action>

```bash
<command>
```

<What the output should show.>

## Check it worked

<!-- The command or page that proves the task is done, and the output to expect, copied
from a real run. -->

## Undo it

<!-- How to roll back or clean up, when the task changes something shared. Drop this
section when there is nothing to undo. -->

## Troubleshooting

<!-- One `###` per symptom. Put the exact error message in the heading, in quotes, so a
reader can search for it. Under it: the cause, then the fix. -->

### "<exact error message>"

<Cause.> <Fix.>

## Related docs

- [<doc>](<path>) — <what it adds>
~~~
