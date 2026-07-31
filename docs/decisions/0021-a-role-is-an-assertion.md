# 21. A role is an assertion

**Date:** 2026-07-31
**Status:** Accepted by Jeff, 2026-07-31, and built to the criteria as written.
One stated deviation: seeds still write the legacy column for **system**
referents (sentinels, judges) — framework fixtures whose roles are structural,
not epistemic claims about a person; asserting them on every idempotent re-seed
would mint duplicate assertions. The runtime paths named in §3 write only
assertions.
**Source:** Alexandra Krížová's addendum — current systems collapse her into
"caregiver" — and Jeff's separation of it into identity persistence, context
weighting, and protective alignment, under one invariant: *do not allow
incomplete evidence to harden into identity, intent, or judgment prematurely.*

## Context

The invariant is already this system's organizing principle everywhere except
the identity layer. Categories, verdicts, dispositions, orderings — all derived
from standing assertions, all refusing to harden without warrant. Identity is
the exception, three ways at once:

- **`referents.role` is one mutable string.** The Cognitive Passport is
  `Name → Subject → Role`, singular. The record holds `Alexandra Krížová:
  Collaborator` and cannot also say co-author, engineer, or author of the only
  value instrument that survived measurement. Multiplicity is not suppressed;
  it is inexpressible.
- **`Referent` is the only epistemic construct stored as mutable columns**
  rather than derived from accountable assertions. Who somebody is, is a plain
  `update!` — unattributed, unversioned, uncontestable.
- The record demonstrates the cost: referents 67 (`Alexandra`) and 49
  (`Alexandra Krížová`) are two people in the database and one person in the
  world. Object constancy failed on the co-author.

The repair is not a `roles` array. It is applying the house rule to the one
layer that never got it.

## Decision (prescriptive)

**A role becomes a standing assertion about the Referent.** Attributable —
*Jeff says she is the co-author* — contestable, supersedable, and plural by
construction. The passport becomes `Name → Subject → Roles(standing, ≥ 1)`.

### 1. The derived read

- `Referent#roles` → the role named by each **standing** role assertion
  (`act: "assert"`, subject: the referent, claim carrying `"role"`), plus the
  legacy column treated as one unattributed role (§4).
- `Referent#role` becomes a **method** — the legacy column value, else the
  earliest standing role — kept so every existing display renders unchanged.
  No caller may branch on it; none does today, and a spec pins that the method
  is presentation-only by asserting nothing in `app/` reads it outside views,
  serializers and reports.

### 2. Multiplicity semantics — deliberately NOT the contested machinery

Roles are not competing answers to one question. *Engineer* and *caregiver* and
*exhausted* coexist; there is no majority to take and no `CONTESTED` state,
because two roles do not contradict. What CAN be disputed is one role
assertion — *is she actually an engineer?* — and that is the existing
challenge/supersession machinery, unchanged: a challenged role reads
`disputed`, a superseded one stops standing, nothing is deleted. The spec that
guards this boundary: adding a second role never changes the standing of the
first.

### 3. Writes

- `Referent#assert_role!(role, by:, rationale: nil)` — the only write path.
  Recorded beside, never over.
- A role is retired by a **superseding** assertion, never by destroy. An
  identity claim that was wrong is answered, not erased — ADR 19's rule,
  applied forward.
- `GroundMention` keeps its API (`subject:`, `role:`) and writes the role as
  an assertion **attributed to `by:`** — the person or agent who answered the
  STOP — in the same transaction that creates the referent. The column is not
  written for new referents.
- `User#referent` bootstrap self-asserts its role (*Jeff says Jeff is Admin*):
  attributable and honest, and the chicken-and-egg (an assertion needs an
  existing asserter) resolves inside one transaction — create the referent,
  then the self-assertion.

### 4. Migration — none, and that is the decision

No backfill. The existing role column values are **unattributed**: the record
does not say who decided `Mom → Mother`, and inventing an asserter to make the
data look modern is exactly what ADR 19 refused. The legacy column becomes
read-only-in-practice (no code path writes it), reads as one role whose
attribution is absent — the same key-absent honesty as `grounded` — and reports
say "recorded before roles named their asserter" where it matters. No schema
change in this build; dropping the column is a later decision once no referent
depends on it.

### 5. The passport invariant survives intact

A referent with **zero** roles — no standing assertion, empty legacy column —
is `unanchored`, exactly as a blank role column is today. `ReferentResolver`'s
missing-check moves from `role.blank?` to `roles.empty?`. A partial passport
remains no anchor, not a weaker one.

### 6. Surfaces

- Reports and CLI display all standing roles, ` · `-joined, oldest first.
- The profile's identity section keeps its shape; where a legacy-only role is
  shown, its missing attribution is stated, not implied away.
- `IdentityProposer` is untouched: a proposal was never a resolution and its
  proposed role only becomes an assertion when a person accepts — which is the
  front-door guard already working.

### 7. Acceptance criteria (the build is done when these are specs)

1. Three roles stand on one referent simultaneously, each with its own
   asserter.
2. Challenging one role disputes that role and leaves the others standing.
3. Superseding a role retires it without deleting it; history shows both.
4. A referent with no roles is refused by the resolver as `unanchored`.
5. Grounding attributes the role to whoever answered, never to the Sentinel
   (ADR 19 continuity, spec'd against both a person and an agent).
6. A legacy referent renders identically to today, and its report line states
   that the role's attribution predates this decision.
7. Nothing in `app/` outside presentation reads `#role`; behavior reads
   `#roles` or neither.
8. 0 destroyed assertions, 0 fabricated asserters, 0 rewritten rows —
   verified against the record before and after.

## What this deliberately does not decide

**The authority gate.** `primitive` — person or entity — is assigned from the
`subject` string at grounding time and permanently allocates the right to
settle claims (`human?`) and to grant delegations. That is *inference becomes
identity* with behavioral teeth, and it is a bigger decision than roles: making
it an assertion means the right to judge becomes revisable, and whoever may
revise it holds the keys to everything downstream. That is an ADR of its own,
and the decision in it is Jeff's. This build must not touch `primitive`,
`subject`, or any authority path — scope creep there is a reason to reject the
diff.

**The two Alexandras.** This build supplies no merge. Declaring referent 67
another name for 49 is a grounding decision — a person's, through the existing
alias mechanism, after which their roles union the way standing assertions
already do.

## Consequences, if accepted

Identity becomes the last construct to obey the system's own rule: nothing
stored that can be derived, nothing asserted without an asserter, nothing
erased that can be answered. The failure she described stops being
inexpressible-to-refuse — a system asked to collapse her into "caregiver" would
have to *supersede five standing assertions with named authors*, and the record
of doing so would itself be the finding.
