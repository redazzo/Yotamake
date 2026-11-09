#!/usr/bin/env bash
# Installs the harness into scratch repositories and checks the result: a full
# install, a lite one, the eval fixture, and a refresh. Exit 1 if any step fails.
set -uo pipefail
plugin="$(cd "$(dirname "$0")/../plugin" && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
full=$tmp/full
lite=$tmp/lite
failed=0

# step <name> <function>: run it in a subshell, quietly; on failure show its output.
# The status is read after a plain assignment: inside `if`, `!`, `&&` or `||`, bash
# ignores set -e, and only the step's last command would count.
step() {
    local out status
    out=$( (set -e; "$2") 2>&1 )
    status=$?
    if [[ $status -ne 0 ]]; then
        echo "FAIL $1"
        tail -n 20 <<<"$out" | sed 's/^/     /'
        failed=1
    fi
}

full_install() {
    git init -q -b main "$full"
    "$plugin/install.sh" "$full"
    cd "$full" && scripts/check --all
}

lite_install() {
    git init -q -b main "$lite"
    "$plugin/install.sh" "$lite" --lite
    test ! -e "$lite/docs" && test ! -e "$lite/scripts/docs"
    cd "$lite" && scripts/check --all
}

lite_refresh_adds_nothing() {
    cd "$lite"
    local before
    before=$(git status --porcelain --ignored)
    "$plugin/install.sh" "$lite" >/dev/null
    [[ "$(git status --porcelain --ignored)" == "$before" ]]
}

eval_fixture() {
    mkdir "$tmp/fixture" && cd "$tmp/fixture"
    bash "$plugin/evals/_fixture/setup.sh"
    scripts/check --all
}

refresh_regenerates_stale_index() {
    cd "$full"
    echo stale > docs/records/README.md
    local out
    out=$("$plugin/install.sh" "$full")
    grep -q 'regenerated docs/records/README.md' <<<"$out"
    node scripts/docs/lint-docs.mjs
}

quoted_status_agrees() {
    cd "$full"
    mkdir -p docs/records/2026
    printf -- '---\nkind: record\ndate: 2026-11-01\nstatus: "current"\n---\n\n# Quoted\n' \
        > docs/records/2026/2026-11-01-q.md
    node scripts/docs/generate-records-index.mjs >/dev/null
    grep -q Quoted <<<"$(sed -n '/## Open/,/## Complete/p' docs/records/README.md)"
    node scripts/docs/lint-docs.mjs
}

settings_merge_keeps_ours() {
    cd "$full"
    node -e '
        const fs = require("fs"), p = ".claude/settings.json", d = JSON.parse(fs.readFileSync(p));
        d.permissions.allow.push("Bash(make:*)"); d.model = "x";
        fs.writeFileSync(p, JSON.stringify(d));'
    "$plugin/install.sh" "$full" >/dev/null
    node -e '
        const d = require("./.claude/settings.json");
        if (d.model !== "x" || !d.permissions.allow.includes("Bash(make:*)")) process.exit(1);'
}

step "full install passes its own check" full_install
step "lite install has no docs system and passes its check" lite_install
step "a lite refresh adds no files" lite_refresh_adds_nothing
step "the eval fixture passes its check" eval_fixture
step "a refresh regenerates a stale records index" refresh_regenerates_stale_index
step "a quoted status is read the same by the index and the linter" quoted_status_agrees
step "the settings merge keeps the repository's own entries" settings_merge_keeps_ours

exit $failed
