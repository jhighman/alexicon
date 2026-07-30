# 19. A resolution names who decided it

**Date:** 2026-07-30
**Status:** Accepted; reaching `GroundMention`, the Identity Sentinel and the
profile. The 422 historical resolutions are deliberately **not** rewritten.
**Source:** Auditing the fourth derived read. `Claim#category`,
`Transition#verdict` and `Assertion#disposition` had each been examined for what
they do under disagreement; `Mention#status` had not.

## Context

Identity precedes reasoning. `execution_must_not_be_locked` refuses any
judgement *about* an entity until its name is grounded, so the answer to *who
says this name refers to that* is load-bearing for everything downstream.

The audit found something other than the expected defect. Not a collapse — an
**attribution failure**:

```
resolve assertions: 422
by asserter:        {["Identity Sentinel", "system"] => 422}
asserted by a PERSON: 0
```

`GroundMention` creates the referent from the passport somebody supplied, then
calls `IdentitySentinel.verify!`, which records the resolution **under the
Sentinel's own name**. So a decision a person made was recorded as a machine's
inference, in the one place the system treats as prior to all reasoning.

Two things followed, both invisible until measured:

- `Mention#resolution` reads `candidates.select(&:human?).last || candidates.last`
  — *"a person's resolution wins over a system's"*. That branch **could never
  fire**, because no resolution had ever been asserted by a person. A documented
  guarantee that was dead code.
- `ProfileReport` said *"14 of 14 answers were inferred by an agent rather than
  decided by a person"*. Structurally it could say nothing else, however many
  names a person grounded by hand.

Eleven referents in the record carry the note *"Grounded during review by
Identity Grounder"* — somebody was asked, answered, and the record credits the
Sentinel.

Recording a sentinel as the author of a decision it did not make is the
misattribution this whole system exists to catch, committed against itself at
the foundation.

## Decision

**`IdentitySentinel.verify!(mention, by: nil)`.** `by` is whoever decided, when
somebody did.

- Verification at ingest passes nothing and remains the Sentinel's inference.
- `GroundMention` passes the person or agent who answered. Every occurrence of
  the name carries that attribution, because they are all consequences of one
  decision.
- The resolution records `grounded` **both ways** — `true` when somebody was
  asked, `false` when the resolver matched it alone.

Writing only the `true` case would have made a pre-fix resolution
indistinguishable from an automatic match, and 422 of those exist, some of which
somebody did answer. An absent key therefore means *"recorded before resolutions
named their decider"*, which is a different fact from *"nobody was asked"* and is
reported as such.

`inferred?` alone cannot carry this: an agent grounding under delegation is a
system making a decision, so the profile now separates three states — matched by
the resolver, grounded by a person, grounded by an agent — plus the unattributed
legacy.

## Consequences

The guarantee `Mention#resolution` documents is now reachable: a person's
resolution can outrank the Sentinel's, and a spec exercises it.

`GroundMention` had **no spec at all** — it was driven only through controllers,
which is how the attribution came to be wrong without anything noticing. It has
one now, including the alias path.

**The 422 are not rewritten.** An assertion records that a claim *was made*, and
those were made by the Sentinel: a faithful record of a flawed process.
Backfilling them to look correct is exactly the erasure immutability forbids. The
profile reports the attribution as missing rather than inventing it, which is why
document 30 now reads *"14 were recorded before resolutions named their decider,
so whether anyone was asked is not in the record"* instead of a confident and
false claim about who decided.

## What this does not settle

Two people grounding the same name to different referents is still resolved by
supersession — the later answer replaces the earlier, and `Mention`'s own comment
says so: *"Re-verification supersedes prior judgements, so exactly one judgement
stands at a time."* That is a deliberate mechanism rather than the accidental
last-wins fixed in ADR 18, and an explicit `supersedes` link is left in the
record where the others left nothing.

It is still worth asking whether one person superseding another person's identity
decision should stand unremarked, or whether a disputed subject should be treated
as ungrounded and re-lock predication. That question is left open rather than
half-answered here; nothing in the record currently exercises it, since no
resolution has ever been asserted by a person at all.
