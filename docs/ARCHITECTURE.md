# Architecture

How the system is put together, and why the seams fall where they do.

[`THESIS.md`](THESIS.md) argues the position; [`CONOPS.md`](CONOPS.md) says what
the system is for; this document says how it is built. Decisions with rejected
alternatives live in [`decisions/`](decisions/).

---

## The shape of it

Text arrives, is cut into claims, and every capitalised string in it is
proposed as a name. Nothing is predicated of a name until someone has said what
it refers to. Claims are typed by kind; the steps *between* claims are judged
for whether the promotion from one kind to the next was earned.

```mermaid
flowchart TD
    T["Text"] --> S["ClaimSegmenter<br/><i>rule-based</i>"]
    S --> C["Claims"]
    C --> X["MentionExtractor<br/><i>rule-based</i>"]
    X --> M["Mentions"]
    M --> IS{"IdentitySentinel"}

    IS -->|"resolves"| R["Referent<br/>Name → Subject → Role"]
    IS -->|"cannot"| STOP["STOP<br/><i>waits for a person</i>"]

    STOP -.->|"model may propose"| IP["IdentityProposer"]
    IP -.->|"proposal, not a resolution"| STOP
    STOP -->|"person answers"| R

    C --> CL["ClaimClassifier<br/><i>model, governed</i>"]
    CL --> CAT["Category<br/>objective · observation<br/>interpretive · ontological"]

    CAT --> TR["Transitions<br/><i>the step between two claims</i>"]
    R --> GS
    TR --> GS{"GovernanceSentinel"}
    GS --> V["Verdict<br/>earned / unearned"]

    V --> RV["Reading view"]
    CAT --> RV

    style STOP fill:#f8d7da,stroke:#dc3545
    style V fill:#d1e7dd,stroke:#198754
    style IP fill:#e2e3e5,stroke:#6c757d
```

**Structure is not a claim.** A heading, a table row, a rule — part of the
document, but not an assertion about anything. These are marked rather than
dropped, so the text stays in the record and still renders; what changes is that
nothing asks them what kind of claim they are, and no step is drawn through
them, because a heading is where an argument restarts rather than a move within
one.

Where the text is markdown, this is decided with certainty: a row is a table row
because a delimiter row says the block is a table. Where it is plain prose, a
deliberately timid heuristic applies — an *isolated* short unterminated line,
never a run of them. The timidity is earned: the obvious rule swallowed 49 of
one document's 306 claims, including the framework's own category definitions,
because a table had been flattened into bare newlines before it ever arrived.

Two things to notice. The **rule-based** stages are deliberately not
model-backed — segmentation and extraction decide what counts as a claim and
what counts as a name, and every later judgement inherits those decisions
([ADR 9](decisions/0009-ingest-is-deterministic.md)). And the identity STOP
blocks the path to *governance* but not to *classification*
([ADR 11](decisions/0011-the-lock-guards-predication.md)).

---

## One record type

A sentinel's flag, a reviewer's dismissal, a verdict on a step, a
classification, an identity resolution — all the same object. Immutable,
attributed, evidenced, supersedable, challengeable
([ADR 8](decisions/0008-one-epistemic-record-type.md)).

```mermaid
flowchart LR
    A["Assertion<br/><i>immutable</i>"]
    A -->|"asserter"| R["Referent<br/><i>who made it</i>"]
    A -->|"about"| S["Subject<br/>Claim · Mention · Document<br/>Transition · Assertion"]
    A -->|"points at"| O["Object<br/>ClaimCategory · Referent"]
    A -->|"supersedes"| A2["an earlier Assertion"]
    A -->|"came from"| I["LlmInvocation<br/><i>when a model produced it</i>"]
    A3["Later assertions"] -->|"answer, never edit"| A

    style A fill:#cfe2ff,stroke:#0d6efd
```

An assertion may be *about* another assertion — that is what makes the structure
recursive, and it is how a flag is answered without the flag being altered.

An assertion is an **event**, not a property. It records that a claim *was
made* — never that the claim was correct. An assertion may be perfectly
authentic and entirely mistaken, and the architecture holds both facts at once.

Nothing is edited. `readonly? = persisted?` is enforced at the model, so an
error is never erased; it is *answered* by a later assertion that references it.

### Everything downstream is derived

`claims`, `mentions` and `relationships` carry no `status`, `verdict` or
`category` column at all. Each of these is read from the standing assertions.

| Question | Answered by |
|---|---|
| What category is this claim? | its standing `classify` assertion |
| Is this mention resolved? | whether a standing `resolve` assertion names it |
| Was this step earned? | the newest standing verdict assertion on the transition |
| Is this flag still open? | whether a standing `accept`/`reject` answers it |
| Is the document locked? | whether any STOP flag stands undisposed |

A stored copy could disagree with the record it summarises. Derivation costs
queries and buys the guarantee that it cannot.

The registry is different, and deliberately so: `llm_providers.status`,
`llm_models.certification_status` and `llm_invocations.status` are ordinary
columns. They record configuration and what happened on the wire, not
judgements about a text, so there is nothing for them to drift out of step with.

---

## Identity precedes reasoning — about an entity

A name arriving without established reference is *Entity Noise*. The Cognitive
Passport is `Name → Subject → Role`, and a partial passport is not a weaker
anchor — it is no anchor.

```mermaid
flowchart LR
    N["Name in text"] --> RR{"ReferentResolver"}
    RR -->|"one match"| OK["resolved"]
    RR -->|"several, or a form<br/>with non-entity senses"| A["ambiguous"]
    RR -->|"no match"| O["out_of_distribution"]
    RR -->|"passport incomplete"| U["unanchored"]

    A --> STOP["STOP"]
    O --> STOP
    U --> STOP

    style OK fill:#d1e7dd,stroke:#198754
    style STOP fill:#f8d7da,stroke:#dc3545
```

The resolver is deterministic on purpose: its job is to refuse to guess, and a
probabilistic resolver would reintroduce the guess it exists to prevent.

### What a STOP actually blocks

This is the seam most likely to be misread, so it is drawn explicitly.

```mermaid
flowchart TD
    STOP["Unresolved name"] -->|"blocks"| G["Judging a step<br/><i>reasons about what<br/>the names refer to</i>"]
    STOP -.->|"does NOT block"| CL["Classifying a claim<br/><i>asks what KIND of<br/>statement this is</i>"]
    STOP -.->|"does NOT block"| RES["Resolving the name<br/><i>would deadlock</i>"]

    style G fill:#f8d7da,stroke:#dc3545
    style CL fill:#d1e7dd,stroke:#198754
    style RES fill:#d1e7dd,stroke:#198754
```

*"Polanyi said we can know more than we can tell"* is an objective claim
whichever Polanyi it is. Gating classification on resolution made ordinary prose
unreadable — one essay produced 204 blocking questions and could not be typed at
all ([ADR 11](decisions/0011-the-lock-guards-predication.md)).

### One entity, several names

`Polanyi`, `Polayani` and `Michael Polanyi` are one philosopher. Grounding them
separately would break object constancy over a transposed letter, so a name can
be declared **another spelling** of an existing referent. The alias is recorded;
the document's text is never corrected, because the misspelling is evidence that
it was there.

---

## Action polarity — what a claim does, and whether that can be read

The G3/G7 Matrix reads verbs as forces applied between nodes rather than as
grammatical decoration. The difficulty is Freud's: a surface negation can carry
the very intent it appears to deny. *"Nechceš kávu?"* — *"Don't you want
coffee?"* — is an offer in Slovak and is read as refusal through an
English-shaped frame.

So `ClaimPolarity` reads **surface** polarity only, deterministically, and says
so. Its useful output is not the reading but the constructions where the reading
cannot be trusted — a negative question, a double negative, a negated modal.
`SituationalSentinel` raises a **concern** on those, never a STOP: an unreadable
direction does not make a document ungroundable the way an unresolved name does,
because nothing is yet predicating a direction of anything.

Litotes is a recorded miss. *"It is not uncommon"* reads as denied and means
roughly the opposite, and no structural rule separates `uncommon` from
`understood`, `universe` or `information`. Detecting it needs a lexicon of
negative-prefixed words — world knowledge, which is what this layer exists not
to guess at. The gap is documented and pinned by a spec rather than papered over.

The enforceable claim is narrow, in the manner of gap invariance:

> **Polarity invariance.** Negating a claim does not change what KIND of claim
> it is. *"The wall represented fear"* is interpretive; so is *"The wall did not
> represent fear."*

A classifier whose category moves under negation is reading what a claim says
rather than what it does. `PolarityInvariance` checks it by construction — two
classifications, no opinion — and abstains where a negation cannot be built
structurally, because a paraphrase would put the checker's own rewrite
underneath the result.

---

## The model is fenced

Which model answers is a governed decision, not a constant. An uncertified model
is unreachable — nobody's judgement runs because a constant named it.

```mermaid
flowchart LR
    P["LlmProvider<br/><i>adapter? credential?</i>"] --> MO["LlmModel<br/><i>pending</i>"]
    MO -->|"a named person certifies"| CE["certified"]
    CE -->|"admin writes a rule"| AS["LlmAssignment<br/><i>caller + act → model</i>"]

    AG["Agent<br/><i>claim-classifier</i>"] --> RES{"LlmResolver"}
    AS --> RES
    RES -->|"specificity, then priority"| CALL["Call"]
    RES -->|"no rule matches"| NO["Refuses.<br/><i>No fallback.</i>"]

    CALL --> INV["LlmInvocation<br/><i>model · tokens · cost<br/>latency · outcome</i>"]
    INV --> J["The judgements it produced"]

    style NO fill:#f8d7da,stroke:#dc3545
    style CE fill:#d1e7dd,stroke:#198754
```

There is deliberately **no fallback** to "the cheapest certified model". A
fallback of that shape means a call silently runs on a model nobody chose for
it, and the invocation record would be the only place that fact appears.

Two conditions are kept apart because they fail differently: a provider needs an
**adapter** (can the code call it?) and a **credential** (may it?). A provider
without an adapter may be registered but never certified — vouching for a model
this application cannot reach would claim a capability that does not exist.

### Adapters, not vendors

Callers speak one interface and one error taxonomy, so nothing upstream knows
which vendor was on the other end.

```mermaid
flowchart TD
    CF["CallFailed"] --> RT["Retryable"]
    CF --> RJ["RequestRejected<br/><i>4xx — same answer next time</i>"]
    CF --> TR["ResponseTruncated<br/><i>cut off at the token limit</i>"]
    RT --> RL["RateLimited<br/><i>429</i>"]
    RT --> SE["ServerError<br/><i>5xx</i>"]
    RT --> CN["ConnectionFailed"]

    style RT fill:#fff3cd,stroke:#ffc107
    style RJ fill:#f8d7da,stroke:#dc3545
```

The decision that depends on this — wait and retry, or stop — is the same
whoever was called.

`max_tokens` means the size of the **answer**, for every adapter. Gemini charges
its thinking against the same budget, so its adapter adds a thinking allowance
on top rather than making each caller know which providers think. Three separate
services were sized wrong before that floor existed, each found by a run failing
— which is the argument for putting provider quirks in the adapter rather than
in the caller's memory of them. A retry re-runs the whole document, which is cheap: a claim
with a standing classification is skipped, so it resumes rather than repeating
calls already paid for.

### Where the model is asked, and for what

| Agent | Asks the model | Does not decide |
|---|---|---|
| `claim-classifier` | what kind of claim each statement is | may abstain; below the confidence floor the proposal is discarded |
| `identity-proposer` | what an unfamiliar name refers to | proposes only — a STOP lifts when a **person** accepts |

Both record their output as assertions by their own referent: inference,
attributable, challengeable, never a finding. The proposer is deliberately not
the `identity-sentinel` that would accept its proposal — an actor that proposed
the ground and then accepted it would be the conflation Chapter 6 forbids.

---

## Authorisation and provenance are separate

A **User** carries the credential and the role. Its **Referent** carries the
authorship. Every judgement attributes to the Referent, so credentials never
appear in the audit trail.

```mermaid
flowchart LR
    U["User<br/><i>username · password · role</i>"] --> R["Referent<br/><i>the author of judgements</i>"]
    U --> C{"Capabilities"}
    C --> V["can_view?"]
    C --> RW["can_review?"]
    C --> RG["can_view_llm_registry?"]
    C --> CM["can_certify_models?"]
```

Policies ask capability questions, never role questions, so a new role is a new
composition rather than a new branch in every policy.

| Role | May |
|---|---|
| `viewer` | read documents, claims and flags |
| `reviewer` | + submit texts, run analyses, answer flags, ground names |
| `auditor` | read + the model registry and every invocation |
| `admin` | everything, including certifying and revoking models |

---

## Reading

The review surface shows the working memory of the analysis: identity cards,
claim rows, step rows. That is the wrong artifact to hand a person, so
`DocumentReading` slices the body on claim offsets and returns the text in
order, with the judgements attached to the sentences they concern.

It generates **no prose**. A model retelling the document in its own words would
read as more authoritative than the record while being less accountable than it,
and the retelling would become the artifact people cite — fluency mistaken for
grounding ([ADR 13](decisions/0013-the-reading-view-writes-no-prose.md)).

The obligation is pinned by spec: the segments reassemble into *exactly* the
body, and cover it once.

---

## Layout

```
app/
  models/          the record types; almost all state is derived here
  services/
    claim_segmenter · mention_extractor · casing_evidence   rule-based ingest
    referent_resolver · identity_sentinel                   the input boundary
    identity_proposer                                       model proposes names
    claim_classifier · document_classification              model types claims
    governance_sentinel · domain_sentinel · sentinels/      judges the steps
    llm_clients/ · llm_resolver                             the fenced model layer
    document_reading                                        the reading view
  jobs/            long analyses, with live progress over Turbo Streams
  policies/        Pundit; capability questions only
```

## Running it

See [`README.md`](../README.md) for setup. The postures worth knowing before
first use: **nothing classifies until a model is certified and routed**, and
**nothing routes anywhere by default** — both are refusals by design, not
missing configuration.
