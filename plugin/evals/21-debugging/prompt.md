---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Users report that greet crashes when a name has two spaces in a row: greet('Ada  Lovelace') throws "TypeError: Cannot read properties of undefined (reading 'toUpperCase')". Can you fix it? Work on the current branch, fix/eval-work.
