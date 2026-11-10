#!/usr/bin/env bash
# PreToolUse hook for Bash: refuse two git commands the skills forbid.
#   - Any git command with --no-verify (or `git commit -n`), which skips the pre-commit
#     hook and so the gate (CLAUDE.md, Checks). A person can still run it with `! <command>`.
#   - `git commit` while the repository is on its main branch, read as
#     pre-edit-main-branch.sh reads it (`simple-session`, "Branch"). Finishing a merge
#     (MERGE_HEAD exists) is allowed, and so is a repository with
#     .claude/yotamake/allow-edits-on-main.
# The command is split into simple commands with a small quote-aware parser; `cd <dir>` and
# `git -C <dir>` move the directory the next git command runs in. When the command cannot
# be read (an unclosed quote, say), the hook lets it through. Exit 2 blocks the call and
# sends stderr back to Claude.

here=${BASH_SOURCE[0]%/*}
[[ "${BASH_SOURCE[0]}" == */* ]] || here=.
. "$here/lib.sh"

input=$(cat)
# Only commit and --no-verify (or commit -n) can be refused: skip node for anything else.
[[ "$input" == *commit* || "$input" == *no-verify* ]] || exit 0

# The first line is the directory the command runs in. Then one line per git call:
# <dir, relative to that one unless absolute> TAB <subcommand> TAB <1 if it skips hooks,
# else 0>. Prints nothing when the input or the command cannot be read.
calls=$(node -e '
let d;
try { d = JSON.parse(require("fs").readFileSync(0, "utf8")); } catch { process.exit(0); }
const src = String(d?.tool_input?.command ?? "");
const cmds = [[]];
let word = null, quote = null;
const end = () => { if (word !== null) cmds[cmds.length - 1].push(word); word = null; };
for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (quote === "\x27") { if (c === quote) quote = null; else word += c; continue; }
    if (quote === "\"") {
        if (c === "\\" && i + 1 < src.length) word += src[++i];
        else if (c === quote) quote = null;
        else word += c;
        continue;
    }
    if (c === "\x27" || c === "\"") { quote = c; word = word ?? ""; continue; }
    if (c === "\\" && i + 1 < src.length) { word = (word ?? "") + src[++i]; continue; }
    if (/\s/.test(c) && c !== "\n") { end(); continue; }
    if (c === "\n" || c === ";" || c === "&" || c === "|" || c === "(" || c === ")") {
        end(); cmds.push([]); continue;
    }
    word = (word ?? "") + c;
}
if (quote) process.exit(0);
end();
const commitValueFlags = "mFcCt";
const valueLong = /^--(message|file|reuse-message|reedit-message|template|author|date|cleanup|trailer|fixup|squash)$/;
let dir = ".";
const join = (a, b) => (b.startsWith("/") ? b : a + "/" + b);
const out = [];
for (let words of cmds) {
    while (words.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(words[0])) words = words.slice(1);
    if (words[0] === "command" || words[0] === "exec") words = words.slice(1);
    if (words[0] === "cd" && words[1]) { dir = join(dir, words[1]); continue; }
    if (!words.length || !/(^|\/)git$/.test(words[0])) continue;
    let i = 1, gdir = dir;
    for (; i < words.length && words[i].startsWith("-"); i++) {
        if (words[i] === "-C") gdir = join(gdir, words[++i] ?? "");
        else if (words[i] === "-c") i++;
    }
    const sub = words[i] ?? "";
    let skip = 0;
    for (let j = i + 1; j < words.length; j++) {
        const w = words[j];
        if (w === "--") break;
        if (w === "--no-verify") { skip = 1; break; }
        if (sub === "commit" && valueLong.test(w)) { j++; continue; }
        if (sub === "commit" && /^-[^-]/.test(w)) {
            let k = 1;
            for (; k < w.length; k++) {
                if (w[k] === "n") { skip = 1; break; }
                if (commitValueFlags.includes(w[k])) break;
            }
            if (skip) break;
            if (k === w.length - 1) j++;   // the value is the next word
        }
    }
    out.push([gdir, sub, skip].join("\t"));
}
if (out.length) process.stdout.write([d.cwd || process.env.CLAUDE_PROJECT_DIR || process.cwd(), ...out].join("\n"));
' <<<"$input" 2>/dev/null)
[[ -n "$calls" ]] || exit 0
{ read -r cwd; calls=$(cat); } <<<"$calls"

while IFS=$'\t' read -r dir sub skip; do
    if [[ $skip == 1 ]]; then
        echo "BLOCKED: this git command skips the pre-commit hook (--no-verify or commit -n). Fix what the hook reports instead. If the user asked to skip it, they can run the command themselves with '! <command>'." >&2
        exit 2
    fi
    [[ $sub == commit ]] || continue
    [[ "$dir" == /* ]] || dir="$cwd/$dir"
    root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
    git -C "$root" rev-parse -q --verify MERGE_HEAD >/dev/null && continue
    on=$(guarded_main_branch "$root") || continue
    echo "BLOCKED: $root is on its main branch '$on'. Commit on a branch (e.g. git switch -c fix/<topic>), then merge it. $MAIN_OPT_OUT" >&2
    exit 2
done <<<"$calls"
exit 0
