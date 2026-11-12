---
type: llm
focus: trace
---

The fix is in words() in src/text.js, so that it ignores extra spaces as its comment says (for example by splitting on runs of whitespace or dropping empty words). It is not only a guard in titleCase against an empty word, nor only a clean-up of spaces in greet, either of which would leave wordCount('Ada  Lovelace') returning 3.
