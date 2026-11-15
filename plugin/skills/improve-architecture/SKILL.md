---
name: improve-architecture
description: Review the design of existing code, read-only — find shallow modules worth deepening (by the deletion test, starting from the parts git history shows change most), places where the code and CLAUDE.md's Architecture section disagree, and code names that clash with the project's glossary — and report rated candidates with a top pick. Then hand the chosen one to a session, the backlog or an ADR. Use when the user runs /yotamake:improve-architecture or asks for an architecture review of the code.
disable-model-invocation: true
---

# Improve architecture

Other skills check that a change fits the design. This one asks whether the design itself is
good, and whether `CLAUDE.md` still describes the code. It finds three kinds of candidate:

- **Deepening:** a shallow module, or a cluster of them, that would be easier to change and
  test as one deeper module.
- **Drift:** a place where the code and the **Architecture** section disagree.
- **Naming drift:** a place where the code names a domain idea against the project's
  glossary.

It reads, reports and asks. It edits nothing, cuts no branch and writes no file. The work a
candidate needs runs later, as a session.

It reads the **Architecture** section of `CLAUDE.md` (all its lines) and the titles of the
accepted ADRs in `docs/decisions/`; read an ADR in full only when a candidate touches it
(step 3). If the section is missing or still holds `FILL IN` placeholders, say so once, judge
the code by the structure it already has, and report no drift: there is nothing to compare
against. Point out that `/yotamake:setup` can fill it in.

Use the words and rules in `<this skill's directory>/../../reference/module-design.md`.
Read it first.

Find the glossary as "Where the glossary lives" in
`<this skill's directory>/../../reference/domain-language.md` says, and use its words for
domain ideas. With no glossary, report no naming drift, but still propose terms (step 4).

## 1. Decide where to look

Improving code nobody changes pays nothing back, so look first where the code changes most.

- If the user named an area, a module or a pain point, look there and skip the rest of this
  step.
- Otherwise list the files changed most often:
  `git log --since="6 months ago" --name-only --format= | sort | uniq -c | sort -rn | head -20`.
  These, and the folders they sit in, are the hot spots. If the history is short or the
  changes are spread evenly, look at the whole codebase.

## 2. Explore in a fresh context

Start one built-in `Explore` agent with the Agent tool, so its reading stays out of this
context. Without the Agent tool, read the code yourself. Give it a self-contained brief:

"Architecture read, read-only. Read <the absolute path of module-design.md> and use its
words. Look first at <the hot spots or the named area>. The project's Architecture section
says: <paste it>. Report two lists. (1) Shallow modules, by that file's 'Signs of a shallow
module': for each, its deletion-test verdict and its kind of dependency. (2) Drift: a module,
folder, pattern or dependency the code uses that the Architecture section does not list, and
a rule it states that the code breaks. (3) Naming drift, only if there is a glossary: read
<the glossary's path, or paste its terms>, and list naming drift as 'Naming drift' in
<the absolute path of domain-language.md> defines it. Give a file path and line range for everything. Edit nothing."

Read the code yourself only where you need to: the lines behind a candidate you would rate
`Strong`, and any claim that looks doubtful. A shallow module is a deepening candidate only
when the deletion test says deleting or merging it would remove complexity or gather it into
one place.

## 3. Sort the candidates

For each candidate:

- **Rating:** `Strong` (the friction is clear and the change pays back soon), `Worth
  exploring`, or `Speculative`.
- **ADRs:** if it goes against an accepted ADR, drop it, unless the friction is bad enough
  to reopen that ADR. Then keep it, and say which ADR and why it is worth reopening.
- **Fit:** the deepened shape must fit **Style**, **Boundaries** and **Patterns**. If it
  needs a new kind of part or a new pattern, say so: that is a design change the user
  decides first.

For drift, say which is wrong: the code (it broke a rule) or `CLAUDE.md` (it is out of
date). For naming drift, follow "Naming drift" in `domain-language.md`. When you can't tell, say so; the user decides.

## 4. Report and ask

Report in the conversation. Do not write the report to a file unless the user asks.

Start with one line: where you looked and why (the hot spots, or the area the user named).
Then the candidates, strongest first, each as:

- **Title:** what changes, e.g. "Merge `name.js` into `greet.js`".
- **Rating**, and the ADR it would reopen, if any.
- **Files:** the paths involved.
- **Problem:** one or two sentences: what hurts, in the words of `module-design.md`.
- **Change:** one or two sentences: the deeper shape, or the fix to the code or to
  `CLAUDE.md`. Describe it, but do not design its interface yet.
- **Gain:** what gets easier, as leverage, locality or tests, e.g. "tests reach one
  interface instead of three". Not "cleaner" or "easier to maintain".
- **Shape:** for a deepening, a small before-and-after sketch of how the modules connect
  (a few lines of text or Mermaid), when it shows the change better than words.

Then the drift, and then the naming drift, one line each: what differs, file paths, and
which side you think is wrong.

Then any **proposed terms**: a domain idea the report needed a name for that the glossary
lacks, such as the idea a deepened module would hold. Give each a one-line definition and
any word to avoid. Leave this out when there are none.

End with the one candidate you would do first, and why, in one or two sentences. Then ask
which candidate the user wants to take on. If you found nothing worth changing, say so
plainly; do not pad the list.

## 5. Hand over

For each candidate the user decides on:

- **Do it now.** Hand it to `simple-session`. Its size check decides whether it fits one
  session; if not, it offers `multi-session`, whose S0 starts its `findings.md` from your
  report. The session's design step checks the deepened shape against **Architecture**. A
  drift fix to `CLAUDE.md`, a rename for naming drift, and the glossary entries for proposed
  terms the user accepts are sessions too.
- **Explore the shape first.** Talk through the deepened module with the user before any
  session: what it hides, its interface, what sits behind each seam, which tests survive,
  and what it is called. Use the rules in `module-design.md`, and give your recommendation
  on each question. Name it with a glossary word; settle a missing one by
  `domain-language.md`, and add it to the proposed terms.
- **Later.** Offer a `docs/backlog.md` entry with a trigger to act.
- **Rejected for a reason that will last.** Offer an ADR: "Want me to record this as an ADR
  so future reviews don't suggest it again?" Offer only when the reason passes the test in
  `write-doc`, "Write it".

A backlog entry or an ADR is written in a session, with the `write-doc` skill. In a repository with no `docs/README.md` (a lite install) there is no backlog or ADR folder:
list what is left over in the report instead.
