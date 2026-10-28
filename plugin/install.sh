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
# A repository can opt out of any template file, harness-owned or not, by listing
# its path in .claude/yotamake/skip (one per line, # for comments). The installer
# then never writes that path, e.g. when the repository has its own docs linter.
#
# Also adds .scratchpad/ to .gitignore and points git at .githooks/, unless
# another hook tool (pre-commit, lefthook, a hook in .git/hooks) is in use.

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

# Paths the repository opted out of. Trim spaces and comments; ignore blank lines.
optout=()
skip_file="$target/.claude/yotamake/skip"
if [[ -f "$skip_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%%#*}
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] && optout+=("${line#./}")
    done < "$skip_file"
fi
is_optout() { local f; for f in "${optout[@]-}"; do [[ -n "$f" && "$1" == "$f" ]] && return 0; done; return 1; }

copied=()
refreshed=()
skipped=()
opted_out=()
while IFS= read -r -d '' file; do
    rel=${file#"$src"/}
    dest="$target/$rel"
    [[ "$rel" == .claude/settings.json ]] && continue
    if is_optout "$rel"; then
        opted_out+=("$rel")
        continue
    fi
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
    # Setting core.hooksPath makes git stop reading .git/hooks, which is where the
    # pre-commit framework and lefthook install. Never switch it off silently.
    other_tool=""
    if [[ -z "$hooks_path" ]]; then
        git_hook=$(cd "$target" && git rev-parse --git-path hooks/pre-commit)
        [[ "$git_hook" == /* ]] || git_hook="$target/$git_hook"
        for f in lefthook.yml lefthook.yaml lefthook.json lefthook.toml \
                 .lefthook.yml .lefthook.yaml .lefthook.json .lefthook.toml; do
            if [[ -f "$target/$f" ]]; then other_tool=lefthook; fi
        done
        if [[ -f "$target/.pre-commit-config.yaml" ]]; then
            other_tool=pre-commit
        elif [[ -z "$other_tool" && -f "$git_hook" ]]; then
            other_tool=existing
        fi
    fi

    if [[ -z "$hooks_path" && -z "$other_tool" ]]; then
        git -C "$target" config core.hooksPath .githooks
        echo "set git core.hooksPath to .githooks (pre-commit runs scripts/check --staged)"
    elif [[ "$other_tool" == pre-commit ]]; then
        cat <<'EOF'
note: found .pre-commit-config.yaml, so core.hooksPath was left alone. To run the checks
      on commit, add this to .pre-commit-config.yaml:
        - repo: local
          hooks:
            - id: scripts-check
              name: scripts/check --staged
              entry: .githooks/pre-commit
              language: script
              pass_filenames: false
EOF
    elif [[ "$other_tool" == lefthook ]]; then
        cat <<'EOF'
note: found a lefthook config, so core.hooksPath was left alone. To run the checks on
      commit, add this to it:
        pre-commit:
          commands:
            scripts-check:
              run: .githooks/pre-commit
EOF
    elif [[ "$other_tool" == existing ]]; then
        echo "note: .git/hooks/pre-commit already exists, so core.hooksPath was left alone; call .githooks/pre-commit from it to run the checks"
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
if [[ ${#opted_out[@]} -gt 0 ]]; then
    echo "did not install ${#opted_out[@]} file(s) listed in .claude/yotamake/skip:"
    printf '  %s\n' "${opted_out[@]}"
fi
if [[ ! -e "$target/README.md" ]] && grep -qF '(./README.md)' "$target/CLAUDE.md" 2>/dev/null; then
    echo "note: no README.md; CLAUDE.md links to it, so the docs check fails until you add one"
fi

cat <<EOF

Next steps:
  1. Fill in every FILL IN comment in CLAUDE.md and scripts/check.
  2. Add your toolchain setup to .github/workflows/check.yml (or delete it).
  3. Uncomment the lines in .claude/yotamake/post-edit-checks.conf that fit the project.
  4. Run: scripts/check --all
EOF
