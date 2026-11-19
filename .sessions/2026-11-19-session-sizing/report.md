# Report — Session sizing

Autopilot run, 2026-11-19. Mother branch `ccr-670642ff-1n2a64`, 8 commits ahead of `main`.
The effort set out to size a session by review, revert and decisions instead of by context
and fixed structural tests. It did, with one wording gap in A7 (below).

## Decisions and design

- **ADRs added or changed:** ADR-0011, "A session is sized by review, revert and decisions,
  with context as a backstop" — **Proposed**, for you to accept.
- **Architecture section of CLAUDE.md:** unchanged.
- **The plan's Design:** followed, with these changes found in review:
  - "How to work here" in the three `CLAUDE.md` copies points to the skill instead of
    restating the definition (D7).
  - The split of a session that stops partway is a `multi-session` rule, not only an
    autopilot one, so step-through efforts get it too.
  - The signal "parts that could ship on their own" became "bundles separate changes that
    could each ship, and be reviewed, alone": the old wording could fire on a column plus the
    code that reads it.
  - Autopilot keeps its general "cannot finish within its plan" pause beside the new
    `PAUSE: size` (the A7 gap).

## Changes

- **Skills, reference, template:** `simple-session` "Check the size" rewritten (estimate,
  `Session size` limit with a stated default, signals, ADR first, stop partway, report line);
  `multi-session` sizing and split rule; `autopilot.md` pause; `debugging`, `setup`,
  `missing-setup.md`; template `CLAUDE.md` line and wording; `upgrades.md` 0.38.0 entry.
  ```
  9 files changed, 108 insertions(+), 66 deletions(-)
  ```
- **Evals and tests:** new case `24-should-fit` (12 files); `test-install.sh` step.
  ```
  13 files changed, 127 insertions(+), 4 deletions(-)
  ```
- **Docs and site:** ADR-0011, work record, glossary, backlog (3 new entries, 1 updated),
  README, changelog, this repository's `CLAUDE.md`, three site pages.
  ```
  11 files changed, 220 insertions(+), 29 deletions(-)
  ```

## Acceptance criteria

| ID | Met? | How it was checked |
|---|---|---|
| A1 | yes | Read: skill, glossary, `multi-session`, plan template; `CLAUDE.md` copies point to the skill (D7) |
| A2 | yes | Read "Check the size"; old structural tests named as not too big by themselves |
| A3 | yes | Read step 1 and the report list (not for trivial or docs-only changes) |
| A4 | yes | `test-install.sh` step; upgrade entry; doctor has no `FILL IN` to flag (an older install shows a pending upgrade, as for any entry) |
| A5 | yes | Read step 1, step 3 and step 4: an ADR lands first as its own commit |
| A6 | yes | Read "Stop partway" (also inside `debugging`) |
| A7 | partly | Named `PAUSE: size` and the split are in; the general "cannot finish within its plan" trigger was kept beside it, where the spec said "instead of" |
| A8 | written, not run | Case 24 added, case 03 checked by reading; neither run (cost) |
| A9 | yes | README and site sum up and link; backlog updated; `scripts/check` passes |

## Checks and review

- **`scripts/check`:** PASS syntax, consistency, docs, site, upgrades, validate, install.
- **Review:** S1 and close-out were docs only (skipped). S2–S6 each ran `/simplify`,
  `/code-review` and a design read, and each changed the work; `log.md` has the details.
  The biggest fixes: the upgrade Check covering the rewording (S2); stop partway inside an
  effort and in bug fixes, and the stated default restored after a design read found the
  pointer clashed with ADR-0002 (S3); split updates later `Needs:` and waits for your yes
  (S4); the loose signal and the eval's grader (S5); unconfirmed claims removed (S6).
- **From the sessions' reports:** S3 and S4 wrote no size estimate before starting; S5 and
  S6 did, and were close.

## Assumed decisions

| ID | Session | Question | Assumed answer |
|---|---|---|---|
| D1 | S1 | Write a new ADR for the definition? | Yes, ADR-0011, Proposed |
| D2 | S2 | Where does the limit live? | A bold `**Session size:**` line in **Branching and releases** |
| D3 | S3 | A hook that warns on diff size? | No; skill text only, backlog entry |
| D4 | S2 | Default limit? | About 400 changed lines or 15 files (a judgment, not measured) |
| D5 | S3 | Keep the heading "Check the size"? | Yes |
| D7 | S2 | `CLAUDE.md` copies: restate or point? | Point to the skill |

## Commits

```
c438220 docs: sum up the new session sizing in the README, site and backlog (S6)
179a188 test(evals): add case 24-should-fit, and tighten the separate-changes signal (S5)
6810101 feat(multi-session): size planned sessions by the size check, and split one that stops partway (S4)
213e8c7 feat(simple-session): size a session by review, revert and decisions, and stop partway (S3)
43e3906 feat(template): add a Session size line and point How to work here at the size check (S2)
2f8f36d docs(decisions): propose ADR-0011, sizing a session by review, revert and decisions (S1)
657bd24 docs(sessions): plan the session sizing rework (S0)
```
Plus the close-out commit (work record).

## Left open

- **Accept ADR-0011?** The README and backlog cite it; it should be Accepted before merge.
- **A7 wording gap:** keep the general autopilot pause (my view: it is a useful catch-all) or
  drop it to match the spec.
- **Evals not run** (cost money): 03-too-big and 24-should-fit matter most; `scripts/check`
  names all 24 as covering the change.
- **Backlog entries added:** size warning hook; middle tier; the review window restarting
  during a cloud autopilot run (cause not confirmed).
- `simple-session` is at its 250-line cap.
- On yes: delete this folder, bump to 0.38.0 (with `./plugin/install.sh .`), then push.

---

**Push `ccr-670642ff-1n2a64` and open a pull request into `main`?** (This cloud session works
on an assigned branch, so integration is a push and a pull request, not a local merge.)
