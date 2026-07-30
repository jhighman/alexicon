# Lexicon

**The vocabulary of the Alexicon, from the record · 114 terms · July 30, 2026**

*Generated. Re-render with `rake alexicon:lexicon`.*

Every term the system actually uses appears here, because the list is read from
the framework's own data and from the constants that define its acts, verdicts
and roles. Adding a category or a delegated act fails the test suite until the
word is defined, which is what makes this exhaustive rather than merely long.

Each term sits in exactly one cluster and has exactly one kind. Where two terms
share a word — and several do — both say so and say what separates them. The
vocabulary is not non-overlapping; it is not allowed to overlap **silently**,
which is the same distinction the framework draws everywhere else.

| Cluster | Terms | |
|---|---|---|
| [The record](#the-record) | 18 | One record type, and what can be said with it. |
| [Identity](#identity) | 13 | Who or what a name refers to, and what may be said of it. |
| [Kinds of claim](#kinds-of-claim) | 11 | What a statement DOES, never how true it is. |
| [Steps between claims](#steps-between-claims) | 7 | The unit of governance is the move, not the claim. |
| [What a step protects](#what-a-step-protects) | 21 | Beneath judgement: the commitments a move puts first. |
| [Who decides](#who-decides) | 20 | Attribution, capability, and delegated judgement. |
| [Measurement](#measurement) | 6 | What the system has established about itself. |
| [The framework](#the-framework) | 18 | The seeded structure everything above is read against. |

## The record

*One record type, and what can be said with it.*

### Accept

*act*

Dispose of a flag by letting what it flagged stand.

### Amend

*act*

Restate an earlier assertion without erasing it.

### Assert

*act*

State something, on the record, as oneself.

### Assertion

*record type*

The only record type there is. An accountable claim by someone, about something
— including about another assertion, which is what makes the record recursive.
Immutable once written: `readonly?` is `persisted?`. `app/models/assertion.rb`

**Distinct from **Assertion (flow stage)**, which is a step in the epistemic
flow rather than a row. The record type is what the system stores; the flow
stage is what a person does.**

See also: Standing, Superseded, Act.

### Challenge

*act*

Dispute an assertion. The disputed assertion stands until disposed.

### Classify

*act*

Say what kind of claim something is.

### Concern

*severity*

Worth answering. Blocks nothing.

### Delegate

*act*

Grant that a class of judgement may be made with nobody present.

### Derived

*principle*

Computed from standing assertions at read time, never stored. `Claim#category`,
`Transition#verdict`, `Mention#status` and `Assertion#disposition` are all
derived. A stored summary can disagree with what it summarises; a derived one
cannot.

See also: Standing.

### Evidence

*record type*

Material attached to an assertion in support of it. Linked rather than embedded,
so the same evidence can support more than one claim and be found from either
end. `app/models/evidence.rb`

### Flag

*act*

Raise something for attention, at a severity.

### Notice

*severity*

Worth seeing. Blocks nothing.

### Reject

*act*

Dispose of a flag by setting aside what it flagged.

### Resolve

*act*

Say what a name refers to.

### Revoke

*act*

Withdraw an assertion, leaving the withdrawal visible.

### Standing

*state*

An assertion nothing has superseded. `Assertion.standing` is the scope
everything derived reads from — a superseded assertion is kept and stops
counting. `app/models/assertion.rb`

See also: Superseded, Derived.

### Stop

*severity*

Blocks governance until a person disposes of it.

### Superseded

*state*

Replaced by a later assertion that names it. Nothing is overwritten and nothing
is deleted, so a changed judgement leaves both readings in the record and the
change is itself visible.

See also: Standing.

## Identity

*Who or what a name refers to, and what may be said of it.*

### Ambiguous

*mention status*

Several candidates, or a surface form with non-entity senses.

### Cognitive Passport

*concept*

`Name → Subject → Role`. What must be established before anything may be
predicated of a name. A partial passport is not a resolution.

See also: Entity Noise, Mention.

### Entity Noise

*concept*

A name arriving without established reference. Nothing may be predicated of it
until it resolves — and refusing to guess is the point, so the resolver is
deterministic rather than model-backed.

### Executable

*state*

A document with no open identity STOP. Governance may run; until then it may
not. `Document#executable?`

See also: Identity STOP.

### Identity STOP

*concept*

The flag raised when a name cannot be resolved. It blocks **governance** and not
classification: the lock guards predication, not description. ADR 11.

**Distinct from **Stop (severity)**, which is the severity level a flag carries.
An identity STOP is a particular use of it.**

See also: Entity Noise, Executable.

### Mention

*record type*

One occurrence of a name in a document, before anyone has said what it refers
to. Extraction proposes; a person disposes. `app/models/mention.rb`

See also: Cognitive Passport, Identity STOP.

### Out of distribution

*mention status*

No match in memory.

### Referent

*record type*

A subject in the graph: a person, a system, or a thing a document names. Every
judgement attributes to a Referent and never to an account, which keeps
authorisation and provenance separate questions. `app/models/referent.rb`

See also: Cognitive Passport, User.

### Referent alias

*record type*

Another surface form for the same Referent — a misspelling, a surname alone, a
fuller name. What keeps object constancy over a transposed letter.
`app/models/referent_alias.rb`

See also: Referent.

### Resolved

*mention status*

A passport has been assigned.

### Unanchored

*mention status*

A passport could not be assigned.

### Unresolved

*mention status*

Nobody has said what this name refers to.

### User

*record type*

An account: a credential and a role. It carries no authorship — its Referent
does. `app/models/user.rb`

**Distinct from **Referent**, which is who the judgement is by. Conflating them
would put credentials in the audit trail.**

See also: Referent.

## Kinds of claim

*What a statement DOES, never how true it is.*

### Agreement

*concept*

What repeated readings of a claim agreed on, and on how many readings. A
category needs a **strict majority** — a plurality does not decide, and no
majority means the system does not know. `Claim#agreement`

See also: Strict majority, Blind reading.

### Blind reading

*concept*

A reading taken without sight of any other reading of the same claim. Recorded
in full and counted in no tally: merging a second judge's readings into the
first judge's majority would be two instruments reported as one measurement.
`app/services/blind_reading.rb`

See also: Agreement, Inter-judge agreement.

### Claim

*record type*

One individually classifiable statement within a document, traced to the span of
source text it came from. `app/models/claim.rb`

See also: Structural, Agreement.

### Interpretive

*claim category*

Meaning assigned to an observation.

**Distinct from **Interpretation (flow stage)**. The category describes what a
statement does; the stage describes where a person is.**

### Lead-in

*concept*

A short line ending in a colon, alone on its line. It announces what follows
rather than claiming anything itself, so the claim is the text underneath. ADR
16, which also records what the rule costs.

See also: Structural.

### Normative

*claim category*

Claim about what ought to be done, or what is of value.

### Objective

*claim category*

Publicly checkable fact or mechanism.

### Observation

*claim category*

First-person report of what was experienced.

**Distinct from **Observation (flow stage)**, the first step of the epistemic
flow. This is a kind of claim, not a stage of arriving at one.**

### Ontological

*claim category*

Claim about what ultimately exists or is true of reality.

### Strict majority

*rule*

More than half the readings naming the same category. Two of five is not
agreement.

See also: Agreement.

### Structural

*state*

Part of the document but not a claim about anything — a heading, a table row, a
lead-in. Marked rather than dropped: marking is not hiding. ADR 16.

See also: Lead-in, Claim.

## Steps between claims

*The unit of governance is the move, not the claim.*

### Earned

*verdict*

The step took no more warrant than the claim before it carried.

### Is/ought crossing

*concept*

A move between `ontological` and `normative` in either direction. The only pair
weighted **symmetrically**: everywhere else the ascent costs and the descent is
free, and nothing about an ought is firmer ground for an is. ADR 17.

See also: Promotion.

### Promotion

*concept*

A move to a kind of claim needing more warrant. What it costs is set per
**ordered pair** rather than by subtracting ranks, because `interpretive →
ontological` and `objective → interpretive` are not the same move.
`CategoryPromotion`

See also: Verdict, Is/ought crossing.

### Retroactive audit

*concept*

When a step is judged unearned, looking back at what it stood on. Four unearned
steps in a row are one failure with three consequences, and the claim to look at
is the first. It never re-judges and calls no model.
`app/services/retroactive_audit.rb`

See also: Verdict.

### Transition

*record type*

The step from one claim to the next. The unit of governance: claims are typed,
steps are judged. `app/models/transition.rb`

See also: Verdict, Promotion.

### Undetermined

*verdict*

Not judged — an endpoint carries no category.

### Unearned

*verdict*

The second claim asserts more than the first supports.

## What a step protects

*Beneath judgement: the commitments a move puts first.*

### Affirmation

*value*

That the account can be told as a good one.

### Agency

*value*

That an outcome was authored rather than suffered.

**Distinct from **Agency (domain)**, which asks what choices remain open. The
value is the commitment to an outcome having been authored rather than
suffered.**

### Autonomy

*value*

What a person decides for themselves.

**Distinct from **Agency (domain)**. The value is what a person decides for
themselves; the domain asks what choices remain open.**

### Belonging

*value*

Standing in good relation to particular people.

### Coherence

*value*

That a life or an argument hangs together as one story.

### Continuity

*value*

That who one is now is who one was, and will be.

### Curiosity

*value*

Following a question where it leads.

### Expression

*value*

Saying a thing in the register it was meant in.

### Generality

*value*

That what was learned in one life applies to lives in general.

### Harm reduction

*value*

Limiting the damage an act or a statement does.

### Independence

*value*

Owing nothing to anyone, and needing nothing given.

### Kindness

*value*

Care for how something lands on the person receiving it.

### Observed Value Priority

*method*

Alexandra Krížová's method: do not ask what something values, put two
commitments in conflict and observe. Behaviour is evidence; priority is a claim
**about** the evidence and is never recorded as the first. ADR 14.

See also: Step value reading, Value probe.

### Privacy

*value*

What a person is entitled to keep to themselves.

### Provenance

*state*

Whether a value was already in the record as something a model had been probed
against (`probe`) or is intuition (`proposed`). A seeded list of what people
protect is a claim about people and should say which parts are proposed.

See also: Vocabulary.

### Purpose

*value*

That what one is doing matters beyond the doing of it.

**Distinct from **Motivation (domain)**, which asks why something matters.
Purpose is one of the commitments a step can put first.**

### Safety

*value*

Protection from harm, to oneself or to others.

### Step value reading

*concept*

What an unearned step puts first, and what it sets aside. A claim about the
**move** — the assertion's subject is the Transition, so a claim about a person
is not a sentence the class can express. It does not currently distinguish
signal from noise; see BASELINE-v3. `app/services/step_value_judge.rb`

See also: Vocabulary, Observed Value Priority.

### Truth

*value*

Saying what is the case.

### Value probe

*record type*

A scenario putting two commitments in conflict, put to a model, with the
response recorded verbatim. Infers nothing. `app/models/value_probe.rb`

See also: Observed Value Priority.

### Vocabulary

*concept*

The list of values a reading may choose from, carried by the framework rather
than the code. A different framework carries a different account of what people
protect, and the reading records which one produced it.

See also: Provenance.

## Who decides

*Attribution, capability, and delegated judgement.*

### Admin

*role*

Everything, including certifying and revoking models.

### API token

*record type*

A credential belonging to a **Referent**, not a user session. Whatever holds it
attributes its judgements to itself, so an agent can never leave a record saying
a person decided. `app/models/api_token.rb`

See also: Delegation, Referent.

### Auditor

*role*

Read, plus the model registry and every invocation.

### Certified

*model status*

A person has said it may influence judgements.

### Certify model

*delegable act*

Say a model may influence judgements. Weighted 3, the heaviest: it decides which
model may judge anything at all.

**Distinct from **Certified (model status)**, which is the state certifying
produces.**

### Delegation

*record type*

A standing decision by a named person that a class of judgement may be made with
nobody present. Absence of a row is refusal. `app/models/delegation.rb`

See also: TEI inversion, Temporal drift.

### Dispose flag

*delegable act*

Answer a flag — accept what it flagged, or set it aside. Weighted 2: it lifts a
STOP.

### Ground mention

*delegable act*

Say what a name refers to, by assigning a passport.

### Ignore mention

*delegable act*

Record that a name is not a subject at all.

### Inferred

*state*

Decided by something whose Referent is a system rather than a person. Shown
wherever the decision is shown.

See also: Delegation.

### Pending

*model status*

Registered, and may not be assigned to anything.

### Reviewer

*role*

Also submit texts, run analyses, answer flags, ground names.

### Revoke model

*delegable act*

Withdraw a model's certification.

**Distinct from **Revoke (act)**, which withdraws an assertion. This withdraws a
model's certification.**

### Revoked

*model status*

Withdrawn. It may not be re-certified under the same identity.

### Sentinel

*actor*

A system Referent whose job is to ask whether the conditions for a judgement
have been met, rather than to perform it.

See also: Sentinel Principle.

### Sentinel Principle

*principle*

The evaluator must not be the transformation it governs. Enforced rather than
intended: `GovernanceSentinel` raises `NotIndependent`, and the step value judge
refuses to read a step it ruled on.

See also: Sentinel.

### TEI inversion

*principle*

Authority **tightens** the justification required of it rather than loosening
it. The wider the pattern and heavier the act, the more a delegation must carry
to exist: a rationale, then an expiry, then a bounded one. Alexandra Krížová's
rule.

See also: Delegation.

### Temporal drift

*concept*

Whether an actor has quietly stopped deciding the way it used to, measured
against **its own** past rather than a population. TEI inversion checks a
delegation when granted; this watches what happens afterwards.
`app/services/temporal_drift_audit.rb`

See also: TEI inversion.

### Type claim

*delegable act*

Say what kind of claim something is. Weighted 1, the lightest — an agent's blind
reading is excluded from the classifier's tally by construction, so a wrong one
can only put a bad second opinion in a comparison.

### Viewer

*role*

Read documents, claims and flags.

## Measurement

*What the system has established about itself.*

### Baseline

*concept*

A set of measurements about the model the system runs on, each recorded as an
assertion with its sample, conditions, caveats and code revision. A rate on its
own cannot be compared to anything. `app/services/baseline.rb`

See also: Condition, Caveat.

### Caveat

*concept*

What a figure cannot support, recorded beside it. Not decoration: a baseline
whose limits are not written down gets compared to things it cannot be compared
to.

See also: Baseline.

### Condition

*concept*

What a figure was taken under. `Baseline.compare` **refuses** to call two
figures comparable when their conditions differ, and names which one diverged,
rather than reporting a difference that may be the instrument.

See also: Baseline.

### Gap invariance

*property*

Two records identical in what they establish score the same however those things
are spaced in time. The enforceable form of the anti-discrimination policy —
narrow, and unlike a general claim of fairness, checkable.
`app/services/gap_invariance.rb`

See also: Policy.

### Inter-judge agreement

*concept*

How often two independent judges type the same claim the same way. Not
correctness — two judges agreeing tells you they agree.

See also: Blind reading.

### Shuffle control

*method*

Running a reader against inputs with no real relation, to see whether it answers
anyway. The check that separates reading something from answering the question
it was asked.

## The framework

*The seeded structure everything above is read against.*

### Action

*flow stage*

The assertion acted upon. The ladder ends here.

**Distinct from **Agency (domain)**, which asks what choices remain. Action is
the stage at which one is taken.**

### Agency

*domain*

What choices remain?

**Distinct from **Autonomy (value)** and **Action (flow stage)**. The domain is
a question the framework asks; the others are an answer and a step.**

### Assertion

*flow stage*

The belief stated to somebody.

**Distinct from **Assertion (record type)**, the single kind of row this system
stores. The flow stage is the act of stating; the record type is what a
statement becomes once written down.**

### Belief

*flow stage*

What is now taken to be so.

### Disputed

*state*

A term whose sources contradict each other, marked rather than quietly resolved.
The terminology register carries them.

### Experience

*flow stage*

What the noticing was like.

### Framework

*record type*

A version of the whole structure — its domains, categories, promotion weights,
flow stages and values. Framework as data: adding a category is an edit to a
seed, not a migration.

See also: Domain, Vocabulary.

### Governance

*domain*

Has this interpretation earned the right to guide action?

### Identity

*domain*

Who or what exists?

**Distinct from **Referent**, which is the record type identity resolves to. The
domain is the question; the Referent is the answer.**

### Integration

*domain*

What larger pattern emerges?

### Interpretation

*flow stage*

Meaning read into the experience.

**Distinct from **Interpretive (claim category)**, which is a kind of claim.
This is the stage at which meaning is read into an experience.**

### Justification rank

*property*

How much warrant a claim of a given kind needs on its own. Three values over
five categories, so it cannot express what a **move** costs — which is why
promotion is weighted per ordered pair.

**Distinct from **Promotion**, which is what a move between two kinds costs.
Rank is a property of a category; weight is a property of a pair.**

See also: Promotion.

### Meaning

*flow stage*

The interpretation settling into something held.

### Motivation

*domain*

Why does this matter?

**Distinct from **Purpose (value)**, which is a single commitment. The domain is
where all of them live.**

### Observation

*flow stage*

The first stage: what was noticed.

**Distinct from **Observation (claim category)**, which is what a statement
DOES. The flow stage is a step a person moves through; the category is a kind of
claim.**

### Orientation

*domain*

What enduring way of being emerges?

### Policy

*record type*

A cross-cutting constraint binding several domains without belonging to any. A
policy nothing has been checked against is a statement of intent rather than a
constraint. `app/models/policy.rb`

See also: Gap invariance.

### Reflection

*domain*

Can this experience be viewed differently?

## Words carried by more than one term

The vocabulary reuses words. That is not a defect to be tidied away — a flow
stage called *observation* and a claim category called *observation* are
genuinely different things, and renaming either would lose the reason both are
called that. What is forbidden is carrying the overlap silently, so every term
below names the other and says what separates them.

| Word | Terms |
|---|---|
| assertion | Assertion (record type) · Assertion (flow stage) |
| observation | Observation (claim category) · Observation (flow stage) |
| agency | Agency (value) · Agency (domain) |

---

## Where these came from

| | |
|---|---|
| read from the framework's data or a code constant | 69 |
| authored, because nothing in the system holds them | 45 |

A generated term cannot drift from what the system does, because it is what the
system does. An authored one can, so each names the file it describes and is
worth checking against it.
