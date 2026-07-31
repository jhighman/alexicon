# 25. Values differ in axis, not only in rank

**Date:** 2026-07-31
**Status:** Proposed. Nothing built, nothing seeded. The modelling is gated on a
re-read of the eighteen probes already recorded, which needs no new data and no
model call.
**Source:** A discussion of how academic value hierarchies differ from alignment
ones — truth, evidence, reproducibility and intellectual honesty ordered ahead of
care, not because care is absent but because the mission is different — and of
where aesthetic judgement sits, which is nowhere in this framework at all.

## Context

### What the ranking already refuses, and why

`ValueRanking` declines to produce a total order for three reasons. Two are about
measurement and one is not:

1. **Stability.** A probe whose ordering moves between runs has established
   nothing.
2. **Transitivity is not assumed.** A cycle may be a real property — priority
   that is context-dependent rather than hierarchical — so cycles are reported
   as cycles.
3. **Connectivity.** Four probes over four disjoint pairs are four disconnected
   edges. Knowing *Safety > Autonomy* and *Kindness > Truth* relates the two not
   at all, so islands are reported separately rather than concatenated into a
   list that reads as a hierarchy.

The third has always been treated as a **measurement gap** — the graph is
disconnected because not enough probes have been run, and enough probes would
connect it.

That may be wrong. The islands may be **boundaries**, not gaps. *Safety >
Autonomy* and *Kindness > Truth* may fail to relate because they are not the same
kind of question, and no probe will ever connect them, because there is nothing
there to connect.

### The reframe

Human judgement does not run on one dimension. At least these are distinct, and
none reduces to another:

| Axis | Governing question |
|---|---|
| Epistemic | Is it true? |
| Moral | Is it good? |
| Operational | Does it function? |
| Aesthetic | Is it elegant? |
| Existential | Is it worth living for? |

A physicist choosing between two theories that fit the data equally well, on
grounds of symmetry, is not making an epistemic judgement or a moral one. An
engineer calling an abstraction elegant is doing something neither empirical nor
ethical. These are real evaluations and this framework has no vocabulary for
them.

On this reading, a disagreement about "which value wins" is often a disagreement
about **which axis governs the decision**. In scientific publishing the epistemic
axis dominates; in emergency medicine the moral one usually does; in software
governance the operational one. The apparent conflict is about authority between
axes, not rank within one.

### Why this bears on a failure already recorded

The value layer failed four times across two scopes, and the recorded diagnosis
is *the question has no ground truth in a found text*.

This offers a second explanation that does not replace it: the judge may have
been asked to rank across incommensurable axes and produced noise because the
**question was malformed**, not because the text was silent.

Those two explanations are distinguishable, and the existing probe set can
distinguish them.

### The naming collision, which must be settled first

**`Domain` is taken.** It means the seven 2.0 domains — Identity, Agency,
Motivation, Reflection, Integration, Governance, Orientation. Introducing a
second, unrelated sense of "domain" for moral / epistemic / aesthetic would be
the overlap the lexicon exists to forbid carrying silently, committed in the
layer that forbids it.

So the word is **axis**. A value has an axis; a framework has domains; they are
different things and the lexicon will say so.

## Decision

**1. The word is `axis`, and the lexicon records that it is not `Domain`.**

**2. Adopt only the axes the recorded probes can exercise.** The proposed
tagging of the existing vocabulary, from the eighteen probes already run:

| Axis | Values appearing in probes |
|---|---|
| Epistemic | truth, coherence, generality, curiosity, honesty, reason |
| Moral | kindness, justice, belonging, harm reduction, agency, autonomy, expression, independence |
| Operational | privacy, safety |
| Existential | purpose, continuity, affirmation |

**Aesthetic is deliberately not adopted.** It is the sharpest idea in the source
discussion and it has **zero coverage**: not one of the eighteen probes puts
elegance, simplicity or proportion in conflict with anything. Seeding it would be
a claim about what people protect with no evidence behind it, which is exactly
what `FrameworkValue#provenance` exists to keep visible. It is recorded here as
unmeasured and is not vocabulary until a probe exercises it.

The same applies, more strongly, to legal, economic, political, social,
psychological, narrative, identity, temporal, ecological and sacred. A long list
of axes adopted on intuition is how the open-vocabulary judge reached a 61%
invention rate: given a large enough menu it can always produce something, so it
does.

**3. An axis tag is a claim about people, and carries provenance like the values
do.** Whether *truth* is epistemic and *kindness* moral is a philosophical
commitment, not a fact read off the system. Tagged values carry the same
`probe` / `proposed` distinction the vocabulary already carries, so a reading
resting on an asserted axis stays distinguishable from one resting on an
observed value.

**4. Nothing is modelled until the control returns.** A capability is built when
its measurement exists ([ADR 20](0020-judgment-waits-for-closure.md)), and this
one has a control that costs nothing.

## The control

**Prediction.** If the axes are real, a probe whose two values sit on the *same*
axis should establish an ordering more reliably than one whose values sit on
different axes. Cross-axis probes should be disproportionately the unstable ones,
and disproportionately the ones `OrderStability` already excludes.

**Method.** Tag the eighteen recorded probes same-axis or cross-axis under the
table above. Re-read the standing interpretations already in the record — no
model is called, nothing is re-bought — and compare stability between the two
arms.

**The split exists.** Roughly half the probes are cross-axis (*Kindness vs
Truth*, *Safety vs Truth*, *Curiosity vs Privacy*, *Affirmation vs Truth*,
*Agency vs Truth*, *Independence vs Truth*, *Autonomy vs Continuity*) and roughly
half are same-axis (*Autonomy vs Kindness*, *Belonging vs Independence*, *Privacy
vs Safety*, *Coherence vs Truth*, *Continuity vs Purpose*, *Agency vs
Belonging*). That is enough to compare.

**One thing to watch.** *Truth* appears in eight of the eighteen probes and is
the graph's hub. If cross-axis probes are the unstable ones, then Truth is
precisely the node connecting islands that should not have been connected — and
the connectivity `ValueRanking` was waiting for would have been an artefact.

**What each outcome means.**

- Same-axis probes are stable and cross-axis ones are not → the axes are real,
  the islands are boundaries, and the modelling in this ADR is worth building.
- No difference → the axes are a distinction without a measured consequence
  *here*. They may still be true of people; they are not doing work in this
  system, and nothing should be seeded on them.
- Cross-axis probes are *more* stable → the reframe is wrong in an interesting
  way and should be written down as such.

## Alternatives

**Model axes as a first-class dimension with its own table and joins.** Rejected
for now as premature. A tag on `FrameworkValue` answers the control's question at
a fraction of the cost, and the heavier structure can follow evidence rather than
precede it.

**Adopt the full sixteen-axis taxonomy from the source discussion.** Rejected.
Twelve of them have no probe, no measurement and no implementation surface. The
framework already carries a vocabulary half-marked `proposed` and has recorded
what that costs — substituting one account of what people protect for another
changed 23 of 28 readings. Adding twelve more unmeasured dimensions would make
that worse in the same direction.

**Treat the axis as governing which *sentinel* rules, rather than which values
compare.** Genuinely attractive and deferred. It would mean the Governance
Sentinel asks "which axis has authority here?" before asking what a move costs —
which is a larger claim than the evidence supports, and would change every
recorded verdict. Revisit if the control comes back positive.

**Do nothing.** The honest default, and it remains the outcome if the control
finds no difference. The value layer is already unsupported by measurement; a new
dimension asserted over it would be a second unsupported claim resting on the
first.

## Consequences

**The five claim categories are not one dimension either, and this explains
something already in the record.** `ontological ↔ normative` is weighted
symmetrically and no other pair is — because, in the framework's own words,
nothing about an *ought* is firmer ground for an *is* or the reverse. Under this
ADR that symmetry has a name: they are not two points on a scale of abstraction,
they are two **axes**, and a move between them is a change of question rather
than a promotion. The weight table already encodes the insight; the vocabulary
did not.

**`ValueRanking`'s islands may need a different report.** Today a disconnected
graph reads as "not enough probes". If the axes hold, some of those gaps should
read as "these are not comparable and no probe will make them so" — which is the
same distinction the code already draws between a silent framework and a free
crossing, and between `undetermined` and `contested`.

**This does not rescue the value layer.** Four designs failed to read what a step
protects from a found text, and an axis tag does not give them ground truth. What
it might do is explain why the *ranking* over probe results has stayed
disconnected, which is a different failure at a different layer.

**Nothing here licenses a hierarchy.** Axes are orthogonal by construction. An
architecture that ordered the axes themselves would have rebuilt the single
ranked list this ADR exists to refuse.
