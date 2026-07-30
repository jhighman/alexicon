# 18. A ruling names the premises it was made under

**Date:** 2026-07-30
**Status:** Accepted; migrated, backfilled across 1006 rulings, reaching the
Sentinel, the reports, and the review queue
**Source:** Jeff's question, in five parts, ending: *"The architecture must first
learn to preserve disagreement before it is asked to adjudicate disagreement."*

## Context

`Assertion`'s class comment has said this since the beginning:

> Immutability is the point. Issuing an assertion enlarges the historical record
> without destroying what preceded it, so the architecture preserves
> disagreement rather than resolving it prematurely.

That was true of **storage** and false of **every derived read**.

- `Transition#verdict` returned the last ruling, whatever its origin.
- `Assertion#disposition` returned the last disposing act, whoever made it.
- `Claim#agreement` let one person's single reading settle the question.

Each of these resolves by recency. The losing side stayed in the database,
attributable and standing, and was invisible to every surface anybody looks at.
Disagreement was preserved where nobody reads and destroyed where everybody
does.

The record showed it. Of 1006 rulings over 805 transitions, **201 transitions
carried more than one ruling and 6 carried two contradictory ones** — reported
as whichever came second, with nothing anywhere indicating a contradiction
existed. Not one ruling superseded another; they simply piled up and the last
one won.

The sharper consequence was that **a second set of moral premises could not be
recorded at all.** `alexicon-2.0` charges 2 for `ontological → normative`, with
a rationale naming Hume. `lewisian-1.0` charges 0, holding that a claim about
what ought to be is a claim about what is. Both frameworks existed. Running
Lewis over 327 steps produced four differing verdicts — and those verdicts could
not be stored, because with no framework on the assertion they were
indistinguishable from the Humean sentinel being re-run and changing its mind.
Baseline v3 records that run as `persisted: false` for exactly this reason.

So the system could *compute* under two incompatible premises and could not
*hold* them. Asked to, it collapsed them into a chronological sequence and
reported the last one as the truth.

## Decision

**A ruling carries the framework it was made under, and verdicts are read per
framework rather than newest-wins.**

- `assertions.framework_id`, nullable. Most assertions have no such dependence —
  a classification names a category that already belongs to a framework, a
  person's disposal is theirs rather than a premise's. A governance ruling does,
  and `record_verdict!` stamps it.
- All 1006 existing rulings were backfilled to `alexicon-2.0`. Leaving them null
  would have made "unattributed" and "Humean" the same state, which is the
  confusion the change exists to remove.
- `Transition#verdict(framework:)` is scoped to one framework, collapsed **per
  asserter** — a judge revising itself is one position, the latest — and returns
  `CONTESTED` when the surviving positions disagree.
- `CONTESTED` is deliberately outside `VERDICTS`. No sentinel may assert it; it
  can only be observed. `record_verdict!("contested")` raises.
- `Assertion#disposition` does the same for people: one position per reviewer,
  and a split across reviewers is reported as a split.
- `GovernanceSentinel` takes a framework and translates categories by key, so a
  claim classified under one framework can be judged under another. A framework
  with no word for a category has not priced the move, and the Sentinel declines
  rather than treating the absence as free.

Two failures are named separately and never merged:

| | |
|---|---|
| **contested** | two asserters disagree under the same premises — real disagreement, which nothing here resolves |
| **unstable** | one asserter changed its own answer under the same premises — drift, a fact about the instrument rather than the step |

## Consequences

The Lewisian run is now **persisted**. On document 30 both frameworks rule on 93
steps; they agree on 90 and differ on 3, all of them `ontological ↔ normative` —
the two pairs whose weights differ, and no others. Both verdicts stand:

```
{"alexicon-2.0" => "unearned", "lewisian-1.0" => "earned"}
```

The 6 contradictory rulings now report themselves as drift instead of resolving
silently. Since the Sentinel is deterministic, its *inputs* moved — the claims
were re-classified between runs — so those six are a fact about classification
stability, not about the Sentinel. That is a better thing to know than the
verdict it was quietly reporting.

A contested step is neither earned nor unearned, so it falls out of `unearned?`
and out of everything built from it — including the review queue, which is where
a disagreement most needs a person. `Review` now queues contested steps first,
shows both rulings with who said what, and lets a reviewer dispose of either
position. Disposing of one does not delete the other.

**What this does not do.** It does not adjudicate. Nothing here says Hume or
Lewis reads a document better, and the profile refuses to rank them in as many
words. Zero contested steps exist in the record — nothing has yet been ruled on
by two different judges under the same premises — so that path is exercised only
by specs. The capability is built and unmeasured.

The general rule this leaves behind: **anything that presents standing
assertions to a person has to decide what disagreement means to it.** Standing
and undisputed are different properties, and only one of them is a scope.
