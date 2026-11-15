# Domain language

The project's own words for what it is about: a customer, an order, a refund. A glossary
holds them, so people, docs and code use one word for each idea and know what it means.
Skills read this file when a talk or a review touches those words. It adapts the
`domain-modeling` skill in Matt Pocock's [skills](https://github.com/mattpocock/skills)
repository (MIT licence).

The words for the design (module, seam, depth) are in `module-design.md` (this folder). Name
a module after the domain idea it holds ("the order intake module"); judge its shape with
`module-design.md`.

## Where the glossary lives

The **Domain language** line in the **Architecture** section of `CLAUDE.md` says where it
is.

- It links to a file, normally `docs/reference/glossary.md`: read that file.
- It lists the terms itself (a repository with no `docs/README.md`, a lite install): read
  the line.
- It says "none yet", or the line is missing: there is no glossary. The first settled term
  starts `docs/reference/glossary.md` and the line then links to it (with no
  `docs/README.md`, the line lists the term).

When the line is first written (by `/yotamake:setup` or an upgrade), look for a glossary the
repository already has: a `GLOSSARY.md`, or a doc that defines the project's terms. Link to
it if there is one; otherwise write "none yet."

Read the glossary only when the work touches its words. Don't read it for every change.

## Rules

- **One word per idea.** When two words name the same idea, pick one and list the other
  under *Avoid*. When one word names two ideas ("account" for both a customer and a login),
  split it into two words.
- **Challenge a clash at once.** When the user, a spec or the code uses a glossary word in
  another sense, say so then, and ask which they mean: "The glossary says a refund is
  always whole, but you describe a partial one. Which is it?" Give your recommendation.
- **Pin the edges with a case.** When two ideas sit close, make up a concrete case that falls
  between them and ask which one it is.
- **Check what the code does.** When someone says how a thing works, check the code. Raise a
  difference: "The code cancels a whole order, but you said a part can be cancelled."
- **What it is, not how it is built.** A definition says what the thing is in the domain. It
  names no table, class or file. The glossary is a list of words, not a spec or a design.
- **Only the project's words.** Leave out general programming words (request, cache, user
  interface) unless the project gives them a meaning of their own.

## Proposing and writing terms

Skills that only read or report (a review, a spec talk) propose terms: each with its
definition and any word to avoid, in their report or their spec. They do not write the
glossary. A session writes it, with the `write-doc` skill, on its branch. A session that
settles a term while it works adds it in the same branch, as it would update any reference
doc it changes.

## Glossary format

A reference doc with the usual front-matter (`write-doc`'s reference template), owning
`domain-language`, and listed in the "Owns" table of `docs/README.md`. Its body:

```markdown
# Glossary

<One or two sentences: what the project is about.>

## <Group, when the terms fall into groups>

- **Refund:** money paid back to a customer for all of one order. _Avoid:_ return, credit.
- **Customer:** a person or company that places orders. _Avoid:_ account, client.
```

Each definition is one or two sentences. Group terms under `##` headings only when groups
appear on their own. In a lite install, the `CLAUDE.md` line holds the same entries, short.

## Naming drift

Drift between the glossary and the code: the code names a domain idea with a word the
glossary lists under *Avoid*, or uses a glossary word in another sense. Report each with
the file, the word and the glossary word. Say which side is wrong when you can tell: the
code (rename it) or the glossary (the code's word is better, or the idea changed). Code
that predates the glossary is not a fault on its own; report it only where the clash would
mislead a reader.

## When a decision gets an ADR

A term needs no ADR. A choice about the domain may need one, say, that a refund always
covers a whole order because the payment provider can't split them. Offer one only when it
passes the three-part test in `write-doc`, "Write it".
