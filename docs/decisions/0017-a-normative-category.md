# 17. A fifth category: normative

**Date:** 2026-07-26
**Status:** Accepted; seeded, weighted across all 20 ordered pairs, reaching the
classifier
**Source:** Jeff's decision, from a question about whether the framework is
conceptually exhaustive. It is not, and this was the first gap.

## Context

The flow stages run `Observation → Experience → Interpretation → Meaning →
Belief → Assertion → Action`. The ladder ends in **action**. The claim
categories were objective / observation / interpretive / ontological, and there
was nowhere in them for a claim about *what should be done*.

So the framework policed `interpretive → ontological` — meaning becoming a claim
about what exists — as its centrepiece, and left **description becoming
prescription entirely unpoliced**. That is the same species of crossing. Hume
named it, and it is arguably the more consequential of the two, because a
prescription is what a reader acts on.

It was not hypothetical. The essay under analysis is full of prescription:
*"A man's purpose is one thing, and only one thing: sacrifice"*, *"You need a
clear mind for this"*, *"one must merely open one's eyes"*. Every one was typed
objective, interpretive or ontological, because those were the only options.
When a second judge typed the same claims blind (BASELINE.md §11) it made the
same substitutions for the same reason. Some part of the disagreement measured
there is two readers improvising around a category that did not exist.

## Decision

Add `normative`: *"Claim about what ought to be done, or what is of value."*
Confidence rests on moral or practical commitment.

**Rank 3, alongside ontological.** Both are commitments that no amount of
description licenses. Asserting that an ought needs *more* warrant than an
existence claim would be an editorial judgement with nothing behind it.

### The weights, and the shape they break

Every pair in the table until now took the same shape: the ascent costs, the
descent is free, because coming down means retreating to firmer ground.

| | |
|---|---|
| `interpretive → normative` | **2** — meaning becoming obligation; the direct analogue of `interpretive → ontological`, weighted the same |
| `objective → normative` | **3** — fact straight to obligation |
| `observation → normative` | **3** — experience straight to obligation |
| `ontological → normative` | **2** — what exists does not settle what should be done |
| `normative → ontological` | **2** — and the reverse has no more warrant |
| `normative →` objective / observation / interpretive | **0** — retreat to firmer ground |

`ontological ↔ normative` is **symmetric**, and it is the first pair in the
table that is. Nothing about an ought is firmer ground for an is, or the
reverse; the crossing is unwarranted in both directions, so neither direction is
a retreat.

They also share a rank and are still not lateral, where `objective ↔ observation`
share a rank and *are*. That is exactly why `CategoryPromotion` weights the
ordered pair instead of subtracting ranks — a decision made for a different
reason ([the fork migration](../../app/services/retroactive_audit.rb)) which
turns out to have been necessary for this one.

## Consequences

Nothing already classified moves. Classifications are immutable assertions, and
a category added today does not retype yesterday's claims. Documents 20 and 26
keep the readings they were given.

**Baselines v1 and v2 were measured against four categories.** Every figure in
them — reproducibility, polarity invariance, category-pair reproducibility,
inter-judge agreement — was taken from a four-way choice, and a five-way choice
is a different measurement. Any baseline recorded from now on must carry the
category count in its `conditions` so `Baseline.compare` refuses the pair rather
than reporting a difference that is really a changed instrument. v1 and v2 do
not carry it, because it could not have occurred to anyone to record a constant.

The classifier needed no code change: it builds both its prompt and its response
schema from `framework.claim_categories`, so the category reached the model as
soon as it was seeded. A probe over seven prescriptive claims moved three to
normative — the unambiguous ones — and left the rest, including one phrased as
an is-claim (*"A man's purpose is one thing"*) that arguably should have moved.
Single readings, so some of that is the 87.9% reproducibility of §2 rather than
the boundary.

**The boundary will need measuring, not assuming.** §10 and §11 showed the
observation boundary is genre-dependent and underdetermined; there is no reason
to think a normative boundary arrives better behaved, and a category that exists
is not yet a category that is applied consistently.

## What this does not fix

Three further gaps in the same audit, left open deliberately:

- **Governance is pairwise.** `Transition` is one source, one target. A
  conclusion resting on several premises is judged only against whatever
  preceded it, and convergent argument cannot be represented at all.
- **Abstention conflates two things.** "This is not a claim" and "I cannot tell
  what kind of claim this is" are recorded identically.
- **The categories are still not demonstrably a partition.** Normative closes
  the gap that had a name. Modal, counterfactual, definitional and performative
  claims have no home either, and nobody has checked whether five is enough.

## See also

- [0001 — Categories and domains are different axes](0001-categories-and-domains-are-different-axes.md)
- `docs/BASELINE.md` §11 — where two judges disagreed about prescription with
  nowhere to put it
