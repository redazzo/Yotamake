# Findings not acted on

The `simple-session` skill sends you here ("Findings not acted on") when a session has a
finding it does not act on: a real problem you see, at any step, that the branch does not fix.

Drop a finding you judge wrong, and say why in one line in the report. Write every other
one into `docs/backlog.md` as part of this branch's changes, as the `write-doc` skill says,
with the file and line. Add to an entry that already covers it rather than a duplicate, and
put one branch's small cleanups in a single entry. List the findings in the report instead
when there is no `docs/backlog.md`, or when the user has limited which files may change.
Inside a `multi-session` effort, add them to the ledger's Backlog line instead; close-out
writes the entry. Write the ones you know before a `scripts/check` run, so that run covers
them; one written after the last run means running it again before the report.
