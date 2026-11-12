---
type: llm
---

The final message names the root cause: words() in src/text.js splits on single spaces, so two spaces in a row give an empty word, which titleCase then fails on. It also names the test that failed before the fix.
