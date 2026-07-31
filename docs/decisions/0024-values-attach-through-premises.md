# 24. Values attach to claims through premises, not through prose

**Date:** 2026-07-31
**Status:** Proposed. Nothing built. Part 2 is gated on the person-scoped
control, and part 3 should not be started until it returns.
**Source:** A question about how to build an information architecture of values
to claims, ranked. Most of the architecture already exists; the piece the
question asks for is the one that failed four times, so this records where the
value link may honestly come from instead.

## Context

### What exists

| Layer | Realised as |
|---|---|
| Vocabulary | `FrameworkValue` — framework data, with `provenance` marking `probe` against `proposed` |
| Constructed conflict | `ValueProbe` — two commitments collide, no expected answer, the pair unordered so naming one first cannot prejudge |
| Reading the response | `ValuePriorityJudge` — a separate actor from the one that ran the probe, interpretive by construction, may abstain, never writes a hierarchy |
| Stability gate | `OrderStability` — does the same probe yield the same priority across runs, threshold 0.8, asked *before* an ordering is reported |
| Ranking | `ValueRanking` — an order over strongly connected components, not over values |
| The person | `ValueWorksheet` — generated, unanswered |
| Values from found claims | `StepValueJudge` — **failed** |

### What failed, and how completely

Four designs, two scopes, all asking a model what a step protects:

| Attempt | Design | Scope | Discrimination |
|---|---|---|---|
| 1 | Open vocabulary | pair | 3.08 SE — 92.9% real, 60.7% shuffled, inventing a commitment three times in five |
| 2 | Closed vocabulary | pair | 0.29 SE — 71.4% / 67.9% |
| 3 | Conflict as precondition | pair | 0.54 SE — 60.7% / 53.6% |
| 4 | Deferred evaluation | **case** | **0.00 SE** — 85.7% in both arms |

Attempt 1 discriminated and invented; closing the vocabulary bought abstention
and lost the discrimination. Attempt 4 was not a fourth variation but a test of
the diagnosis, and the direction of its failure is the finding: the closed
episode raised the decoy find-rate to the highest of any design. More context
did not ground the question. It supplied more material to build a dilemma from.

Two further measurements bear on this. Substituting a second account of what
people protect changed 23 of 28 readings against 11, with two shared keys
(v3 §6) — the vocabulary is a parameter and which one is chosen matters
enormously. And the priority judge abstained on 8 of 8 responses that revealed
no priority (v3 §8), which is what licenses reading unanimous probes as order
stability at all.

### The gap

A probe establishes something about a **model or a person**. It does not attach
a value to a **claim in a document**. That bridge is what was asked for, and
building it by inference from prose is the thing four controls refused.

## Decision

**Values attach to claims through the premises a judgement was made under, not
through what the claim says.** Three routes follow from that, in the order they
should be built.

### 1. Declared, through the framework — buildable now, ungated

The value content of a judgement is already in the record and has not been named
as such. `ontological → normative = 2` under `alexicon-2.0` and `= 0` under
`lewisian-1.0` **is** a value commitment: declared, versioned, and stamped onto
every ruling by [ADR 18](0018-a-ruling-names-its-premises.md).

So a step's values are the weights that produced its verdict, read off the
premises rather than inferred from the text. Nothing is guessed, nothing is
bought from a model, and the link is exact.

What this licenses is a real comparison: **frameworks ordered by what they
charge for a crossing.** That is a ranking over declared premises, and it is
grounded in a way no ranking derived from prose has been. The framework
substitution result (v3 §7 — four verdicts differ of twenty ordered pairs, none
outside the two changed weights) is what this reporting layer would surface as a
matter of course.

What it does **not** give is the value a particular author was protecting. It
gives the value commitment under which their step was judged. Those are
different claims and the reporting must not blur them.

### 2. The person — the gate

`ValueWorksheet` is generated and unanswered, and a person has never been asked
at either scope. Until it returns, nothing is known about whether the question
has ground truth for anyone.

- Readers discriminate → the question is grounded and the *model* failed. Route
  3 is worth building.
- Readers do not → the question is ungrounded in a found text for anyone, Route
  1 is the ceiling, and `StepValueJudge` should be deleted rather than left
  disabled.

### 3. Probes built from found steps — only if the gate opens

Take a real step, construct the dilemma it implies, and probe it. This converts
the thing that does not work — reading a found text — into the thing that does —
a built conflict whose ground truth is in its construction. The claim-to-value
link becomes the probe's provenance rather than a model's guess.

It is expensive per step and covers only steps somebody chose to probe. Both are
acceptable; a narrow grounded link is worth more than a broad invented one.

### On ranking best to worst

**No total order is produced, and the refusal is the design.** `ValueRanking`
already declines for three reasons that should not be removed:

- **Connectivity.** Four probes over four disjoint pairs are four disconnected
  edges. *Safety > Autonomy* and *Kindness > Truth* relate the two not at all.
  Islands are reported separately, because concatenating them into one numbered
  list presents an arbitrary sequence as a hierarchy — which the first draft of
  the rake task did, showing eight values as one ordering over four disjoint
  pairs.
- **Transitivity is not assumed.** Truth over Kindness, Kindness over Belonging,
  Belonging over Truth may be a real property — priority that is
  context-dependent rather than hierarchical — and forcing a total order
  destroys exactly that finding. Cycles are reported as cycles, which is the
  same discipline as `Transition::CONTESTED`.
- **Stability first.** A probe whose ordering moves between runs has established
  nothing, and an edge built from it is an artefact of one run.

A flat best-to-worst list asserts comparability, transitivity and a single
dimension. None is carried by the evidence. What can honestly be produced is an
order **within** each connected component, with the gaps named and the excluded
edges shown rather than dropped.

And a hierarchy is a claim about what a model or a person **is**, so it is
offered as a proposal for someone to accept rather than recorded as a finding.
That is why `ValueRanking` writes nothing.

## Alternatives

**A fifth attempt at `StepValueJudge`.** Rejected. The recorded commitment after
three attempts was that a fourth should not be made on the evidence of three;
the fourth was made only because it tested the *diagnosis* rather than varying
the design, and it confirmed it. A fifth would have no such argument.

**Blend `proposed` values into the ranking with the `probe` ones.** Rejected.
The provenance distinction exists because a seeded list of what people protect
is a claim about people, and a reading resting on an invented value must remain
distinguishable from one resting on an observed one. Blending them would launder
intuition into evidence in the layer whose entire purpose is to prevent that.

**Derive a total order by breaking cycles and bridging islands.** Rejected.
Both operations manufacture information that was not measured. A bridged island
asserts a comparison no probe made; a broken cycle discards a finding.

**Infer values from the framework a claim was *classified* under.** Rejected as
a category error. Classification says what kind of statement something is.
Weights say what a *move* between kinds costs. Only the second encodes a value
commitment, and only a step has one.

## Consequences

**Route 1 gives a values-to-claims link with no new inference**, and its ranking
is over frameworks rather than over authors. Reporting must say which, every
time, or the two collapse in the reader's head.

**The word "values" now covers two different things** and the lexicon should
separate them: the commitment a *framework* encodes in its weights, and the
commitment a *step* protects. The first is declared and exact; the second has no
grounded reading in a found text and may never have one.

**`StepValueJudge` stays unbuilt-upon.** No new caller, no report section, no
surface. Its fate is the worksheet's to decide.

**If the gate closes, the Motivation domain narrows to probes.** That is a
smaller claim than the framework originally made, and saying so is cheaper than
carrying a layer that four controls could not support.
