#!/usr/bin/env bash
# Install the Yotamake harness into a project.
#
#   ./install.sh <target-repo> [--force]
#
# Copies everything under template/ into the target. Existing files are kept
# unless --force is given; each skipped file is listed so you can merge by hand.
# Also adds .scratchpad/ to the target's .gitignore.

set -euo pipefail

usage() { echo "usage: $0 <target-repo> [--force]" >&2; exit 1; }

[[ $# -ge 1 ]] || usage
target=$1
force=${2:-}
[[ -z "$force" || "$force" == "--force" ]] || usage
[[ -d "$target" ]] || { echo "not a directory: $target" >&2; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)/template"
target="$(cd "$target" && pwd)"
today=$(date +%Y-%m-%d)

copied=0
skipped=()
while IFS= read -r -d '' file; do
    rel=${file#"$src"/}
    dest="$target/$rel"
    if [[ -e "$dest" && "$force" != "--force" ]]; then
        skipped+=("$rel")
        continue
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
    copied=$((copied + 1))
done < <(find "$src" -type f -print0 | sort -z)

chmod +x "$target"/.claude/hooks/*.sh 2>/dev/null || true

# Date the backlog's front-matter, if we just wrote it.
if [[ ! " ${skipped[*]-} " =~ " docs/backlog.md " ]]; then
    sed -i.bak "s/^updated: .*/updated: $today/" "$target/docs/backlog.md" && rm -f "$target/docs/backlog.md.bak"
fi

gi="$target/.gitignore"
if ! grep -qxF '.scratchpad/' "$gi" 2>/dev/null; then
    printf '\n# multi-session working folders (Yotamake harness)\n.scratchpad/\n' >> "$gi"
    echo "added .scratchpad/ to .gitignore"
fi

echo "copied $copied file(s) into $target"
if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "kept ${#skipped[@]} existing file(s) — merge these by hand, or re-run with --force:"
    printf '  %s\n' "${skipped[@]}"
fi

cat <<EOF

Next steps:
  1. Fill in every FILL IN comment in CLAUDE.md (Checks, Branching and releases,
     Migrations, Deploying). Delete Migrations / Deploying if the project has none.
  2. Uncomment the lines in .claude/hooks/post-edit-checks.conf that fit the project.
  3. Check .claude/hooks/protected-paths.conf covers your secret files.
  4. Run: node scripts/docs/lint-docs.mjs
EOF
