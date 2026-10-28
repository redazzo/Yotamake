#!/usr/bin/env bash
# Set up a repository for the Yotamake harness, or refresh one already set up.
#
#   install.sh <target-repo> [--force]
#
# The method (skills, hooks, output style) comes from the yotamake plugin. This
# script installs the files each repository keeps for itself, from template/:
#
#   Project-owned  CLAUDE.md, scripts/check, docs/, .claude/yotamake/*.conf, CI workflow.
#                  Copied only when missing (--force overwrites). Yours to edit.
#   Harness-owned  scripts/docs/*.mjs, .githooks/pre-commit.
#                  Always refreshed, so re-running this script updates them.
#   Merged         .claude/settings.json: the harness's marketplace, plugin and
#                  permission entries are added to whatever is already there.
#
# Also adds .scratchpad/ to .gitignore and points git at .githooks/.

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

managed=(scripts/docs/lint-docs.mjs scripts/docs/generate-records-index.mjs .githooks/pre-commit)
is_managed() { local f; for f in "${managed[@]}"; do [[ "$1" == "$f" ]] && return 0; done; return 1; }

copied=()
refreshed=()
skipped=()
while IFS= read -r -d '' file; do
    rel=${file#"$src"/}
    dest="$target/$rel"
    [[ "$rel" == .claude/settings.json ]] && continue
    if is_managed "$rel"; then
        if [[ -e "$dest" ]] && cmp -s "$file" "$dest"; then continue; fi
        [[ -e "$dest" ]] && refreshed+=("$rel") || copied+=("$rel")
    elif [[ -e "$dest" && "$force" != "--force" ]]; then
        skipped+=("$rel")
        continue
    else
        copied+=("$rel")
    fi
    mkdir -p "$(dirname "$dest")"
    cp -p "$file" "$dest"
done < <(find "$src" -type f -print0 | sort -z)

# Merge settings.json: add the harness's entries, keep everything else.
mkdir -p "$target/.claude"
python3 - "$src/.claude/settings.json" "$target/.claude/settings.json" <<'EOF'
import json, os, sys
src_path, dest_path = sys.argv[1], sys.argv[2]
ours = json.load(open(src_path))
theirs = json.load(open(dest_path)) if os.path.exists(dest_path) else {}
before = json.dumps(theirs, sort_keys=True)
for key in ("extraKnownMarketplaces", "enabledPlugins"):
    theirs.setdefault(key, {})
    for k, v in ours[key].items():
        theirs[key].setdefault(k, v)
perms = theirs.setdefault("permissions", {})
for kind in ("allow", "ask"):
    have = perms.setdefault(kind, [])
    for rule in ours["permissions"][kind]:
        if rule not in have and rule not in perms.get("deny", []):
            have.append(rule)
if json.dumps(theirs, sort_keys=True) != before:
    with open(dest_path, "w") as f:
        json.dump(theirs, f, indent=2)
        f.write("\n")
    print("merged harness entries into .claude/settings.json")
EOF

chmod +x "$target/scripts/check" "$target/.githooks/pre-commit" 2>/dev/null || true

# Date the backlog's front-matter, if we just wrote it.
if [[ " ${copied[*]-} " == *" docs/backlog.md "* ]]; then
    sed -i.bak "s/^updated: .*/updated: $today/" "$target/docs/backlog.md" && rm -f "$target/docs/backlog.md.bak"
fi

gi="$target/.gitignore"
if ! grep -qxF '.scratchpad/' "$gi" 2>/dev/null; then
    printf '\n# multi-session working folders (Yotamake harness)\n.scratchpad/\n' >> "$gi"
    echo "added .scratchpad/ to .gitignore"
fi

if git -C "$target" rev-parse --git-dir >/dev/null 2>&1; then
    hooks_path=$(git -C "$target" config --get core.hooksPath || true)
    if [[ -z "$hooks_path" ]]; then
        git -C "$target" config core.hooksPath .githooks
        echo "set git core.hooksPath to .githooks (pre-commit runs scripts/check --staged)"
    elif [[ "$hooks_path" != ".githooks" ]]; then
        echo "note: core.hooksPath is already '$hooks_path'; call .githooks/pre-commit from your own hook to run the checks"
    fi
fi

echo "copied ${#copied[@]} file(s), refreshed ${#refreshed[@]} harness file(s) in $target"
[[ ${#refreshed[@]} -gt 0 ]] && printf '  refreshed: %s\n' "${refreshed[@]}"
if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "kept ${#skipped[@]} existing project file(s) — compare with the template by hand, or re-run with --force:"
    printf '  %s\n' "${skipped[@]}"
fi

cat <<EOF

Next steps:
  1. Fill in every FILL IN comment in CLAUDE.md and scripts/check.
  2. Add your toolchain setup to .github/workflows/check.yml (or delete it).
  3. Uncomment the lines in .claude/yotamake/post-edit-checks.conf that fit the project.
  4. Run: scripts/check --all
EOF
