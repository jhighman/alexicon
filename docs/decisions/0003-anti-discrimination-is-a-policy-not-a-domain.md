# 3. The anti-discrimination protocol is a cross-cutting policy, not a domain

**Date:** 2026-07-24
**Status:** Accepted
**Decided by:** Claude, under delegated judgement.

## Context

The anti-discrimination protocol is the framework's most concrete and most testable component, and the one with the most direct effect on real people:

> A gap in a record is an absence of evidence, not evidence of degradation.

It has no home in the seven domains. It touches Identity (a stable subject across a discontinuous record), Reflection (temporal reasoning), and Governance (refusing to promote inference to finding) — and belongs to none of them.

## Decision

**Model it as a `Policy` that binds to multiple domains.**

Considered and rejected: making it an eighth domain. That would break a seven-domain structure already published, and would misdescribe it — a domain asks a question, whereas this asserts a constraint.

Policies are a distinct kind: named, stated, rationalised, and joined to any number of domains.

## Consequences

- `policies` + `domain_policies`, seeded with `anti-discrimination` bound to Identity, Reflection, Governance.
- More policies can be added without touching the domain structure.
- The policy statement is stored as text, so it can be quoted verbatim in a flag or an audit rather than paraphrased.

## Caution carried forward

Source material claims this produces judgement "stripped of statistical biases." That claim does not survive contact with the fairness literature — demographic parity, equalised odds and calibration are provably not simultaneously satisfiable outside degenerate cases, so any implementation *chooses* which criterion to honour.

The defensible claim, and the one the seeded statement makes, is narrower: **this specific penalty is identified, made explicit, and removed.** Naming the chosen fairness criterion is a requirement before this is implemented, not a detail.
