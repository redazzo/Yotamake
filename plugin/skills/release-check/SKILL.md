---
name: release-check
description: Guide a deployment to the right target and component, with a pre-flight checklist and the project's known gotchas, using the Deploying section of CLAUDE.md
disable-model-invocation: true
---

Guide the user through deploying to the correct target, and stop the common mistakes.

All project specifics come from the **Deploying** section of CLAUDE.md: the targets, the
components, the deploy command and its flags, the order components must go in, and the
gotchas. If that section is missing or still holds `<!-- FILL IN -->` placeholders, stop and
say so. Do not guess a deploy command.

## Workflow

1. If the invocation does not name a target, ask which one (for example `local` or
   `production`), listing the targets CLAUDE.md names.
2. If it does not name a component, ask which one, or confirm "all".
3. Run the pre-flight checklist for that target.
4. Show the exact command you will run.
5. For any non-local target, ask: "Ready to deploy to <TARGET>?" and wait for an explicit
   "yes". Anything else means stop. If the deploy command is not under `permissions.ask` in
   `.claude/settings.json`, say so once and suggest adding it.
6. Run it, then run the post-deploy verification CLAUDE.md names, if any.
7. Report the result in a few lines: what went out, the version or tag, and the verification
   result.

## Pre-flight checklist (non-local targets)

1. The branch is the one CLAUDE.md says releases come from, and `git status` is clean.
2. `scripts/check --all` passes on this commit.
3. Pending database migrations go first, if the project has them (CLAUDE.md, **Migrations**).
4. The version bump is done, if the project uses one (CLAUDE.md, **Branching and releases**).
5. Run the dry-run form of the deploy command first, if one exists, and show the plan.

## Gotchas

Always surface every item in CLAUDE.md's **Deploying → Gotchas** list that applies to the
chosen target and component. Say each in one line before asking for confirmation.

## Never

- Deploy without the explicit "yes" from step 5.
- Run a remote migration command when the user asked for a local one.
- Set a secret on a platform by hand when the project keeps secrets in a store. Follow the
  store's process in CLAUDE.md instead.
