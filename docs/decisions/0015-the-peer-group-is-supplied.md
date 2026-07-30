# 15. The peer group is supplied, never derived

**Date:** 2026-07-26
**Status:** Accepted; `AverageCeilingMetric` takes peers as an argument and has
no derivation path
**Source:** Matrix 2.0 Q5 (Alexandra Krížová & Jeff Highman) asks for a peer
group "sharing identical environmental or parental pauses". The refusal to
compute it is this architecture's response, confirmed by Jeff.

## Context

The Average Ceiling Metric compares what a record established per active window
against what its peers established per active window. That comparison needs a
peer group, and Q5 describes one: entities sharing identical environmental or
parental pauses.

Computing that group requires knowing who paused and why.

The record does not carry that. The only way to obtain it from the timeline is
to read the gaps — their length, their spacing, their position in a life — and
infer a cause. That is the sensitive attribute, reconstructed out of exactly the
absences this policy forbids reading, in the service of a fairness mechanism.

The failure is quiet, which is what makes it worth an entry. Nothing would look
wrong: the score stays gap-invariant, `PolicyAudit` still passes, and the
inference sits one layer away in the comparison group. A system that had learned
to sort people by inferred parental status would be passing its own
anti-discrimination audit while doing it.

This is the framework's own axiom, applied to the mechanism meant to enforce it:
**inference must not become evidence.** An inferred pause reason is an inference.
Selecting a comparison group by it makes it evidence.

## Decision

`AverageCeilingMetric#read` accepts `peers:` and there is no `peers_for`,
`similar_to`, or any other derivation. The caller names the peers on grounds the
system does not hold, and takes responsibility for having done so.

Absent peers, the metric reports the ceiling alone and says it was not compared —
`Reading#compared?` is false, `relative` is nil. It does not fall back to a
population average, because a population average is the thing Q5 rejects.

A peer contributes its **ceiling and not its length**. Comparing against how much
time someone had is the privilege comparison this metric replaces; comparing
against what they established per window is not.

## Resolution — the question this left open has dissolved

This decision closed with *"where a defensible peer group should come from is not
answered here."* It no longer needs to be.

Q5's stated concern was that **a ceiling averaged over an already-advantaged
population reproduces the bias it exists to remove**, and the peer group was
proposed as the repair. But `AverageCeilingMetric` answers that concern by a
different route: the ceiling is what a record established **per active window**,
which is a rate. Rates are comparable between records without any reference
group, because there is no population in the denominator to carry anyone's
advantage.

So the peer group solves a problem the intra-entity truncation had already
removed. `Reading#compared?` is false by default and the metric stands: a
ceiling, a count of windows, and no claim about where the record sits among
others.

That is a better outcome than the one this decision reached for. The refusal to
*derive* a peer group stands unchanged and for the same reason. What has changed
is that supplying one is now optional rather than a gap — a caller with a
defensible basis outside the system may still pass peers, and one without a basis
loses nothing by not having them.

## Consequences

The metric is less automatic. A caller who wants a comparison must construct the
group, and there is no default that quietly does it for them. That is the
intended cost.

It moves a judgement out of the code and into the open, which is the same trade
`Delegation` makes: a person decides once, about a class, on the record, rather
than the system deciding repeatedly and invisibly.

It leaves a real gap. Where a defensible peer group should come from is not
answered here, and this decision does not pretend to answer it — it only refuses
to answer it by inference. If one is ever derived, it must come from a source
outside the timeline, and that source is itself a decision worth an entry.

The narrow claim survives intact and is still the only one made: a documented gap
carries no penalty. `GapInvariance` states it, `AverageCeilingMetric` satisfies
it by reading active windows only, and `PolicyAudit` records that the check ran.
Nothing here claims the metric is fair.

## See also

- [0014 — Observed Value Priority](0014-observed-value-priority.md), the same
  observation/inference split applied to a model rather than a person
- `docs/THEORY.md` §7 — the anti-discrimination policy and §7.4's resolution
