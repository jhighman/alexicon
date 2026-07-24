# 6. Relationship subsumes Transition

**Date:** 2026-07-24
**Status:** Accepted
**Supersedes:** the open question left by [ADR 0005](./0005-referent-not-entity.md)

## Context

Two constructs existed with the same shape:

- **Relationship** — a governed edge between Referents, with lifecycle, evidence, and standing derived from assertions.
- **Transition** — a governed edge between Claims, with a *stored* `verdict` column and a `score`.

The stored verdict was an inconsistency of our own making. Chapter 4 argues that current state conceals the sequence of accountable claims that produced it, and `Relationship` was built without a status column for exactly that reason. `Transition` kept one.

## Decision

**Merge them. `Transition < Relationship` via single-table inheritance, with polymorphic endpoints.**

An edge may now join `Referent → Referent` (employment) or `Claim → Claim` (an epistemic transition). Standing derives from assertions in both cases.

**`verdict` and `score` are no longer columns.** A sentinel *asserts* that a transition was earned or unearned:

```ruby
transition.record_verdict!("unearned", asserter: sentinel, score: 0.12,
                           rationale: "confidence exceeds the evidence class presented")
```

That judgement is attributable, evidenced, supersedable, and open to challenge like any other assertion. `"undetermined"` is the *absence* of such an assertion, so a system that has not yet judged says so rather than manufacturing a verdict.

## Consequence: this widens the thesis

Chapter 3 defines Relationship as a connection between ontological primitives. A Claim is not one of the five primitives, so a Transition is not literally a Chapter 3 Relationship.

**The generalisation is deliberate.** Chapter 3's load-bearing insight is not *what* relationships connect but *that* a governed connection is an independently governable object with its own lifecycle and evidentiary requirements. That property holds regardless of endpoint type. `Relationship` in this codebase therefore means *any governed edge*, which is broader than the thesis's primitive.

If that widening turns out to be wrong, the fix is to reintroduce a narrower `PrimitiveRelationship` subclass rather than to unpick STI.

## Consequences

- `transitions` table dropped; rows migrated into `relationships` with `type = 'Transition'`.
- Polymorphic `flaggable_type` and `subject_type` store the STI **base** name, so flags and assertions that pointed at `'Transition'` were repointed to `'Relationship'` during migration.
- `Document#transitions` is derived from its claims rather than owned — an edge belongs to its endpoints, not to a container.
- `Claim` and `Referent` associate via `as: :source` / `as: :target`, and use `restrict_with_error`: an endpoint that has been asserted about cannot be deleted.
- The base class writes its own STI `type`, so the column is never NULL and "what kind of edge is this?" is answerable in SQL.
- The migration is **irreversible**. Reversing would have to invent the assertions that produced each verdict.

## What did not merge

`SentinelFlag` remains distinct from `Assertion`, though both are accountable records about a subject. A flag is a *governance signal with a disposition* — open, accepted, rejected — that a person acts on; an assertion is an immutable claim. Whether the flag should itself become an assertion with a disposition asserted over it is the next question of this kind, and is not answered here.
