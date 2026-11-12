#!/usr/bin/env bash
# The fixture with a typo in a comment, so the fix is a trivial change that
# simple-session runs without its review skills.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh"
sed -i.bak 's|^// Shared text helpers\.|// Shraed text helpers.|' src/text.js && rm src/text.js.bak
if ! grep -q '^// Shraed text helpers\.' src/text.js; then
  echo "scaffold: could not add the comment typo" >&2; exit 1
fi
git add -A
git -c user.name="Eval Fixture" -c user.email=eval@example.invalid commit -qm "Add a comment typo"
git checkout -q -b fix/eval-work
