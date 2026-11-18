#!/usr/bin/env bash
# PostToolUse hook for Edit/Write: record that Claude changed a file, for the step
# evaluator (steps.mjs, ADR-0010). It appends an edit event, marked as a doc or not, to
# yotamake-events in the edited file's git directory. Which files are docs: the docs globs in
# .claude/yotamake/project.conf, else the default Docs-only rule (files under docs/, and
# Markdown at the root other than CLAUDE.md). Git-ignored files, files outside a repository,
# and repositories whose scripts/check writes no stamp are left alone. It never blocks.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.

node "$here/steps.mjs" record edit >/dev/null 2>&1
exit 0
