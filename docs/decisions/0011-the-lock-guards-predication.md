# 11. The identity lock guards predication, not description

**Date:** 2026-07-25
**Status:** Accepted
**Supersedes:** the reading of the Sentinel Principle implied by the original
`execution_must_not_be_locked`

## Context

The code read:

> Nothing may be predicated of an ungrounded subject, **so** a claim in a
> document with open identity STOPs cannot be classified at all.

That "so" is a leap, and it made the system unable to read ordinary prose. One
21,000-character essay produced **204 blocking questions across 144 distinct
names** and not one of its 244 claims could be typed.

The names were not exotic. They were `Fortunately`, `Wow`, `Part Two`,
`Ironically` — and `Michael Polanyi`, `David Goggins`, `Dead Poets Society`.

## Decisions

### Classifying a claim is not predicating something of the names inside it

Classification asks *what kind of statement is this?* That does not depend on
who a name refers to. *"Polanyi said we can know more than we can tell"* is an
objective claim whichever Polanyi it is. *"Therefore God exists"* is ontological
whether or not `God` will ever carry a Cognitive Passport — and it will not,
because that is a contested ontological question, not missing data.

A gate that demands resolution before typing a sentence cannot process
philosophical or religious prose at all, which is a large share of what this
framework is for.

### The lock guards judgements about a *step* between claims

That is where reasoning about the referents actually happens. `GovernanceSentinel`
and `DomainSentinel` still call `require_executable!`; `DocumentClassification`
deliberately does not.

### The guard is the subject, not a list of acts

It cannot be expressed as acts. A governance verdict is recorded as `assert` —
the same act used for a dozen harmless things — and `resolve`, the act that
grounds a name, would deadlock, blocked by the very flags it clears. So the
validation asks whether the subject is a `Relationship`.

### Identity accumulates in the graph, not in the document

Writing does not introduce the people it names. An essay citing Polanyi assumes
you know him. Requiring the document to establish identity requires prose to be
self-contained in a way it never is.

So a name is asked about **once**, however often it appears and in whichever
document, and the answer applies wherever the name occurs.

## Rejected

**Narrow the lock to the claim rather than the document.** Measured: 132 of 244
claims still blocked. It does not rescue the case.

**A confidence threshold — proceed when 80% of names resolve.** The threshold is
a number nobody can justify, and it lets unresolved names through silently,
which is worse than either alternative.

## Consequences

A document is readable while its identity questions are outstanding, and the
reading view says so rather than implying a clean bill of health. Governance —
the output actually worth a person's attention — still waits on the answers,
which is the friction this decision preserves on purpose.
