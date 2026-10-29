---
max_turns: 60
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add three new messages next to greet: farewell(name) returns "Goodbye, <name>.", welcomeBack(name) returns "Welcome back, <name>." and thanks(name) returns "Thank you, <name>.". All four, greet included, must capitalise the name properly, so "ada LOVELACE" becomes "Ada Lovelace". I want this run as several sessions, one message per session, with a /clear between them. Start with the planning session.
