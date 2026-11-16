#!/usr/bin/env bash
# The fixture with a bug whose cause is one step away from where it shows. words()
# should ignore extra spaces but splits on single spaces, so two spaces in a row make
# an empty word. titleCase (called by greet) throws on it; wordCount silently counts it.
# A guard in titleCase hides the crash but leaves wordCount wrong: the cause is words().
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
cat > src/text.js <<'JS'
// Shared text helpers. Reuse these rather than writing new ones.

// Splits text into its words, ignoring extra spaces: "ada  lovelace" -> ["ada", "lovelace"].
export function words(text) {
  return text.split(' ');
}

// Capitalises the first letter of each word and lower-cases the rest, with one space
// between words: "ada LOVELACE" -> "Ada Lovelace".
export function titleCase(text) {
  return words(text)
    .map((word) => word[0].toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

// Counts the words in text.
export function wordCount(text) {
  return words(text).length;
}
JS
cat > src/greet.js <<'JS'
import { titleCase } from './text.js';

// Returns the greeting shown to a user, with the name in title case.
export function greet(name) {
  return `Hello, ${titleCase(name)}.`;
}
JS
sed -i.bak 's|returns `Hello, <name>.` — the name, ending|returns `Hello, <Name>.` — the name in title case, ending|' \
  docs/reference/greeting.md && rm docs/reference/greeting.md.bak
if ! grep -q 'title case' docs/reference/greeting.md; then
  echo "scaffold: could not update the greeting doc" >&2; exit 1
fi
if node -e "import('./src/greet.js').then(m => m.greet('Ada  Lovelace'))" 2>/dev/null; then
  echo "scaffold: the planted bug does not crash" >&2; exit 1
fi
git add -A
git -c user.name="Dev" -c user.email=dev@example.invalid commit -qm "Title-case names in greetings"
git checkout -q -b fix/work
