#!/usr/bin/env bash
# Tell Claude where it is at the start of a session: the branch, any active
# multi-session effort, and the session rule (ADR-0004, amendment).
# Harness-owned: install.sh refreshes it. To opt out, list this file in
# .claude/yotamake/skip and delete it.
#
#   session-context.sh [dir]   the project's SessionStart hook
#
# Claude Code adds its plain stdout to Claude's context; the person does not see it.
# It prints only what git and the files say, at most about ten lines. It needs only
# bash and git, and always exits 0.

root=$(git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null) || exit 0

# The main branch, read as pre-edit-main-branch.sh reads it; without the line, both
# main and master count.
main=$(sed -n '/^[-*][[:space:]]*\*\*Main branch:\*\*[[:space:]]*`\([^`]*\)`.*/{s//\1/p;q;}' "$root/CLAUDE.md" 2>/dev/null)
mains=${main:-main master}
if branch=$(git -C "$root" symbolic-ref --short -q HEAD); then
    case " $mains " in
        *" $branch "*) echo "Branch: $branch, the main branch. Cut a branch before editing." ;;
        *) echo "Branch: $branch (not the main branch, ${mains// / or })." ;;
    esac
else
    echo "Branch: none (detached HEAD at $(git -C "$root" rev-parse --short HEAD 2>/dev/null))."
fi

# A linked worktree has no .scratchpad/ of its own (it is git-ignored): parallel sessions
# share the main worktree's (ADR-0005), so list its efforts too, by full path. The main
# worktree is the first one git lists.
plans=("$root"/.scratchpad/*/plan.md "$root"/.sessions/*/plan.md)
main_tree=$(git -C "$root" worktree list --porcelain 2>/dev/null | sed -n '1s/^worktree //p')
if [[ -n "$main_tree" && "$main_tree" != "$root" ]]; then
    echo "Worktree of $main_tree; efforts in its .scratchpad/ are listed by full path."
    plans+=("$main_tree"/.scratchpad/*/plan.md)
fi

# Active efforts: a folder with a plan.md, and its first session not marked `done`.
efforts=()
for plan in "${plans[@]}"; do
    [[ -f "$plan" ]] || continue
    folder=${plan#"$root"/}
    folder=${folder%/plan.md}
    next=$(awk '/^## S[0-9]+/ && !/`done`[[:space:]]*$/ { print; exit }' "$plan")
    next=${next#\#\# }
    next=${next% — \`*\`}
    efforts+=("  $folder: ${next:+next is }${next:-every session is done; close-out is next}")
done
if [[ ${#efforts[@]} -gt 0 ]]; then
    echo "Multi-session efforts (to resume, read <folder>/README.md):"
    printf '%s\n' "${efforts[@]:0:5}"
    [[ ${#efforts[@]} -gt 5 ]] && echo "  and $(( ${#efforts[@]} - 5 )) more"
fi

echo "Every change to code, tests or docs runs as a session (yotamake:simple-session, or yotamake:multi-session). Without those skills, see CLAUDE.md, \"How to work here\"."
exit 0
