---
type: regex
target: { source: file, path: "docs/guides/running-tests.md" }
---
^(?=[\s\S]*npm test\b)(?=[\s\S]*updated: \d{4}-\d{2}-\d{2})(?![\s\S]*test:all)(?![\s\S]*updated: 2026-01-01)
