#!/usr/bin/env bash
# The fixture without its Docs-only line, so the run must use simple-session's
# default rule to decide that a CLAUDE.md-only branch is code.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
sed -i.bak '/^- \*\*Docs-only:\*\*/{N;d;}' CLAUDE.md && rm CLAUDE.md.bak
if grep -q '\*\*Docs-only:\*\*' CLAUDE.md || ! grep -q '^## Conventions' CLAUDE.md; then
  echo "scaffold: could not remove the Docs-only line cleanly" >&2; exit 1
fi
git add -A
git -c user.name="Dev" -c user.email=dev@example.invalid commit -qm "Drop the Docs-only line"
git checkout -q -b chore/work
