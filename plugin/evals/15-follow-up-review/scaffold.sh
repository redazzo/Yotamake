#!/usr/bin/env bash
# The fixture as the first turn in history.jsonl left it: case 13's change made,
# reviewed and reported, not committed.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/../_fixture/setup.sh" feat/work
git apply "$here/first-turn.patch"
