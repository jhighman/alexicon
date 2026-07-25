# 12. The model proposes identities; a person disposes

**Date:** 2026-07-25
**Status:** Accepted
**Extends:** [ADR 9](0009-ingest-is-deterministic.md) — *the extractor proposes;
the Sentinel disposes*

## Context

The granularity was inverted. A regex proposed names, so a person was handed 75
questions for one essay — `Wow`, `Part Two`, `Ironically`, and also
`Michael Polanyi`, `David Goggins`, `Bad Brains`. Every one of those a language
model answers instantly, and it was never asked.

Meanwhile the model was sorting single sentences into four buckets: 244 calls
for a 21k-character document, 332k of prompt resent, one sentence per call with
no sight of the argument around it.

**The model was doing the easy work and the person the hard work.**

[ADR 9](0009-ingest-is-deterministic.md) says segmentation and extraction use no
model, and that stands — those decide what counts as a claim, and every later
judgement inherits it. Naming what a string refers to is a different question:
it is world knowledge, and it is downstream of the binding rather than
underneath it.

## Decisions

### The Identity Proposer reads the whole document

A name is identified by its context, so asking about a surface form in isolation
throws away what would answer the question.

### It proposes; it never resolves

Every proposal is an assertion by the `identity-proposer` referent — inference,
attributable, challengeable. **Nothing it says lifts a STOP.** The form arrives
pre-filled and a person accepts under their own name.

### It is not the Sentinel that would accept it

An actor that proposed the ground and then accepted it would be the conflation
Chapter 6 forbids. `identity-proposer` and `identity-sentinel` are different
referents with different roles.

### It refuses in three ways rather than inventing

- a name it does not recognise → `unknown`, recorded as nothing
- a `subject` whose passport is incomplete → downgraded to abstention, because
  a half-anchor is no anchor
- a name it was never asked about → discarded

### Classification is batched with context

Twelve claims per call, plus four preceding ones the model must not classify.
One sentence per call threw away the argument it sat in — and it showed: every
confidence came back `1.0`, so the abstention floor was decorative.

Measured after batching: 127 proposals at 100%, 71 at 90%, 15 at 80%, and 31
abstentions. Giving the model something to be uncertain about produced
uncertainty.

## Rejected

**A confidence floor that auto-resolves identity.** A model's identity guess
would become operational fact — precisely what the Sentinel exists to prevent.
Observed rates make this worse, not better: 70 of 75 proposals came back at
exactly 100%, so a floor would gate nothing.

**Let the model clear only the noise, and send real people to a human.** Half
the benefit, and it still requires the model to decide which is which — the same
judgement, with the record of it thrown away.

## Consequences

75 questions become a reviewed list. On the first live run the proposer returned
31 subjects and 44 not-a-subject, and correctly linked `Polayani → Polanyi` and
`Goggins → David Goggins`.

It is confidently wrong sometimes — it proposed `B- → Organisation → Band` at
100%. That is what the human acceptance step is for.
