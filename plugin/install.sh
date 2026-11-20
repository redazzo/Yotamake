#!/usr/bin/env bash
# Set up a repository for the Yotamake harness, or refresh one already set up.
#
#   install.sh <target-repo> [--force] [--lite]
#
# The method (skills, hooks, output style) comes from the yotamake plugin. This
# script installs the files each repository keeps for itself, from template/:
#
#   Project-owned  CLAUDE.md, scripts/check, docs/, .claude/yotamake/*.conf, CI workflow.
#                  Copied only when missing (--force overwrites). Yours to edit.
#   Harness-owned  scripts/docs/*.mjs, .githooks/pre-commit, .claude/yotamake/version,
#                  .claude/yotamake/set-hooks-path.sh, .claude/yotamake/session-context.sh.
#                  Always refreshed, so re-running this script updates them.
#   Generated      docs/records/README.md: regenerated when stale, so a refreshed
#                  generator never leaves the docs check failing.
#   Merged         .claude/settings.json: the harness's marketplace, plugin, permission
#                  and hook entries are added to whatever is already there. Only a
#                  retired harness rule (git commit under ask) is ever removed.
#
# A repository can opt out of any template file, harness-owned or not, by listing
# its path in .claude/yotamake/skip (one per line, # for comments). The installer
# then never writes that path, e.g. when the repository has its own docs linter.
#
# --lite leaves out the docs system (docs/ and scripts/docs/): it adds those paths
# to .claude/yotamake/skip, so later runs leave them out too, and drops the docs
# lines from a newly copied CLAUDE.md and scripts/check.
#
# Also adds .scratchpad/ to .gitignore and points git at .githooks/, unless
# another hook tool (pre-commit, lefthook, a hook in .git/hooks) is in use.

set -euo pipefail

usage() { echo "usage: $0 <target-repo> [--force] [--lite]" >&2; exit 1; }

[[ $# -ge 1 ]] || usage
target=$1
shift
force=""
lite=""
for arg in "$@"; do
    case "$arg" in
        --force) force=--force ;;
        --lite) lite=--lite ;;
        *) usage ;;
    esac
done
[[ -d "$target" ]] || { echo "not a directory: $target" >&2; exit 1; }

src="$(cd "$(dirname "$0")" && pwd)/template"
target="$(cd "$target" && pwd)"
today=$(date +%Y-%m-%d)

managed=(scripts/docs/lint-docs.mjs scripts/docs/generate-records-index.mjs .githooks/pre-commit
         .claude/yotamake/set-hooks-path.sh .claude/yotamake/session-context.sh)
is_managed() { local f; for f in "${managed[@]}"; do [[ "$1" == "$f" ]] && return 0; done; return 1; }

skip_file="$target/.claude/yotamake/skip"

# Paths the repository opted out of. Trim spaces and comments; ignore blank lines.
optout=()
if [[ -f "$skip_file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=${line%%#*}
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] && optout+=("${line#./}")
    done < "$skip_file"
fi
is_optout() { local f; for f in "${optout[@]-}"; do [[ -n "$f" && "$1" == "$f" ]] && return 0; done; return 1; }

# --lite: record the docs system's paths in the skip file, once.
if [[ -n "$lite" ]]; then
    mkdir -p "$(dirname "$skip_file")"
    [[ -s "$skip_file" && -n "$(tail -c1 "$skip_file")" ]] && echo >> "$skip_file"
    added=0
    while IFS= read -r -d '' file; do
        rel=${file#"$src"/}
        [[ "$rel" == docs/* || "$rel" == scripts/docs/* ]] || continue
        is_optout "$rel" && continue
        if [[ $added -eq 0 ]]; then
            printf '# --lite: no docs system. Delete these lines and re-run the installer to add it.\n' >> "$skip_file"
        fi
        echo "$rel" >> "$skip_file"
        optout+=("$rel")
        added=$((added + 1))
    done < <(find "$src" -type f -print0 | sort -z)
    [[ $added -gt 0 ]] && echo "--lite: added $added docs path(s) to .claude/yotamake/skip"
fi

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
    # Lines between "yotamake:docs begin" and "end" markers belong to the docs
    # system: --lite drops them, otherwise only the marker lines go.
    if grep -qE 'yotamake:docs (begin|end)' "$dest"; then
        if [[ -n "$lite" ]]; then
            sed '/yotamake:docs begin/,/yotamake:docs end/d' "$dest" | cat -s > "$dest.bak"
            cat "$dest.bak" > "$dest"
        else
            sed -E -i.bak '/yotamake:docs (begin|end)/d' "$dest"
        fi
        rm -f "$dest.bak"
    fi
done < <(find "$src" -type f -print0 | sort -z)

# Merge settings.json: add the harness's entries, keep everything else. An allow rule
# or hook entry that names a script the repository opted out of, and does not have, is
# left out. A hook entry is added once per event, known by the scripts it runs. The one
# removal: Bash(git commit:*) leaves the ask list, which older versions put it in (ADR-0013).
mkdir -p "$target/.claude"
node - "$src/.claude/settings.json" "$target/.claude/settings.json" "$target" "${optout[@]-}" <<'EOF'
const fs = require("fs");
const path = require("path");
const [srcPath, destPath, target, ...optout] = process.argv.slice(2);
const ours = JSON.parse(fs.readFileSync(srcPath, "utf8"));
const theirs = fs.existsSync(destPath) ? JSON.parse(fs.readFileSync(destPath, "utf8")) : {};
const before = JSON.stringify(theirs);
const missing = optout.filter((f) => f && !fs.existsSync(path.join(target, f)));
for (const key of ["extraKnownMarketplaces", "enabledPlugins"]) {
    theirs[key] = theirs[key] || {};
    for (const [k, v] of Object.entries(ours[key])) {
        if (!(k in theirs[key])) theirs[key][k] = v;
    }
}
const perms = (theirs.permissions = theirs.permissions || {});
const retiredAsk = ["Bash(git commit:*)"];
if (perms.ask) perms.ask = perms.ask.filter((rule) => !retiredAsk.includes(rule));
for (const kind of ["allow", "ask"]) {
    const have = (perms[kind] = perms[kind] || []);
    for (const rule of ours.permissions[kind]) {
        if (have.includes(rule) || (perms.deny || []).includes(rule)) continue;
        if (kind === "allow" && missing.some((f) => rule.includes(f))) continue;
        have.push(rule);
    }
}
// A harness hook entry is known by the scripts it runs, so a reworded command is not
// added twice. An entry is added when the event has no command naming its scripts yet.
const commands = (entry) => (entry.hooks || []).map((h) => h.command || "").join("\n");
const scripts = (entry) => commands(entry).match(/\.claude\/yotamake\/[\w.-]+\.sh/g) || [];
for (const [event, entries] of Object.entries(ours.hooks || {})) {
    for (const entry of entries) {
        if (missing.some((f) => commands(entry).includes(f))) continue;
        const have = (theirs.hooks || {})[event] || [];
        const present = have.map(commands).join("\n");
        const known = scripts(entry).length
            ? scripts(entry).every((f) => present.includes(f))
            : have.some((e) => commands(e) === commands(entry));
        if (known) continue;
        theirs.hooks = theirs.hooks || {};
        (theirs.hooks[event] = theirs.hooks[event] || []).push(entry);
    }
}
if (JSON.stringify(theirs) !== before) {
    fs.writeFileSync(destPath, JSON.stringify(theirs, null, 2) + "\n");
    console.log("merged harness entries into .claude/settings.json");
}
EOF

chmod +x "$target/scripts/check" "$target/.githooks/pre-commit" \
    "$target"/.claude/yotamake/*.sh 2>/dev/null || true

# Record the plugin version these files came from. The sessions compare it with the
# plugin's own and offer the upgrades in reference/upgrades.md.
version_file=.claude/yotamake/version
if ! is_optout "$version_file"; then
    version=$(node -p 'require(process.argv[1]).version' "$src/../.claude-plugin/plugin.json")
    if [[ "$(cat "$target/$version_file" 2>/dev/null)" != "$version" ]]; then
        mkdir -p "$(dirname "$target/$version_file")"
        echo "$version" > "$target/$version_file"
        echo "recorded harness version $version in $version_file"
    fi
fi

# docs/records/README.md is the generator's output, not hand-written. A refreshed
# generator may render it differently, and the docs check fails on a stale index,
# so regenerate it on every run. Skipped when the index is opted out, or the repo has
# no generator of ours (opted out, or --lite).
records_index=docs/records/README.md
gen="$target/scripts/docs/generate-records-index.mjs"
if ! is_optout "$records_index" && [[ -f "$gen" && -d "$target/docs/records" ]]; then
    before=$(cat "$target/$records_index" 2>/dev/null || true)
    if ! node "$gen" >/dev/null; then
        echo "warning: could not regenerate $records_index; run: node scripts/docs/generate-records-index.mjs" >&2
    elif [[ "$(cat "$target/$records_index")" != "$before" ]]; then
        echo "regenerated $records_index"
    fi
fi

# Date the backlog's front-matter, if we just wrote it.
if [[ " ${copied[*]-} " == *" docs/backlog.md "* ]]; then
    sed -i.bak "s/^updated: .*/updated: $today/" "$target/docs/backlog.md" && rm -f "$target/docs/backlog.md.bak"
fi

gi="$target/.gitignore"
if ! grep -qxF '.scratchpad/' "$gi" 2>/dev/null; then
    printf '\n# multi-session working folders (Yotamake harness)\n.scratchpad/\n' >> "$gi"
    echo "added .scratchpad/ to .gitignore"
fi

# Point git at .githooks/, unless another hook tool is in use. The template's copy runs
# here, so a repository that opted out of the script still gets this on install. The
# project's SessionStart hook runs the installed copy (ADR-0004).
bash "$src/.claude/yotamake/set-hooks-path.sh" --install "$target"

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
# CLAUDE.md links ./README.md, so a repo without one would fail the docs check.
readme_stub=""
if [[ ! -e "$target/README.md" ]] && grep -qF '(./README.md)' "$target/CLAUDE.md" 2>/dev/null; then
    printf '# %s\n\n<!-- FILL IN: what the project is, and how to set it up and run it. -->\n' \
        "$(basename "$(cd "$target" && pwd)")" > "$target/README.md"
    readme_stub=1
    echo "wrote a stub README.md (CLAUDE.md links to it)"
fi

# Next steps, leaving out files the repository opted out of.
steps=()
fill=""
for f in CLAUDE.md scripts/check; do is_optout "$f" || fill+="${fill:+ and }$f"; done
[[ -n "$readme_stub" ]] && fill+="${fill:+ and }README.md"
[[ -n "$fill" ]] && steps+=("Fill in every FILL IN comment in $fill.")
is_optout .github/workflows/check.yml ||
    steps+=("Add your toolchain setup to .github/workflows/check.yml (or delete it).")
is_optout .claude/yotamake/post-edit-checks.conf ||
    steps+=("Uncomment the lines in .claude/yotamake/post-edit-checks.conf that fit the project.")
steps+=("Run: scripts/check --all")
echo
echo "Next steps:"
for i in "${!steps[@]}"; do echo "  $((i + 1)). ${steps[$i]}"; done
