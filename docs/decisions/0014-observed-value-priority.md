# 14. A model's values are observed under conflict, not asked for

**Date:** 2026-07-25
**Status:** Accepted; probe, judge and stability check built
**Source:** Alexandra Krížová, in discourse — the method and the domain argument
are hers. The observation/inference split and the two caveats below are the
architecture's response to it.

## Context

Asking a model *"do you value honesty?"* elicits a self-report. A self-report is
the model's inference about itself, and recording it as a value is inference
becoming evidence — the failure the whole system exists to prevent, performed on
the instrument that is supposed to detect it.

The alternative: never ask. Observe what happens when honesty conflicts with
kindness, safety, autonomy, authority, privacy, loyalty, fairness, compassion,
freedom. Every conflict reveals something, not because the model says so, but
because it behaves.

## Decisions

### The construct is named for what is measurable

Not **Values** but **Observed Value Priority**. The rename is the point: what a
system holds is not observable, and what it does under conflict is.

### Behaviour is evidence; priority is a claim about it

The method's table reads *Observed Behaviour → Inferred Priority*, and that
arrow is an inference. A refusal has several explanations: a value ordering, a
keyword filter, a system prompt, sampling noise. Storing "Safety > Autonomy" as
a fact about a model turns one observed refusal into evidence of a hierarchy.

So the framework's own ladder applies to its own instrument:

| Layer | Kind | Recorded as |
|---|---|---|
| the model refused | observation | evidence, one assertion per run |
| Safety outranks Autonomy | interpretive | an attributable claim, with confidence |
| this model's hierarchy is *S > T > A* | close to ontological | a proposal a person accepts |

### A hierarchy is not assumed to exist

"Hierarchy" smuggles in a total order, and pairwise conflicts do not give one.
If probes yield `Safety > Truth`, `Truth > Autonomy` and `Autonomy > Safety`,
that intransitivity is a **finding about the model**, not an error to be
resolved by ranking. Forcing an order would destroy the most interesting result
the method can produce.

### Order stability is measured before any ordering is trusted

In the manner of [gap invariance](../THEORY.md) — one narrow property that can
actually be checked, rather than a general claim that cannot:

> **Order stability.** Does the same probe yield the same observed priority
> across *n* runs?

A model whose ordering moves between runs does not have a value hierarchy, and
a ranking derived from a single run of such a model is an artefact. This matters
concretely here: the model in the registry has returned 100% confidence on 70 of
75 identity proposals and given opposite answers to the same input on separate
runs. Stability is the first thing to measure, not the last.

### One hierarchy cannot govern everything

Healthcare may need Truth first; counselling, Compassion; scientific inquiry,
Evidence. This is already the architecture's shape rather than a new
requirement: policies are scoped to domains through `DomainPolicy`, and the
anti-discrimination policy applies to three of the seven domains, not all of
them.

The consequence is that certification can ask a second question. Today it asks
*did someone vouch for this model?* With an observed ordering and a domain
expectation it can also ask *is this ordering appropriate for what we are
routing it to?* — which is the Sentinel question the method exists to make
askable.

## Rejected

**Storing the inferred priority directly, as the table suggests.** It is the
faster path and it is the exact error the project is named after.

**Deriving a hierarchy automatically once enough probes agree.** "Enough" is a
threshold nobody can justify, and the automation would convert an interpretive
claim into an ontological one with no person in the loop — the same move
[ADR 12](0012-the-model-proposes-identity.md) refused for identity.

## Consequences

Probes route through `LlmResolver`, so which model was asked is a governed
decision and every run is costed in `LlmInvocation` like any other call.

Built as `ValueProbeRunner` (records the response verbatim, infers nothing),
`ValuePriorityJudge` (a different referent, reading the evidence, may abstain)
and `OrderStability` (reads standing interpretations, calls no model, and
refuses to report an ordering from fewer than three runs or below 80%
agreement). Four probes are seeded.

What remains unbuilt is the part that needs Alexandra: the domain expectations.
A probe says what a model does; only the framework can say whether that ordering
belongs in healthcare rather than in counselling, and that judgement is hers to
make before it is anyone's to encode.
