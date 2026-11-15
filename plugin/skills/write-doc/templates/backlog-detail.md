# Backlog detail template

For `docs/backlog/<slug>.md`: the longer analysis behind one backlog entry. Copy what is inside the fence.

~~~markdown
# <Item> — <what this analysis answers>

**Date:** YYYY-MM-DD · **Status:** <open / stage 1 shipped YYYY-MM-DD, stages 2–3 open>
**Symptom:** <what a user or developer sees, in one or two sentences>

---

## 1. What the investigation found

<!-- The cause, with file:line references and numbers you measured. Say which parts are
measured and which are inferred. -->

## 2. Options

<!-- Each way to fix it, with what it costs and what it risks. End with the one you
recommend and why. -->

| Option | Cost | Risk |
|---|---|---|

## 3. Stages

<!-- When the fix comes in parts, one `###` per stage with its state. A shipped stage says
when it shipped and what it changed; an open stage says what would trigger it. -->

### Stage 1 — <shipped YYYY-MM-DD / open>

## 4. How to tell it worked

<!-- The measurement or test that shows the symptom is gone. -->
~~~
