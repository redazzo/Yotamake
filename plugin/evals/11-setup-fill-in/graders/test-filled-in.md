---
type: regex
target: { source: file, path: "scripts/check" }
pattern: "^[^#\\n]*\\brun\\b[^\\n]*(npm (run )?test|node --test)"
flags: "m"
---
