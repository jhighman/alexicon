# 22. Authority is recognized, not inferred

**Date:** 2026-07-31
**Status:** Proposed — a prescriptive for a build not yet made. The build must
not begin until this status reads Accepted, because what follows reallocates
who may settle claims, and that decision is Jeff's, not an implementer's.
**Source:** The audit ADR 21 deliberately deferred. `primitive` — person,
system, or entity — is assigned from a typed string at grounding time and
permanently allocates epistemic authority. That is *inference becomes
identity* with behavioral teeth, at the layer everything else stands on.

## Context

`primitive` bundles three different claims into one mutable, unattributed
column:

1. **Kind** — is this referent a human being, a software actor, or a thing?
2. **Authority** — `Assertion#human?` reads it, so it decides whose reading
   *settles* a claim and outranks the machine's resolution of a name; and
   `Delegation` reads it, so it decides who may grant an agent the right to
   judge with nobody present.
3. **Provenance labeling** — `inferred?` reads it, so it decides whether a
   judgement renders as a decision or an inference in every report.

What the record shows, measured on 2026-07-31:

```
assertions by asserter primitive: {"system" => 4795, "person" => 3}
assertions by an "entity":        0

referents whose stored primitive contradicts the grounding rule:
  Alec       subject=Family       stored=person
  God        subject=Theological  stored=person
  Alexicon   subject=Concept      stored=person
```

**The system's own concept-referent is a person.** Under the current gates,
an assertion authored by `Alexicon` would settle claims over the machine's
majority, and `Delegation`'s check — `granted_by.primitive == "person"` —
would accept a delegation granted by a Concept. Nothing has exercised either
path; nothing prevents them.

And the column is unguarded. Flipping an entity to person is a plain
`update!` — no validation, no assertion, no trace. Demonstrated live during
this audit and reverted; the record shows neither the flip nor the reversion,
which is exactly the problem.

There is also a latent third state nobody defined: an **entity's** assertion is
neither a decision (`human?` false) nor an inference (`inferred?` false).
`ProfileReport` partitions grounded resolutions by `inferred?`, so an
entity-authored grounding would today be reported as **decided by a person**.
Zero such assertions exist; the path is open.

## Decision (prescriptive)

**Primitive remains a column — and becomes authority configuration, under the
registry's discipline.** The registry is this architecture's sanctioned
exception to derive-everything: `certification_status` is stored because it
records *who may influence judgement*, granted accountably by a named person,
never inferred. Primitive is the same species of fact about referents. What
changes is not where it lives but how it can come to be and to change.

### 1. Explicit, never inferred

`GroundMention#primitive_for` is deleted. Personhood stops being a side effect
of typing `Person` into a subject field: grounding takes an explicit
`person:` flag (default **false**), the API and browser ask it as its own
question, and the subject string carries no authority consequence of any kind.
Grounding a person becomes a deliberate act the grounder knowingly performs.

### 2. Immutable except through recognition

Direct writes to `primitive` **raise**, the same guard `system_id` already has:
kind is part of object constancy, and a kind that drifts silently is an
authority that drifts silently.

The one path is `Referent#recognize_as!(kind, by:, rationale:)`:

- `by:` must be a **person** — recognition of authority flows only from
  someone who already carries it, which is certification's shape applied to
  referents.
- It records the change as an assertion about the referent — claim carrying
  the new kind, the old kind, and the rationale — **and** writes the column,
  in one transaction. The column is the enforceable cache; the assertion is
  the accountable history. Demotion travels the identical path: revoking
  personhood is the same act with a different direction, and it leaves the
  same record.

### 3. Entities do not author

A new validation on `Assertion`: the asserter may not be primitive `entity`.
Places, concepts, and family units do not judge; any assertion attributed to
one is a modeling error, and the undefined
neither-decision-nor-inference state closes rather than being given semantics.
Zero existing assertions violate this, so there is no migration and no
grandfathering.

### 4. The root of trust is named

`User.register!` continues to create person-referents directly. That is not an
exception to §2 — it is the root: a User exists because someone holding
credentials created the account, so personhood-at-registration is vouched by
the credential layer, and the recognition chain terminates there rather than
regressing. The ADR states this so nobody later mistakes it for an oversight.

### 5. The three anomalies are decisions, not cleanup

`Alexicon`, `God`, and `Alec` are **not** silently corrected — a build that
"fixed" data would be the unaccountable flip this ADR exists to forbid. Once
`recognize_as!` exists, each is a call for Jeff to make through it, leaving a
record of who decided and why. The ADR's own position, for the record:
`Alexicon` (a Concept) and `God` (a contested ontological question, per the
README's own line) should not hold claim-settling or delegation-granting
authority; `Alec` looks like a mistyped subject on a real person. Deciding is
not the build's job.

## Acceptance criteria (the build is done when these are specs)

1. A direct `update!` of `primitive` raises; the demonstrated silent flip is
   impossible.
2. `recognize_as!` by a person changes the kind and records who, from what, to
   what, and why — one transaction, both visible.
3. `recognize_as!` by a system referent is refused. An agent cannot mint a
   person.
4. An assertion whose asserter is an entity is invalid.
5. Grounding with `person:` absent creates an entity, whatever the subject
   string says — including `Person`.
6. Grounding with `person: true` creates a person, and the grounding's
   attribution (ADR 19/21) already records who made that call.
7. Demotion by recognition removes settling and granting authority in the same
   act that records it.
8. Zero historical rows rewritten, zero assertions destroyed — verified by
   digest, before and after.

## What this deliberately does not decide

- **Whether the three anomalies are reclassified**, and to what. Jeff's, per
  §5, after the build.
- **Recognition chains.** `by:` must be a person; whether personhood should
  require *n* recognizers, expiry, or TEI-style scrutiny scaling with what the
  recognized party may then do — real questions, out of scope until a second
  person exists in the record's daily operation.
- **The two Alexandras.** Still a grounding call, still a person's.
