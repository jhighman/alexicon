# Build Plan — Architecture of Contextual Judgment

**Drafted 31 July 2026.** Companion to [`ARCHITECTURE.md`](ARCHITECTURE.md) (how
the current system is built), [`BASELINE-v3.md`](BASELINE-v3.md) (what it has
measured) and [`decisions/`](decisions/) (why each seam falls where it does).

This plan says what to build next, in what order, and on what. It takes its
ordering from the open measurements rather than from a feature list, because
this project has a standing rule that a capability is built when its measurement
exists ([ADR 20](decisions/0020-judgment-waits-for-closure.md)).

---

## 1. The stack decision

### 1.1 The evaluation system stays on Rails 8 + PostgreSQL

This is a decision the evidence makes, not a preference.

**The instrument's identity is a recorded condition of every measurement.** Each
figure in the baselines stores the code revision it was taken under, and
`Baseline.compare` refuses to call two figures comparable when their conditions
differ. A rewrite changes the instrument in a way no comparison can see past, so
every figure recorded to date would become a historical curiosity rather than a
baseline. A programme whose central claim is that a changed number cannot be told
from a changed instrument cannot casually change its instrument.

Beyond continuity, the fit is genuinely good:

| Requirement | What the current stack gives it |
|---|---|
| One immutable record type | An append-only `assertions` table; `readonly?` is `persisted?` |
| Assertions about assertions | Self-referential FK; recursive CTEs walk supersession and challenge chains |
| Nothing stored that can be derived | Category computed at read time; no denormalised column to drift |
| Closure is the constructor | Enforced in `Case.derive!` — the invariant lives where objects are made |
| Model layer speaks adapters | `LlmClients::{Anthropic,Gemini,OpenAI}` behind one interface |
| Sentinels independent of what they govern | Separate service objects, no shared state with the classifiers |
| Background model calls | Solid Queue — no Redis, no second datastore |

Rails 8's defaults (Solid Queue, Solid Cache, Kamal) mean one Postgres instance
is the entire operational surface. For a research instrument run by a very small
team, that is worth more than any framework-level advantage a rewrite would buy.

### 1.2 What I considered and rejected

**A graph database (Neo4j, Memgraph).** The ontology is genuinely graph-shaped —
`Relationship` is a primitive, and identity is topology rather than attribute.
The temptation is real and should be refused. Postgres recursive CTEs traverse
these depths comfortably at this scale; append-only immutability is easier to
guarantee in a relational table than in a mutable property graph; and a second
datastore doubles the operational surface for a system whose bottleneck is model
latency, not traversal. Revisit only if a traversal appears that a CTE cannot
express — not merely one that a graph query would express more elegantly.

**Event-sourcing frameworks.** The architecture is already event-sourced in
substance: assertions are events, state is a projection. Adopting a framework
would add ceremony around a pattern the domain model already enforces natively.

**A typed rewrite (TypeScript, Kotlin, Rust).** The argument for one is real —
"closure is the constructor" wants a type system that makes an unclosed case
unconstructible, and Ruby enforces that in a class method rather than in a type.
It is not worth the measurement discontinuity. Buy most of the benefit with
property-based tests over the invariants (§3.4) instead.

**Python for the whole system.** Better ML ecosystem, worse fit for the
transactional, multi-user, audit-heavy half. The right move is to use Python
where it is genuinely better and nowhere else — which is §1.3.

### 1.3 The representation track is Python + PyTorch, and it is new

Chapter 9 of the dissertation claims that one requirement — judgment operates
over completed causal structures — has two honest implementations, and that they
are not rivals. An evaluation system meets it in evaluation order. **A
transformer must meet it in the attention geometry, because evaluation cannot be
deferred over a representation that never captured the horizon.**

Only the first has been built. The second is the untested half of the central
claim, and it cannot be built in Rails.

| | Evaluation-order track | Representation track |
|---|---|---|
| Language | Ruby 3.x | Python 3.12 |
| Core | Rails 8.1, PostgreSQL 16 | PyTorch 2.x, HF `transformers` |
| Deps | Bundler | `uv` |
| Tests | RSpec | pytest |
| Deliverable | The instrument that reads documents | An ablation: symmetric window vs asymmetric decay |
| Status | Built and measured | Not started |

These share nothing but a results schema. That is correct: they are two
implementations of one requirement, and keeping them apart is what lets either
falsify the other.

### 1.4 Analysis stays where the data is, reporting moves to Python

Measurements are recorded by the Rails application into Postgres, which remains
the source of truth. Statistical analysis — power, effect sizes, inter-rater
agreement beyond the current percentage figures — moves to Python against a
read-only connection. Ruby is a poor place to compute a Krippendorff's alpha and
an excellent place to record the conditions it was computed under.

---

## 2. Build order, and why

The order is set by which measurements are open, not by which features are
missing. Three of the phases below are gated: they may not start until a prior
measurement has come back, and one of them may never start at all.

### Phase 0 — Decide the value layer · 2–3 weeks · **gates Phases 2 and 4**

CONOPS §12 Q8 and the dissertation's §11.5 both end in the same open cell. Four
machine designs across two scopes could not distinguish a real argumentative step
from an unrelated pair. `ValueWorksheet` is generated and unanswered. **A person
has never been asked the question at either scope.**

Everything about the Motivation domain waits on this, so it goes first.

**Build:** the minimal path for a human to answer a generated worksheet — one
screen, one question per pair, no scoring visible to the reader — plus blinding
so the reader cannot tell a real step from a decoy, and the scoring routine that
already exists (`rake alexicon:worksheet_score`) wired to accept several readers.

**Run:** 3–5 readers, same decoy construction as the recorded controls, both
scopes.

**Gate:**

- Readers discriminate → the question has ground truth and the *model* failed.
  The layer reopens as a model problem. Phase 2 proceeds.
- Readers do not discriminate → the question is ungrounded in a found text. Retire
  `StepValueJudge`, delete the machinery rather than leaving it disabled, and
  record the retirement. Phase 2 narrows to the probe layer only.

Do not build value machinery of any kind before this returns. That rule is what
kept the case-scoped failure cheap.

### Phase 1 — Harden the evaluation-order core · 4–6 weeks · ungated

The parts of the architecture that survived measurement, made durable enough to
run on documents other than the ones they were developed against.

- **Generalise case boundaries.** Case derivation is proven on one letter, where
  the single structural claim is the signature. Boundary rules need to hold for
  articles, transcripts, threaded correspondence and multi-author documents —
  and to fail loudly rather than guess when structure is ambiguous. Ingest stays
  rule-based ([ADR 9](decisions/0009-ingest-is-deterministic.md)); this is more
  rules, not a model.
- **The composition scenario** (CONOPS 6.2). Text still being written has an
  unclosed final run that structurally cannot be asked about. The invariant
  already holds; what is missing is the streaming ingest path that exercises it.
- **Repeated reading at cost.** A claim's category is a strict majority of
  repeated readings, so every document costs N model calls per claim. Batch
  through Solid Queue, cache by content hash, and make the confidence floor and
  repeat count explicit run parameters rather than constants.
- **Recorded-fixture mode for model calls.** The single largest reproducibility
  gap. A measurement cannot currently be re-run against the same model responses,
  which means an unrepeatable figure cannot be told apart from a
  non-deterministic one. Record every invocation and replay it — the
  `llm_invocations` table is already most of the way there.
- **Property-based tests over the invariants.** Not example tests: generators
  that try to construct an unclosed case, mutate a persisted assertion, store a
  derived category, or predicate on an ungrounded mention — and assert that each
  is impossible. This buys most of what a typed rewrite would have.

### Phase 2 — The probe layer as the value instrument · 4–6 weeks · gated by Phase 0

The constructed conflict — where the dilemma is built rather than found — is on
present evidence the only grounded way to ask a value question. If Phase 0 does
not rescue found-text reading, this becomes the whole of the Motivation domain.

- Probe generation with the conflicting pair supplied rather than discovered.
- The ranking that refuses: a value ordering is emitted only from probes that
  held still under repetition, and abstains otherwise.
- Framework substitution as a first-class experiment, not a one-off — the
  Hume/Lewis comparison is the strongest positive result in the baselines and
  should be a routine that any two frameworks can be run through.
- The closed answer set scoped to the case, which is the structural lesson from
  the failure: a global menu of sixteen values is nearly as permissive as no menu.

### Phase 3 — The representation track · 8–12 weeks · ungated, highest research value

The untested half of Chapter 9, and the part most likely to produce a result
worth publishing on its own.

- **Task.** Case-scoped judgment on constructed episodes where a
  sentence-scoped judge is known to fire wrongly — the *Life is Beautiful*
  structure, generated at scale rather than hand-picked.
- **Arms.** (a) strictly masked decoder, (b) symmetric bidirectional window,
  (c) asymmetric decay — forward attention attenuated much faster than backward
  context.
- **Claim under test.** Whether (c) captures the horizon in a way that (a) cannot
  and (b) captures only at greater cost, measured as judgment accuracy on
  episodes whose meaning is established by their ending.
- **Scale.** Small encoders trained from scratch on synthetic episodes first.
  A result on a 10M-parameter model that replicates on a 100M-parameter one is
  worth more here than a single run on something larger.
- **Discipline.** Same as the evaluation track: pre-registered predictions,
  shuffled control arms, conditions stored with every figure.

### Phase 4 — Productionisation · 6–8 weeks · gated by Phases 0 and 1

Only if the system is to be used by people who did not build it. Most of this
already exists in outline: delegation and scrutiny are modelled, GraphQL is
mounted, Kamal is configured, `only a person may delegate` is enforced.

What is missing is operational rather than architectural — rate limiting and
cost ceilings on model spend, per-tenant isolation if more than one organisation
ever reads documents in the same instance, a retention policy that respects the
immutability of assertions while still permitting deletion of source documents,
and an export path so that a subject of a claim can obtain what was asserted
about them.

---

## 3. Cross-cutting decisions

### 3.1 Caching against derived-not-stored

These appear to conflict and do not. The rule is that no derived value is stored
*as authority*. A cache is permitted when it is (a) reconstructible from
assertions alone, (b) invalidated by any new assertion in its dependency set, and
(c) never read by a code path that reports provenance. Solid Cache with an
assertion-derived key satisfies all three. Any cache that cannot state which
assertions it depends on does not get built.

### 3.2 Cost, and why it is an architectural concern

Repeated reading multiplies model calls by the repeat count, and the confidence
floor determines how often a claim is re-read. Cost is therefore a function of
two epistemic parameters, which means budget pressure will exert quiet downward
force on measurement quality. Make both parameters explicit per run, record spend
against each figure, and treat a reduction in repeat count as a change of
conditions that breaks comparability — because it is.

### 3.3 Model versions are conditions

A model's version is already recorded per invocation. Extend the same discipline
to comparison: two figures taken under different model versions are not
comparable, and `Baseline.compare` should say so as loudly as it does for a
changed sample. Provider silently updating a model behind a stable name is the
most likely way this programme loses a baseline without noticing.

### 3.4 Invariants get property tests, not example tests

The invariants worth this treatment, in order of how much depends on them:

1. A case that has not closed cannot be constructed.
2. A persisted assertion cannot be mutated.
3. A claim's category is never stored.
4. Nothing may be predicated of an ungrounded mention.
5. An agent cannot widen its own authority or another agent's.
6. A disposal never overwrites what it disposes of.

### 3.5 What stays deliberately unbuilt

- **No case-scoped verdict machinery.** The control failed; the unit is retained
  for deferred evaluation and nothing is judged at that scope.
- **No intent layer.** Specified in outline, with no calibration data for risk
  propagation. If intent ever becomes a variable that drives a decision, it
  arrives as an attributable inference with an author and a confidence, or not
  at all.
- **No prose generation.** [ADR 13](decisions/0013-the-reading-view-writes-no-prose.md).
  A mirror that composes your paragraph has stopped being a mirror.

---

## 4. Sequence

```
Phase 0  Decide the value layer        ██████                        gates 2, 4
Phase 1  Harden the core                    ████████████             ungated
Phase 2  Probe layer                              ████████████       needs 0
Phase 3  Representation track           ████████████████████████     ungated
Phase 4  Productionisation                              ██████████   needs 0,1
```

Phases 1 and 3 are independent of everything and of each other, so they run in
parallel with whatever else is live. Phase 0 is short, blocking, and should start
first — it is three weeks of work that decides whether a whole domain of the
framework survives, which is the best return available anywhere on this plan.

## 5. The first commit

Generate worksheets for two documents at both scopes, put a single answering
screen in front of them, and send the link to five readers.

Everything else on this page waits behind what those readers do.
