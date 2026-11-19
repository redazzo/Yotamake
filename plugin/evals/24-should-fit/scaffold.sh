#!/usr/bin/env bash
# The fixture plus a database schema and the code that reads its rows, committed on
# main, so the change touches a schema and other code (the old size tests called that
# too big; the new signals do not).
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
mkdir -p db
cat > db/schema.sql <<'SQL'
-- The database schema. It is applied fresh to a new database; there are no migrations yet.
CREATE TABLE users (
  id integer PRIMARY KEY,
  name text NOT NULL
);
SQL
cat > src/user.js <<'JS'
import { greet } from './greet.js';

// Greets a row from the users table (db/schema.sql).
export function greetUser(user) {
  return greet(user.name);
}
JS
cat > test/user.test.js <<'JS'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { greetUser } from '../src/user.js';

test('greets a user by name', () => {
  assert.equal(greetUser({ id: 1, name: 'Ada' }), 'Hello, Ada.');
});
JS
printf '\n`greetUser(user)` in `src/user.js` greets a row from the `users` table (`db/schema.sql`) by its name.\n' \
  >> docs/reference/greeting.md
node - <<'JS'
const fs = require("fs");
const p = "CLAUDE.md";
const old = "`src/text.js` shared text helpers.";
const s = fs.readFileSync(p, "utf8");
if (!s.includes(old)) throw new Error("Modules line not found");
fs.writeFileSync(p, s.replace(old, old.slice(0, -1) + "; `src/user.js` greets a user row; `db/schema.sql`\n  the database schema."));
JS
git add -A
git -c user.name="Dev" -c user.email=dev@example.invalid commit -qm "Add users schema"
git checkout -q -b feat/work
