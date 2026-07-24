# 7. Flags are assertions

**Date:** 2026-07-24
**Status:** Accepted
**Answers:** the question left open by [ADR 0006](./0006-relationship-subsumes-transition.md)

## Context

`SentinelFlag` was a separate table with a mutable `disposition` column and no
asserter at all. Two problems, both structural:

1. **`dispose!` overwrote governance history.** Accepting or rejecting a flag
   mutated the record. Under the Assertion Principle that is precisely wrong —
   an error is answered, not erased, and a reviewer's judgement is itself a
   claim someone should be accountable for.
2. **A flag had no author.** It recorded a domain, not an actor. A governance
   signal with no accountable author is the ungrounded claim the architecture
   refuses everywhere else.

A flag *is* a claim about a subject: "the conditions for proceeding have not
been satisfied." That is an assertion.

## Decision

**Merge `SentinelFlag` into `Assertion`.**

- A flag is an assertion with `act: "flag"` and a claim carrying `severity`
  and `message`.
- **Disposition is a further assertion about the flag**, using the recursion
  assertions already support: `act: "accept"` or `"reject"`, with the flag as
  subject. `"open"` is therefore the *absence* of a disposition, not a stored
  default — the same shape as `"undetermined"` for a transition verdict.
- **Sentinels become referents.** Each domain gets a seeded System referent
  (`identity-sentinel`, `governance-sentinel`, …) bound to the domain it
  serves. Flags are attributed to it.

The audit trail is now uniform: `flag(8) ← reject(9) by Jeff`, both immutable,
both attributable, both challengeable.

## Consequences

- `sentinel_flags` dropped. Existing flags and dispositions migrated into
  `assertions`, attributed to a sentinel derived from each flag's domain.
- `referents` gain `key` (stable lookup for seeded sentinels) and `domain_id`.
- `Mention#flags`, `Relationship#flags`, `Document#flags` derive from
  assertions. `Document#open_stops` resolves disposition in Ruby, since it
  depends on assertions *about* assertions and is not a single SQL predicate.
- A flagged mention can no longer be deleted (`restrict_with_error`), because
  deleting it would erase the governance history explaining why it was blocked.
  **Practical consequence: a document that has been flagged is not destroyable
  while its flags stand.** That is consistent, and it will be felt.
- Severity is validated on assertions with `act: "flag"`, so a flag cannot
  carry a severity nobody recognises.
- The migration is **irreversible**: reversing would collapse a history of who
  disposed of what back into one mutable column.

## What this buys

Every governance act in the system is now the same kind of object. A sentinel's
flag, a reviewer's dismissal, a verdict on a transition, and an employer's
claim about employment are all immutable, attributed, evidenced, supersedable
assertions. There is one audit trail rather than three, and the framework's own
axiom — inference must not become evidence — applies uniformly to the
architecture's own governance, not merely to the claims it governs.
