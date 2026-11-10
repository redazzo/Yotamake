#!/usr/bin/env bash
# Point git at .githooks/, so the pre-commit hook runs scripts/check --staged.
# Harness-owned: install.sh refreshes it. To opt out, list this file in
# .claude/yotamake/skip and delete it (see ADR-0004).
#
#   set-hooks-path.sh [dir]             the project's SessionStart hook
#   set-hooks-path.sh --install <dir>   install.sh
#
# It sets core.hooksPath only when it is unset at every level and no other hook tool
# (pre-commit, lefthook, a hook in .git/hooks) is in use, since setting it makes git
# stop reading .git/hooks. As the SessionStart hook it also needs .githooks/pre-commit,
# prints nothing unless it sets the value, and then tells the person in one line (a
# systemMessage). With --install it prints the installer's notes instead. It needs only
# bash and git, and always exits 0.

mode=hook
if [[ "${1-}" == --install ]]; then
    mode=install
    shift
fi
dir=${1:-.}

if [[ $mode == hook ]]; then
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
    [[ -f "$root/.githooks/pre-commit" ]] || exit 0
else
    git -C "$dir" rev-parse --git-dir >/dev/null 2>&1 || exit 0
    root=$(cd "$dir" && pwd)
fi

hooks_path=$(git -C "$root" config --get core.hooksPath 2>/dev/null)
other_tool=""
if [[ -z "$hooks_path" ]]; then
    git_hook=$(cd "$root" && git rev-parse --git-path hooks/pre-commit 2>/dev/null)
    [[ "$git_hook" == /* ]] || git_hook="$root/$git_hook"
    for f in lefthook.yml lefthook.yaml lefthook.json lefthook.toml \
             .lefthook.yml .lefthook.yaml .lefthook.json .lefthook.toml; do
        if [[ -f "$root/$f" ]]; then other_tool=lefthook; break; fi
    done
    if [[ -f "$root/.pre-commit-config.yaml" ]]; then
        other_tool=pre-commit
    elif [[ -z "$other_tool" && -f "$git_hook" ]]; then
        other_tool=existing
    fi
fi

if [[ -z "$hooks_path" && -z "$other_tool" ]]; then
    git -C "$root" config core.hooksPath .githooks || exit 0
    if [[ $mode == hook ]]; then
        printf '{"systemMessage": "Set git core.hooksPath to .githooks in this clone, so commits run scripts/check --staged. To undo: git config --unset core.hooksPath"}\n'
    else
        echo "set git core.hooksPath to .githooks (pre-commit runs scripts/check --staged)"
    fi
fi
[[ $mode == hook ]] && exit 0

if [[ "$other_tool" == pre-commit ]]; then
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
elif [[ -n "$hooks_path" && "$hooks_path" != ".githooks" ]]; then
    echo "note: core.hooksPath is already '$hooks_path'; call .githooks/pre-commit from your own hook to run the checks"
fi
exit 0
