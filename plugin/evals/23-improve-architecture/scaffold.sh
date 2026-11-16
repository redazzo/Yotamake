#!/usr/bin/env bash
# The fixture, plus src/name.js: a module that only forwards to titleCase, and that
# the Architecture section's Modules line does not list. Two commits make greet.js and
# name.js the most-changed files.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"

commit() { git add -A && git -c user.name="Dev" -c user.email=dev@example.invalid commit -qm "$1"; }

cat > src/name.js <<'JS'
import { titleCase } from './text.js';

// Formats a user's name for display.
export function formatName(name) {
  return titleCase(name);
}
JS
cat > test/name.test.js <<'JS'
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatName } from '../src/name.js';

test('formatName title-cases the name', () => {
  assert.equal(formatName('ada LOVELACE'), 'Ada Lovelace');
});
JS
cat > src/greet.js <<'JS'
import { formatName } from './name.js';

// Returns the greeting shown to a user.
export function greet(name) {
  return `Hello, ${formatName(name)}.`;
}
JS
commit "feat: format the name in the greeting"

echo '// Used by greet.' >> src/name.js
echo '// The name is title-cased by formatName.' >> src/greet.js
commit "docs: say what the greeting does to the name"
