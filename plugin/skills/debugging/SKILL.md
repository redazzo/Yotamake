---
name: debugging
description: Use when fixing a bug — an error, a crash, wrong output, a failing test, a regression, or any work on a fix/ branch — inside a simple-session or multi-session session. Reproduce the bug, write a failing test where the project has tests, find and name the root cause rather than patching the symptom, then fix it and see the test pass. Does not branch, commit or review; the session around it does.
---

# Debugging

A bug fix that patches the symptom comes back. This skill finds the cause first, and proves
the fix with a test that failed before it.

It runs inside a session, from `simple-session`, "Do the work". If no session is running
yet, start `simple-session` first; it sends you here.

This skill reads the **Checks** section of CLAUDE.md for how the project runs its tests. If
the section is missing or unfilled, use the test command the project already has (for
example in `package.json` or a `Makefile`).

## 1. Reproduce it

Make the bug happen before you change anything. Run the command, the test or the steps from
the report, and note what you expected and what happened, with the exact error.

If you cannot make it happen, do not guess a fix. Say what you tried and ask for what is
missing: the input, the version, the logs.

## 2. Write a failing test

Where the project has tests, write one that fails the way the bug does, and run it as
`simple-session`, "Do the work", says for Test-first. A bug fix always starts with its test,
whatever the `Test-first` line says.

Where the project has no tests, write down a command that shows the bug every time, and say
in the report that there was no test to add.

## 3. Find the root cause

The root cause is the first place the code does something wrong. It is often not where the
error shows.

- Trace back from the symptom: where did the bad value or state come from, and where did
  that come from? Keep going until you reach the line that makes it.
- Test one guess at a time. Read the code, add a temporary print, or run a smaller input.
  Change one thing per try.
- For a regression, `git log` and `git blame` on the lines involved show when it started and
  why.
- A fix where the error shows rarely stops the bug on other paths to the same code.
- A guard at the error is a fix only when the state it handles is allowed to happen. If
  that state should never exist, find what makes it.

If two fixes in a row fail on the same idea of the cause, write that idea down in one
sentence. Then test it directly, before another fix: find an observation that would come out
differently if the idea were false, and make it.

If three fixes in a row fail, stop. Your idea of the cause is probably wrong. Say what you
tried and what you saw, and ask the user before trying more.

## 4. Fix it and see the test pass

Make the smallest change that fixes the cause. Remove the temporary prints. Run the new test
and see it pass, then go back to the session. Its checks run the rest of the tests.

If the cause, or the same mistake elsewhere, lies outside the branch's concern, the session's
one-concern rule applies (`simple-session`, "Do the work").

## 5. Report

In the session's report, name the root cause with its file and line and how it led to the
symptom, and the test that failed before the fix (or the command, when there were no tests).
