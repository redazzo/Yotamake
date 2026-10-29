#!/usr/bin/env bash
# Re-records history.jsonl and first-turn.patch from one run of case 13-reuse.
# The history holds the simple-session text from when it was recorded, and a
# resumed run does not reload the skill, so re-record after changing the skill.
# Costs one eval run. Run from plugin/: bash evals/15-follow-up-review/record.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
before=$(ls -d /tmp/claude-eval-* 2>/dev/null || true)
claude plugin eval . --case 13-reuse --runs 1 --ablation none --scaffold --trust-plugin \
    --allow-tools Bash Write Edit --no-publish --keep-temp
tmp=$(comm -13 <(echo "$before") <(ls -d /tmp/claude-eval-*) | tail -1)
transcript=$(ls "$tmp"/config/projects/*/*.jsonl | head -1)
(cd "$tmp/home/cwd" && git diff) > "$here/first-turn.patch"
# Drop the user's email, which the environment adds to every session's context.
node - "$transcript" "$here/history.jsonl" <<'JS'
const fs = require("fs");
const [src, dest] = process.argv.slice(2);
const lines = fs.readFileSync(src, "utf8").trim().split("\n").map((s) => {
  const x = JSON.parse(s);
  if (x.attachment?.type === "session_context") {
    delete x.attachment.context.userEmail;
    for (const r of x.rendered || [])
      if (typeof r.content === "string") r.content = r.content.replace(/# userEmail\n[^\n]*\n/, "");
  }
  return JSON.stringify(x);
});
fs.writeFileSync(dest, lines.join("\n") + "\n");
JS
rm -rf "$tmp"
if grep -qi "email address is" "$here/history.jsonl"; then
    echo "history.jsonl still holds an email address; remove it before committing" >&2
    exit 1
fi
echo "recorded from $transcript; check the 13-reuse result above passed before committing"
