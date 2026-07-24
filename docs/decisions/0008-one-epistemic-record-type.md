# 8. One epistemic record type

**Date:** 2026-07-24
**Status:** Accepted
**Completes:** the sequence begun in [ADR 0006](./0006-relationship-subsumes-transition.md) and [ADR 0007](./0007-flags-are-assertions.md)

## Context

`Classification` and `Resolution` were separate tables carrying the same five
things: a subject, a judgement, an `origin` (model or human), a `confidence`,
a `rationale`, and a `current` flag. Both were assertions wearing different
names.

Worse, both reproduced problems already solved elsewhere:

- **`current` was maintained by hand.** `IdentitySentinel` ran
  `resolutions.by_model.update_all(current: false)` before inserting — a manual
  bookkeeping step that supersession already expresses.
- **`origin` was stored.** Whether a judgement is an inference or a decision is
  not a property of the judgement; it is a fact about *who made it*.
- **`classifier` was a string.** `"jeff"`, `"smoke"` — an unaccountable name
  where an accountable actor belongs.

## Decision

**Merge both into `Assertion`.** It is now the single epistemic record type.

Two columns disappear rather than move:

| Was | Now |
|---|---|
| `origin` | derived from `asserter.primitive` — system means inferred, person means decided |
| `current` | `standing` — nothing has superseded it |

Assertions gain a nullable polymorphic **`object`**: the thing a claim points
*at*, as distinct from the subject it is *about*. A classification is about a
`Claim` and points at a `ClaimCategory`; a resolution is about a `Mention` and
points at a `Referent`. Keeping these as references rather than JSON keys
preserves integrity — a `ClaimCategory` something has been classified as, or a
`Referent` something has been resolved to, now refuses deletion.

## Consequences

- `classifications` and `resolutions` dropped. Rows migrated, with human
  judgements attributed to Person referents created from the old `classifier`
  strings and machine judgements to seeded System referents.
- `Claim#classify!` and the derived `#classification` / `#category` replace the
  old association. Same semantics: a person's judgement wins, the system's is
  retained.
- The execution-lock guard moved from `Classification` to `Assertion`,
  scoped to `act: "classify"`.
- `Referent#referencing_assertions` uses `restrict_with_error`, so a referent
  cannot be deleted out from under a resolution that points at it.
- Irreversible: reversing would have to discard the accountable author of every
  judgement.

## Where this lands

Four tables became one. Every epistemic act in the system — a sentinel's flag,
a reviewer's dismissal, a verdict on a transition, a classification, an
identity resolution, an employer's claim about employment — is now the same
object with one audit trail, one immutability guarantee, and one attribution
rule.

The framework's axiom is now enforced structurally rather than by convention.
There is no table in which a judgement can be recorded without an accountable
author, and no column in which one can be silently overwritten.

## What has not been merged

`Mention#status` is still a mutable column, denormalised from the resolution
assertions. It is a cache of a derived value, and it can drift. Left as is
because the Sentinel writes it inside the same transaction as the resolution,
but it is the last piece of stored state that arguably should be derived.
