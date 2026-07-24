# 4. The framework is data, not constants

**Date:** 2026-07-24
**Status:** Accepted
**Decided by:** Claude, under delegated judgement.

## Context

Two facts about this project, observed rather than assumed:

1. **The framework has already moved once.** G3/G7 (three columns, seven layer-indexed stations) became Alexicon 2.0 (seven human-level domains). Station numbers became domain names; the transformer-internal vocabulary was dropped.
2. **The vocabulary drifts.** Documented so far: four non-identical epistemic ladders; Average Ceiling Metric vs. Equitable Baseline Scoring stated in both containment directions; "Jekyll Mask" and "Hyde effect" named only in later material; "I-strengths" as an imprecise rendering of Eide & Eide's *Interconnected reasoning*.

Encoding any of this as Ruby constants or an ActiveRecord enum means a migration every time the framework is refined — and it will be refined.

## Decision

**Seed the framework as rows. Version it. Store the terminology register.**

- `frameworks` is versioned, with one marked `current`.
- `domains`, `claim_categories`, `flow_stages` all belong to a framework. Two versions coexist, and claims classified under an older vocabulary stay meaningful.
- `terms` + `term_aliases` hold the register, with a `disputed` status.

That last point matters more than it looks. A disputed term is recorded **as disputed** rather than silently resolved — which is the same discipline the system applies to claims. A framework whose axiom is *inference must not become evidence* should not quietly promote one of two contradictory definitions to canonical because a schema forced a choice.

`equitable-baseline-scoring` and `average-ceiling-metric` are both seeded `disputed` today.

## Consequences

- Renaming a domain, adding an eighth, or revising the ladder is a `db:seed` run.
- Reference data is queryable: *which terms are disputed?* is a question the system can answer about itself.
- Cost: more joins, and no compile-time safety on `Domain.find_by(key: "governance")`. Accepted — the alternative is a migration per rename.
- The epistemic ladder is scoped per framework, so the four variants can coexist as separate rows rather than one being declared correct by fiat.
