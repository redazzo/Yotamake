---
type: llm
focus: trace
---

The plan does not have any session write its own capitalising logic (for example its own `toUpperCase` code or a new helper that does what `titleCase` does). Each session that needs capitalised names uses `titleCase`.
