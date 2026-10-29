#!/usr/bin/env bash
# Fixture with the exclamation-mark change already made and committed on main,
# so the record describes work that happened. Starts on a docs branch.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
sed -i 's/Hello, ${name}\./Hello, ${name}!/' src/greet.js
sed -i "s/'Hello, Ada\.'/'Hello, Ada!'/" test/greet.test.js
sed -i 's/returns `Hello, <name>.` — the name, ending with a full stop./returns `Hello, <name>!` — the name, ending with an exclamation mark./' docs/reference/greeting.md
git add -A
git -c user.name="Eval Fixture" -c user.email=eval@example.invalid commit -qm "feat(greet): end greetings with an exclamation mark"
git checkout -q -b docs/eval-work
