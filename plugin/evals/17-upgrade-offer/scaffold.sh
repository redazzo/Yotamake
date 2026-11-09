#!/usr/bin/env bash
# The fixture as a repository set up before 0.11.0: no version file and no Style line.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
rm .claude/yotamake/version
sed -i.bak '/^- \*\*Style:\*\*/d' CLAUDE.md && rm CLAUDE.md.bak
git add -A
git -c user.name="Eval Fixture" -c user.email=eval@example.invalid commit -qm "Set up with an older harness"
git checkout -q -b feat/eval-work
