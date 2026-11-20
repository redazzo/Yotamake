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

# step <name> <function> [args...]: run it in a subshell, quietly; on failure show its output.
# The status is read after a plain assignment: inside `if`, `!`, `&&` or `||`, bash
# ignores set -e, and only the step's last command would count.
step() {
    local out status
    out=$( (set -e; "${@:2}") 2>&1 )
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
    test -e "$(git rev-parse --git-path yotamake-check-passed)"
}

# The installed CLAUDE.md has a filled Session size line under Branching and releases.
session_size_line() {
    local line
    line=$(sed -n '/^## Branching and releases/,/^## /p' "$full/CLAUDE.md" |
        grep -A1 '^- \*\*Session size:\*\*')
    [[ "$line" =~ [0-9]+\ changed\ lines && "$line" != *"FILL IN"* ]]
}

lite_install() {
    git init -q -b main "$lite"
    "$plugin/install.sh" "$lite" --lite
    test ! -e "$lite/docs" && test ! -e "$lite/scripts/docs"
    # No checks are filled in, so the gate is empty: it passes, says so, and leaves no stamp.
    local out
    out=$(cd "$lite" && scripts/check --all 2>&1)
    grep -q '/yotamake:setup' <<<"$out"
    # The pre-commit run never writes a stamp, so it stays quiet about it.
    out=$(cd "$lite" && scripts/check --staged 2>&1)
    if grep -q 'no check ran' <<<"$out"; then return 1; fi
    cd "$lite"
    test ! -e "$(git rev-parse --git-path yotamake-check-passed)"
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

# True when the docs linter fails.
lint_fails() { ! node scripts/docs/lint-docs.mjs >/dev/null 2>&1; }

# The docs linter fails a link whose #fragment names no heading, in another file or its own.
lint_fails_broken_anchor() {
    cd "$full"
    printf '# Notes\n\n[index](docs/README.md#no-such-heading)\n' > notes.md
    lint_fails || return 1
    printf '# Notes\n\n[index](docs/README.md#reference) [here](#missing)\n' > notes.md
    lint_fails || return 1
    printf '# Notes\n\n## The `docs` check\n\n## Notes\n\n[i](docs/README.md#reference) [a](#the-docs-check) [b](#notes-1) <a id="x"></a>[c](#x)\n' > notes.md
    node scripts/docs/lint-docs.mjs
    rm notes.md
}

# An inventory block fails when a path its glob matches is not named, or it names one not on disk.
lint_checks_inventory() {
    cd "$full"
    mkdir -p items kinds/one && touch items/a.sh items/b.sh
    printf '<!-- inventory: items/*.sh -->\n- `a.sh`\n<!-- /inventory -->\n' > notes.md
    lint_fails || return 1
    printf '<!-- inventory: items/*.sh -->\n- `a.sh` and b.sh, c.sh\n<!-- /inventory -->\n' > notes.md
    lint_fails || return 1
    printf '<!-- inventory: kinds/*/ names -->\n`one`, `two`\n<!-- /inventory -->\n' > notes.md
    lint_fails || return 1
    printf '<!-- inventory: items/*.sh -->\n```\nitems/\n  a.sh  b.sh   run with bash\n```\n<!-- /inventory -->\n<!-- inventory: kinds/*/ names -->Kinds: `one`.<!-- /inventory -->\n' > notes.md
    node scripts/docs/lint-docs.mjs
    rm -r notes.md items kinds
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

# A refresh adds the harness's ask rules to an older settings file, such as the forced
# forms of git branch (backlog, 2026-11-16), and keeps git branch itself allowed.
settings_merge_adds_ask_rules() {
    cd "$full"
    node -e '
        const fs = require("fs"), p = ".claude/settings.json", d = JSON.parse(fs.readFileSync(p));
        d.permissions.ask = d.permissions.ask.filter((r) => !r.startsWith("Bash(git branch"));
        fs.writeFileSync(p, JSON.stringify(d));'
    "$plugin/install.sh" "$full" >/dev/null
    node -e '
        const p = require("./.claude/settings.json").permissions;
        for (const f of ["-D", "-f", "--force", "-M", "-C", "--delete"])
            if (!p.ask.includes(`Bash(git branch ${f}:*)`)) process.exit(1);
        if (!p.allow.includes("Bash(git branch:*)")) process.exit(1);'
}

# project.conf is project-owned (ADR-0008): seeded with the defaults, never rewritten, and
# scripts/check reads its main branch from it.
project_conf_seeded_and_kept() {
    cd "$full"
    grep -qx 'main-branch main' .claude/yotamake/project.conf
    printf 'main-branch trunk\n' > .claude/yotamake/project.conf
    "$plugin/install.sh" "$full" >/dev/null
    grep -qx 'main-branch trunk' .claude/yotamake/project.conf
    local out
    out=$(scripts/check 2>&1 || true)
    cp "$plugin/template/.claude/yotamake/project.conf" .claude/yotamake/project.conf
    grep -qF 'no merge base with the main branch (trunk)' <<<"$out"
}

# The SessionStart entry: added once, beside the repository's own hooks (ADR-0004).
# session_start_count [script]: SessionStart entries naming it (default set-hooks-path.sh).
session_start_count() {
    node -p 'const h = (require("./.claude/settings.json").hooks || {}).SessionStart || [];
        h.filter((e) => JSON.stringify(e).includes(process.argv[1])).length' "${1:-set-hooks-path.sh}"
}

settings_merge_adds_hook_once() {
    cd "$full"
    node -e '
        const fs = require("fs"), p = ".claude/settings.json", d = JSON.parse(fs.readFileSync(p));
        d.hooks = { SessionStart: [{ hooks: [{ type: "command", command: "echo mine" }] }] };
        // Reword our command, as a project might: the merge must not add it again.
        d.hooks.SessionStart.push({ hooks: [{ type: "command",
            command: "bash .claude/yotamake/set-hooks-path.sh || true" }] });
        fs.writeFileSync(p, JSON.stringify(d));'
    "$plugin/install.sh" "$full" >/dev/null
    "$plugin/install.sh" "$full" >/dev/null
    [[ "$(session_start_count)" == 1 ]]
    [[ "$(session_start_count session-context.sh)" == 1 ]]
    grep -q 'echo mine' .claude/settings.json
    test -x .claude/yotamake/set-hooks-path.sh
    test -x .claude/yotamake/session-context.sh
}

# skipped_script_leaves_only_its_hook_out <skipped script> <other script>
skipped_script_leaves_only_its_hook_out() {
    local r=$tmp/skip-$1
    git init -q -b main "$r" && mkdir -p "$r/.claude/yotamake"
    echo ".claude/yotamake/$1" > "$r/.claude/yotamake/skip"
    "$plugin/install.sh" "$r" >/dev/null
    cd "$r"
    test ! -e ".claude/yotamake/$1"
    [[ "$(session_start_count "$1")" == 0 ]]
    [[ "$(session_start_count "$2")" == 1 ]]
    [[ "$(git config --get core.hooksPath)" == .githooks ]]   # the installer still sets it
}

# The installer's hooks-path notes, now printed by set-hooks-path.sh --install.
installer_hooks_path_notes() {
    local r
    r=$tmp/notes-pc && git init -q -b main "$r" && : > "$r/.pre-commit-config.yaml"
    grep -q 'note: found .pre-commit-config.yaml' <<<"$("$plugin/install.sh" "$r")"
    [[ -z "$(git -C "$r" config --get core.hooksPath)" ]]
    r=$tmp/notes-lh && git init -q -b main "$r" && : > "$r/lefthook.yml"
    grep -q 'note: found a lefthook config' <<<"$("$plugin/install.sh" "$r")"
    r=$tmp/notes-own && git init -q -b main "$r" && git -C "$r" config core.hooksPath mine
    grep -q "note: core.hooksPath is already 'mine'" <<<"$("$plugin/install.sh" "$r")"
    r=$tmp/notes-set && git init -q -b main "$r"
    grep -q 'set git core.hooksPath to .githooks' <<<"$("$plugin/install.sh" "$r")"
    ! grep -q 'core.hooksPath' <<<"$("$plugin/install.sh" "$r")"
}

export GIT_CONFIG_GLOBAL=$tmp/gitconfig GIT_CONFIG_NOSYSTEM=1
: > "$GIT_CONFIG_GLOBAL"
step "full install passes its own check and writes the stamp" full_install
step "the installed CLAUDE.md has a filled Session size line" session_size_line
step "lite install has no docs system, and its empty check leaves no stamp" lite_install
step "a lite refresh adds no files" lite_refresh_adds_nothing
step "the eval fixture passes its check" eval_fixture
step "a refresh regenerates a stale records index" refresh_regenerates_stale_index
step "a quoted status is read the same by the index and the linter" quoted_status_agrees
step "the docs linter fails a broken anchor, in another file or its own" lint_fails_broken_anchor
step "the docs linter checks an inventory block both ways" lint_checks_inventory
step "the settings merge keeps the repository's own entries" settings_merge_keeps_ours
step "the settings merge adds the SessionStart hook once" settings_merge_adds_hook_once
step "a refresh adds new ask rules to older settings" settings_merge_adds_ask_rules
step "project.conf is seeded once and scripts/check reads it" project_conf_seeded_and_kept
step "a skipped hooks-path script leaves only its hook entry out" \
    skipped_script_leaves_only_its_hook_out set-hooks-path.sh session-context.sh
step "a skipped session-context script leaves only its hook entry out" \
    skipped_script_leaves_only_its_hook_out session-context.sh set-hooks-path.sh
step "the installer's hooks-path notes are unchanged" installer_hooks_path_notes

exit $failed
