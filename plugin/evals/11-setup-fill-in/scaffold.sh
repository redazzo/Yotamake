#!/usr/bin/env bash
# A small Node repository with the harness freshly installed and nothing filled
# in, on a working branch. The scaffold runs the installer because the eval
# sandbox keeps .claude/ read-only, and cuts the branch because the agent cannot
# write inside .git.
set -euo pipefail
git init -q -b main .
mkdir -p src test
cat > package.json <<'JSON'
{
  "name": "counter",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": { "test": "node --test" }
}
JSON
printf 'export function add(a, b) {\n  return a + b;\n}\n' > src/add.js
cat > test/add.test.js <<'JS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { add } from "../src/add.js";

test("adds", () => assert.equal(add(2, 3), 5));
JS
printf '# counter\n\nAdds numbers.\n' > README.md
git add -A
git -c user.name="Eval Fixture" -c user.email=eval@example.invalid commit -qm "Initial"
git checkout -q -b chore/yotamake-harness
bash "$(dirname "$0")/../_fixture/install-harness.sh"
