---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Users can now have a nickname. Add an optional nickname column to the users table in db/schema.sql, and make greetUser greet a user by their nickname when they have one, falling back to their name. Nothing is deployed yet: db/schema.sql is applied fresh. Work on the current branch, feat/work.
