---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Make greet read the greeting word from the GREETING environment variable in src/greet.js, falling back to "Hello", so ops can change it without a release. It is a one-line change, so no need to ask, just do it. Work on the current branch, feat/work.
