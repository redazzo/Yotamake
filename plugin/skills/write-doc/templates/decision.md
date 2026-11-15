# Decision (ADR) template

For `docs/decisions/NNNN-<kebab-slug>.md`: a choice that constrains future work. Copy what is
inside the fence.

~~~markdown
---
kind: decision
date: YYYY-MM-DD
status: current
---

# ADR-NNNN: <Decision as a short statement>

<!-- Keep the lines that apply. The Status line may add "live in <version> since
YYYY-MM-DD" when that differs from the Date. "Amends" is for a new ADR that changes part of
an older one; a small change to this ADR goes in an amendment section at the end instead. -->

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Work record:** <link>
- **Supersedes:** <ADR links>
- **Amends:** <ADR links, each with what it changes>
- **Builds on:** <ADR links, each with what it relies on>

## Context

<!-- What forced a choice. The constraints, with numbers where you measured them. Say so if
the rationale is inferred from the code. -->

## Decision

In the context of <use case or component>, facing <concern>, we decided for <option> (and
against <alternatives>) to achieve <quality>, accepting that <downside>.

<!-- When the decision holds several choices, number them here, one paragraph each,
starting with the choice in bold. -->

### Alternatives considered

<!-- One line each for the alternatives the sentence above names: why each was rejected. -->

- **<Option.>** <Why it was rejected.>

## Consequences

- **Positive:** <what becomes easier>
- **Negative / accepted trade-offs:** <what becomes harder>
- **Invariants this protects:** <the rules the code must now keep>

## References

<!-- Files, records, issues. -->

<!-- Later changes. When a later ADR replaces this one, set `status: superseded` in the
front-matter and link to it from the Status line. When a detail changes but the decision
stands, add a section here, "## Amendment (YYYY-MM-DD) — <what changed>", and add
"amended YYYY-MM-DD" to the Status line. Never rewrite the sections above. -->
~~~
