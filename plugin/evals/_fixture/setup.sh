#!/usr/bin/env bash
# Builds the eval fixture in the current directory: a tiny Node project with the
# Yotamake harness installed and its facts filled in, committed on main.
# Each case's scaffold.sh calls this. Needs bash, git and node.
#
#   setup.sh [branch]   with a branch name, also creates and checks it out, so the
#                       case starts on an assigned working branch.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

git init -q -b main . 2>/dev/null || true
bash "$here/install-harness.sh"

cp -R "$here/files/." .
sed -i.bak 's|^# full && run tests  pnpm run test --run|run tests npm test|' scripts/check && rm scripts/check.bak
grep -q '^run tests npm test' scripts/check
node - <<'JS'
const fs = require("fs");
const p = "docs/README.md";
let s = fs.readFileSync(p, "utf8");
s = s.replace("| _None yet._ | |", "| [greeting.md](./reference/greeting.md) | The greeting format and the `greet` function |");
s = s.replace("Task recipes. Read the one that matches what you are doing.\n\n_None yet._",
              "Task recipes. Read the one that matches what you are doing.\n\n- [running-tests.md](./guides/running-tests.md) — run the test suite");
fs.writeFileSync(p, s);
JS

git add -A
git -c user.name="Eval Fixture" -c user.email=eval@example.invalid commit -qm "Initial fixture"

# The eval sandbox does not let the agent write inside .git, so a case that needs
# work to happen starts on a branch made here.
if [[ $# -ge 1 ]]; then git checkout -q -b "$1"; fi
