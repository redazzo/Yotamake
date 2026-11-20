# Report — <Effort title>

Autopilot run, <yyyy-mm-dd>. Mother branch `<branch>`; the work is uncommitted until your yes
(in a committed setup: <N> commits ahead of `<main-branch>`).
<One or two sentences: what the effort set out to do, and whether it did.>

## Decisions and design

- **ADRs added or changed:** <each with its status; new ones are Proposed> or "none".
- **Architecture section of CLAUDE.md:** <what changed> or "unchanged".
- **The plan's Design:** <where the work differed from it, and why> or "followed as agreed".

## Changes

Each with `git diff --stat <main-branch> -- <paths>` (uncommitted work included; new files
count once the review's `git add -N` has run).

- **Code:** <a few lines>
  ```
  <diffstat>
  ```
- **Tests:** <a few lines>
  ```
  <diffstat>
  ```
- **Docs:** <a few lines>
  ```
  <diffstat>
  ```

## Acceptance criteria

<Leave out this section when the effort has no `spec.md`.>

| ID | Met? | How it was checked |
|---|---|---|
| A1 | yes | <test name, check or manual step> |

## Checks and review

- **`scripts/check`:** <the summary lines from the last run>
- **Review:** <the one review of the whole effort, from `log.md`: what each part of
  `simple-session`, "Review", found, fixed and left and why, or why it was skipped
  (docs-only, trivial)>
- **From the sessions' reports:** <tests seen failing first (Test-first), root causes of bug
  fixes> or "none"

## Assumed decisions

Questions taken on their recommendation without asking. Confirm or change each.

| ID | Session | Question | Assumed answer |
|---|---|---|---|

## Commits

<Local setup: the commits your yes will make (the effort, the bump, the merge). Committed
setup: `git log --oneline <main-branch>..HEAD`.>

## Left open

<Pauses, findings no session fixed, backlog entries added, anything for the user to do.>

---

**Merge `<branch>` into `<main-branch>`?** <Or: push `<branch>` and open a pull request?>
