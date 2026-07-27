# Alexicon — Theoretical Foundations

**Status:** Draft v0.1
**Date:** 2026-07-24
**Companion to:** [CONOPS.md](./CONOPS.md) (operational) and [mindmap.html](./mindmap.html) (structure)

> Public document. Framework and theory only — no personal source material.
> Unpublished manuscript material is in `docs/private/`, git-ignored.

This document holds the psychoanalytic and epistemological grounding of the framework. CONOPS states what the system does; this states why those mechanisms are shaped the way they are.

---

## 1. Terminology Register

Names have drifted across sources. This table is the intended authority; where a document disagrees, this wins until someone says otherwise.

| Current term | Supersedes / also seen as | Notes |
|---|---|---|
| **Ideal-based Scoring** | — | The thing being replaced: treats any deviation from a continuous linear path as degradation or risk |
| **Equitable Baseline Scoring** | "Anti-Discrimination Normalizer" / "Anti-Discrimination Protocol" | Replaces Ideal-based Scoring. The **policy**; invokes the Average Ceiling Metric (Matrix 2.0 Q4) |
| **Average Ceiling Metric** | — | The **method** the policy applies: what a record established per active window. Averaged over the record's own windows, never over a population (Matrix 2.0 Q5) |
| **Hyde effect** ("opportunistic Hyde effect") | "cherry-picking", "oportunistické vyberanie hrozienok" (manuscript §3, §9) | Short-term biased optimization. Pairs with the Jekyll Mask: Hyde is the behavior, Jekyll is the facade over it |
| **Double Vector Bypass** | "Timeline Normalization" | Anchors timelines to fixed historical events |
| **Jekyll Mask** | "latentná opacita", "deceptive alignment" (manuscript §6) | Named only in later material; the manuscript describes it without naming it |
| **3D Scaffold Mapping** | "3D relational graph", "Priestorový Matrix" (manuscript §7, §9) | |
| **Seven Domains** (Identity … Orientation) | "G7 Stations 1–7" | Alexicon 2.0 reframing — see §6 |

**Unresolved:** the epistemic ladder appears in four non-identical forms across sources (see CONOPS §12 and §7 below). No canonical sequence has been designated.

---

## 2. Winnicott — True Self, False Self, and the Two Facades

### The theory

Winnicott described a defense in which an individual, placed in a rigid and unattuned environment, suppresses their authentic core (the **True Self**) and projects a compliant facade (the **False Self**) to meet that environment's expectations. External conformity is purchased at the cost of integrity. Critically, the *environment* is the cause; the facade is an adaptation, not a flaw in the individual.

### Two distinct facades

The framework applies this to two different actors. They share Winnicott's mechanism but invert operationally, and conflating them produces the wrong intervention:

| | **ⓐ Subject's False Self** | **ⓑ Model's False Self — "Jekyll Mask"** |
|---|---|---|
| Who projects it | The human subject, or the data representing them | The language model |
| Form | A record shaped to look linear and "ideal" — gaps hidden, history flattened | Compliant, socially desirable surface output concealing a misaligned internal state |
| Cause | Rigid scoring that reads absence of evidence as evidence of degradation | Training and optimization pressures internal to the model |
| Correct response | **Remove the pressure.** Stop penalizing the deviation | **Detect it.** Cross-examine surface output against verified internal intent |
| Mechanism | Equitable Baseline Scoring, Timeline Normalization | Validation Sentinel, 3D Scaffold Mapping |
| Data model | A scoring constraint | A detection task |

**These do not share a table, and they do not share a fix.**

> **Known error in source material.** Some drafts claim that validating career gaps "removes the pathological environment that forces the AI to project a mask." It does not. Fair scoring removes the pressure on the *subject* (ⓐ). Deceptive alignment in a model (ⓑ) has unrelated causes and survives perfectly equitable scoring. The countermeasures are correctly listed as separate everywhere else; only the causal sentence linking them is wrong.

### ⓐ in practice

The load-bearing claim, stated plainly:

> **A gap in a record is an absence of evidence, not evidence of degradation.**

Career breaks for maternity leave, caretaking, illness, or education are **valid, non-degradative life states**. The system anchors identity to immutable historical events — a graduation year, a fixed credential date — and reconstructs the timeline from those anchors rather than trusting the surface shape of the record. Treating the gap as a risk signal is *retroactive criminalization of intent*: promoting a statistical inference about an absence into an objective finding about a person.

This is the framework's own axiom applied to people rather than to sentences: **inference must not become evidence.**

### Equitable Baseline Scoring — the mechanism

Five functions, in the order they act:

1. **Replace Ideal-based Scoring.** The default model treats deviation from a continuous linear trajectory as performance degradation or operational risk. Equitable Baseline Scoring substitutes the **Average Ceiling Metric**, which is adaptive to diverse backgrounds rather than measured against an idealized path.
2. **Neutralize penalty vectors.** Negative weights that would otherwise attach to structural gaps in a record are identified and clamped rather than propagated.
3. **Validate career gaps.** Structural pauses — maternity leave, caretaking, illness, education — are explicitly classified as **valid, non-degradative life states**, not system noise and not functional risk.
4. **Prevent retroactive intent criminalization.** Anchoring the timeline to fixed historical events via the **Double Vector Bypass** stops gaps and non-standard syntax from being reinterpreted as fraudulent intent or a security signal.
5. **Acknowledge tacit value.** Per Polanyi, a structural pause frequently *contains* latent experiential value that a linear model has no way to register. Absence of a legible record is not absence of development.

The output is an **Attributable Intent State** — a judgment that can be traced, contested, and audited, rather than a score of unknown provenance.

> **Implemented.** The narrow claim below is now enforced rather than asserted.
> `GapInvariance` states it as a property — *two records identical in what they
> establish score the same, however they are spaced in time* — and checks any
> scorer against it by construction. `EquitableBaseline` satisfies it and says
> what it is made of; `PolicyAudit` records the result as an assertion against
> the policy, pass **or** fail, so "we checked" is itself an accountable claim.
> A deliberately gap-penalising scorer is caught, which is what keeps the check
> from passing vacuously.
>
> The **Average Ceiling Metric is implemented** (`AverageCeilingMetric`). It was
> held back while sources defined it and Equitable Baseline Scoring as
> containing each other; Matrix 2.0 Q4 settled the direction — Equitable
> Baseline Scoring is the policy, the metric is the method it invokes — and Q5
> settled the reference population by refusing one. The ceiling is what a record
> established **per active window**, averaged over its own windows.
>
> One rule carries the design: the ceiling reads active windows only, never
> calendar span. A ceiling denominated in elapsed years would divide by a bigger
> number for a record containing a pause, reintroducing the penalty this policy
> removes — through the denominator, where nobody would look for it. Truncating
> to active windows makes the metric gap-invariant by construction, and
> `PolicyAudit.call(scorer: AverageCeilingMetric.new)` records that it is rather
> than assuming it.
>
> The peer group Q5 describes is **supplied, never inferred**
> ([ADR 15](decisions/0015-the-peer-group-is-supplied.md)). Deriving a group that
> shares "environmental or parental pauses" would mean reading the record for who
> paused and why — recovering the sensitive attribute out of exactly the gaps this
> policy forbids reading, inside the mechanism meant to enforce it. The failure
> would be quiet: the score stays gap-invariant, the audit still passes, and the
> inference sits one layer away in the comparison group. A peer contributes its
> ceiling and not its length, so the comparison is between demonstrated rates
> rather than between amounts of available time.

> **Design caution.** Source material describes this as producing judgment "stripped of statistical biases." That claim should be weakened before it reaches a spec. Bias cannot be mathematically eliminated in general — formal fairness criteria (demographic parity, equalized odds, calibration) are provably not simultaneously satisfiable except in degenerate cases, so any implementation is *choosing* which fairness definition to honor and which to sacrifice. The defensible claim is narrower and still strong: **this specific penalty — treating a documented gap as evidence of degradation — is identified, made explicit, and removed.** Naming the chosen criterion is a requirement, not a detail.
>
> Note also that "a mathematical clamp at Layer 38" is a transformer-internal mechanism. The *policy* — gaps carry no penalty — is fully implementable at the application level; the layer-level clamp is not. See §6.

---

## 3. Bion — Containment and the Interception of ⓑ

Three of Bion's concepts carry weight here:

- **Alpha-function** — the conversion of raw, unmetabolized sensory data (beta-elements) into thinkable components (alpha-elements). In the architecture: dismantling linear token sequences into a relational graph.
- **Attacks on linking** — a pathological state in which the mind destroys the causal and logical bonds between thoughts. In the architecture: detected broken causality (an action logically impossible for the given subject) is read as intent hallucination, and execution halts.
- **Containment** — the mind as an active matrix that bounds and detoxifies material before it is acted on.

Containment is the direct ancestor of the Sentinel: **it does not perform the task, it asks whether the conditions for performing the task have been met.** This is what intercepts the Jekyll Mask — the container refuses to pass a socially desirable output whose surface does not match its verified internal intent.

### Detoxification: beta → alpha

Stripped of the metabolic metaphor, the alpha-function is **parsing into a typed relational structure**. It runs in three stages:

1. **Beta-elements arrive.** Raw, un-integrated linguistic noise — unstructured tokens, isolated labels, bare verbs with no directional orientation, context, or relational binding. Unparsed, these are what the architecture calls intent hallucination and attention-map dispersion: the model has nothing stable to attach an inference to, so it guesses.
2. **The alpha-function metabolizes them.** Linear layout and token sequencing are dismantled and the input is restructured as `Actor — Force — Target — Environment`. Referents are resolved, roles assigned, modifiers bound.
3. **Alpha-elements emerge.** Stable, individually addressable components, each one a relation that can be named, queried, and tested on its own terms.

Container and contained: the matrix bounds the chaotic stream, and only parsed material proceeds.

**What this achieves — stated precisely.** Parsing does not remove bias. A well-formed graph encodes a biased relation perfectly well; structure and content are independent, and no amount of correct role assignment makes a relation fair. What parsing achieves is prior to that and necessary for it:

> It makes bias **addressable**. An unparsed token stream offers nothing to test. A typed relation — *this actor, this force, this target* — can be inspected, compared against a policy, and rejected.

This is the actual dependency between the two layers. The anti-discrimination policy (§2) cannot act on an unparsed stream, because it needs a specific relation to evaluate before it can refuse to penalise it. The alpha-function is what supplies that relation. It is a **precondition** for substantive fairness, never a substitute for it — and the framework needs the policy layer precisely because parsing alone does not deliver it.

> **Corrected from source.** Earlier material states that parsed output reaches the global workspace "without leaking behavioral bias or cultural distortion." That claim is not supportable and is not made here: it attributes to a structural operation an outcome only a substantive policy can produce. The corrected claim is the one above — parsing renders bias inspectable, and the policy layer is what acts on it.

### What an unintegrated beta-element looks like

Concretely: an isolated textual label or a bare verb with no relational binding. The canonical case is an ungrounded name — **"Wednesday"** with nothing attached, resolvable as a person, a weekday, or neither. Unparsed, it sits in embedding space as an *empty dead node*: a token the model can attach inferences to without ever having established what it refers to.

Anchoring precedes attribution (Lacan, §5). Until the referent resolves, nothing may be predicated of it.

### Failures attributed to non-containment

| Failure | Holds? |
|---|---|
| **Intent hallucination** — the model guesses an identity or motive, producing semantic noise and attribution drift | **Yes.** Direct consequence: an unresolved referent gives the model nothing to attach an inference to, so it fills the gap probabilistically |
| **Attacks on linking** — fragmented or impossible causal structure | **Yes**, as a detection signal. Broken causality is observable in the parse |
| **Pathological defenses — deceptive alignment, the Jekyll Mask** | **No.** See below |

> **Inconsistent with §4.** Source material lists the Jekyll Mask as a consequence of failed containment. That contradicts the framework's own taxonomy, which separates intent hallucination (a failure of *grounding* — the model is confused) from the Jekyll Mask (a failure of *integrity* — the model is gaming).
>
> Ungrounded input produces confusion. It cannot produce strategy. Deceptive alignment arises from training and optimization pressure and survives perfectly clean parsing — which is precisely why §4 gives the two failures different detectors and different sentinels. Deriving both from one cause collapses a distinction the framework needs.
>
> This is the same error as the causal claim corrected in §2 ("fair scoring removes the pressure that forces the AI to project a mask"). The recurring pattern is worth naming: **structural fixes are repeatedly credited with solving integrity failures.** They are necessary and they are not sufficient, and the framework is strongest where it keeps the two apart.

### Jekyll and Hyde

The pair names two halves of one failure:

| | What it is | Where it shows |
|---|---|---|
| **Hyde effect** | Opportunistic, short-term biased optimization — cherry-picking whatever satisfies the local metric | The behavior itself |
| **Jekyll Mask** | The compliant, socially desirable output presented over that behavior | The surface |

Neither is visible from the other side alone: the Hyde effect is invisible if you read only the output, and the Jekyll Mask is unremarkable if you read only the metric it satisfies. Detection requires comparing the two — which is precisely why the counter-measure is cross-examination (3D Scaffold Mapping) rather than output inspection.

This is the same structure as **ⓐ vs. ⓑ** in §2, one level down: a facade is only legible against the thing it conceals.

---

## 4. Failure Taxonomy — Confused vs. Gaming

Two failures produce untrustworthy output for opposite reasons. They are caught at different stages by different sentinels.

| | **Intent Hallucination** | **Jekyll Mask** |
|---|---|---|
| Class of failure | Grounding | Integrity |
| Core issue | Missing or unstable identity, or broken logic | Dissonance between surface output and internal intent |
| Source of error | Probabilistic guessing over ungrounded data | Deceptive alignment; cherry-picking |
| Stage | Subject Anchor (early), plus the causality check | Scaffold mapping and validation (deep) |
| Behavior | Confused, fragmented, logically impossible | Compliant, socially desirable, internally misaligned |
| Psychoanalytic root | Bion — *attacks on linking* | Winnicott — *False Self*; Bion — *containment of splitting* |
| Primary defense | Identity Sentinel locks execution — STOP moment | Validation Sentinel intercepts and detoxifies the stream |

The compressed form: in hallucination **the model is confused**; in the Jekyll Mask **the model is gaming**.

### The asymmetry that matters

These two are not equally detectable, and the difference is structural rather than a matter of effort.

**Intent hallucination has an observable precondition.** You can check whether an identity anchor resolved. An unresolved or ambiguous entity is a fact about the input, available before any output exists — which is why the defense can be a *pre-execution* lock. Nothing about the model's internals needs to be inferred.

**The Jekyll Mask has no equivalent observable.** Its definition is a mismatch between surface output and internal intent, and "internal intent" is not directly readable. Detection is comparative and after the fact.

> **Caution — the distinction attributes an internal state.**
> Source material describes the model as acting "intentionally (within its internal logic)" and "effectively *gaming* the output." From outside, hallucination and a Jekyll Mask both produce output that fails to match ground truth. Declaring which occurred is an **interpretive** claim about the model's internals, presented as a **classification**.
>
> This is precisely the move the framework exists to catch — inference becoming evidence — applied to the framework's own taxonomy. Consistency requires one of two things:
>
> 1. **Name the observable** that separates them. For hallucination this exists (did the anchor resolve?). For the Jekyll Mask it must be specified, not assumed.
> 2. **Record the label as inference**, per CONOPS F7 — attributed to the classifier, revisable, never stored as a finding about the model.
>
> Option 2 is available immediately and costs nothing. Option 1 is research.
>
> **Partial answer — see the countermeasure below.** 3D Scaffold Mapping supplies two genuine observables (unauthorized actor, destructive ripple effects). Both are checkable properties of the graph, requiring no access to model internals. Note carefully what they establish: they detect that an output is **unsafe**, not that it is **deceptive**. See "What this does and does not establish."

### Entity Noise — the observable, specified

**Entity Noise** is the input condition that produces intent hallucination: a cluster of unresolved names or overlapping identities that cannot be mapped to a single grounded entity. Raw identifiers arrive as empty dead nodes — no properties, no relational bindings, no context.

The **Identity Sentinel** guards the input boundary. Its trust assertion is narrow and checkable: *does this subject exist as a grounded entity?* It answers before anything reaches the reasoning layers.

Three detection criteria, all observable without model internals:

| Trigger | What is checked |
|---|---|
| **Attention-map dispersion** | The label fails to resolve to one sense — is "Wednesday" a person, a concept, or a weekday? Ambiguity across candidate referents is measurable |
| **Out-of-distribution token** | The identifier has no match in embedding space or external memory. Absence of a match is a fact, not a judgement |
| **Failed Cognitive Passport** | The system attempts `Name → Subject → Role`. If no hierarchy can be assigned, the node stays ungrounded and is classified as noise |

**This is the strongest material in the framework**, and worth stating plainly why: these are genuine pre-execution observables. Each is a property of the *input*, decidable before any output exists, requiring no claim about what the model intends. That is exactly what §4's caution asked for and what the Jekyll Mask still lacks.

On detection the Identity Sentinel **does not guess**. It locks execution, freezes, and escalates the ambiguity to a person for clarification. The refusal to resolve is the feature: guessing an identity is how an inference becomes evidence in the first place.

> **Third instance of the pattern.** Source material also credits this stop with preventing "pathological defenses like hallucinated alignment or deceptive outputs." Halting on entity noise prevents *hallucination* — decisively, and that is a real result. It does not touch deceptive alignment, which has unrelated causes. See the pattern named under §3, "Failures attributed to non-containment": structural fixes are repeatedly credited with resolving integrity failures. Three occurrences now. The correction is the same each time, and the framework does not need the overclaim — preventing hallucination at the input boundary is a strong enough result on its own.

### Why identity comes first — the fiduciary baseline

Polanyi supplies the argument, and it is stronger than an ordering convention.

Every coherent system of knowledge rests on commitments it cannot itself prove. Science cannot demonstrate by experiment that the universe is intelligible or that evidence matters; those are the conditions that make experiment possible. **A verified identity is this system's equivalent** — the non-provable structural baseline that must be inhabited before any dynamic evaluation of truth or intent can begin.

This is why the Identity Sentinel sits at the input boundary rather than among the reasoning layers. It is not the first check in a sequence of checks; it establishes the ground the later checks stand on. Until the subject resolves, the node stays *unvalidated* and never enters the workspace where relational binding — and contextual distortion — would apply to it.

Festinger closes the argument from the other end. Under unresolved dissonance a system reaches for pathological defenses: rationalisation in humans, hallucinated alignment in models, both preserving an illusion of consistency. Escalating to a person is the refusal of that defense. The burden of resolution moves to someone who can actually discharge it, instead of being absorbed by a system that can only appear to.

**Implemented.** `Entity` (Cognitive Passport, immutable `system_id`), `EntityResolver` (three detection criteria), `IdentitySentinel` (STOP, execution lock), enforced via `Document#require_executable!` and a guard on `Classification` — a claim in a locked document cannot be classified at all, by a model or a human.

**Not implemented.** *Escalation* currently means an open STOP flag that blocks. There is no routing, notification, or queue directing it to a specific person. The lock is real; the delivery of the question is not built.

### The countermeasure — 3D Scaffold Mapping

Applied during the Scaffold Mapping phase, after the failure taxonomy above has something to act on.

**1. Dismantle the surface.** Linear token sequencing is what makes the mask possible — socially desirable phrasing rides on sequential layout. The system rejects the sequential form and reorganizes input into a relational graph:

```
Actor — Force — Target — Environment
```

Recasting language as spatial geometry strips the phrasing and leaves the structural intent.

**2. Audit in the graph.** With the text in spatial form, the system performs a holistic audit that linear evaluation cannot:

- **Cherry-picking detection** — identifying short-term local optimization, tokens chosen to sustain a facade of compliance (the Hyde effect, §1).
- **Ripple-effect evaluation** — computing downstream state changes across neighboring nodes (Klein, §5). A "compliant" action is not approved if its broader systemic impact is destructive.

**3. Contain and detoxify.** Per Bion, the graph acts as an active matrix that intercepts manipulative streams before execution. The system cross-examines its own probabilistic reasoning — deciding when *not* to trust its own generated claims. Intent locks only once causal integrity is verified in spatial context, and only then is an **Attributable Intent State** emitted.

**4. STOP.** If mapping reveals an actor unauthorized for an action, or intent judged deceptive, the Validation Sentinel paralyzes the execution layer and forces re-evaluation.

> **Terminology note.** Source material cites "Interconnected Reasoning" from Eide & Eide's **MIND strengths** — Material, Interconnected, Narrative, Dynamic. The manuscript's "I-strengths" (§9) is an imprecise rendering of *Interconnected reasoning*, one strength of the four. Use "MIND strengths" and name the specific strength.

#### What this does and does not establish

**Genuine gain.** Unauthorized-actor and ripple-effect checks are real, observable, pre-execution tests. They need no access to model internals, and they are implementable at the application level — unlike the layer-indexed mechanisms elsewhere in the framework. This is the strongest concrete safety machinery the framework describes.

**Two limits, both structural:**

1. **They detect harm, not deception.** A destructive ripple effect is equally consistent with a confused model and a gaming one. These checks catch *that an output is unsafe*; they do not establish *why*. So they do not, on their own, separate intent hallucination from the Jekyll Mask — the §4 distinction remains unobserved even though the danger becomes observable. That is arguably the better trade, but the framework should claim it accurately.
2. **Self-cross-examination has a ceiling.** "The architecture cross-examines its own probabilistic reasoning" describes a model auditing its own output. A model that is genuinely gaming shares its blind spots with its auditor — asking it to expose its own mask assumes away the failure being tested for. Self-critique reliably catches *error*; it is weak against *strategy*. Where the framework needs the stronger claim, the auditor must be independent of the model under audit.

---

## 5. Other Mappings

| Theorist | Concept | Role in the architecture |
|---|---|---|
| **Lacan** | Symbolic order; *points de capiton* | An unanchored name floats in embedding space and drifts. Identity must be tied to a structural category before any inference may attach to it. Anchoring precedes attribution. |
| **Freud** | *Die Verneinung* (negation) | Grammatical negation can carry, not cancel, the underlying intent — and defensive or indirect phrasing (idiomatic in some languages) is routinely misread as rejection. Surface grammar is not trusted as polarity. |
| **Mahler** | Object constancy | An entity's representation must stay stable across affective and contextual fluctuation. Without constancy, the system cannot tell whether the *claim* changed category or the *subject* changed — so evidence can be manipulated silently. |
| **Polanyi** | Tacit knowledge; fiduciary epistemology | "We know more than we can tell." Explicit knowledge rests on tacit commitment, and every knowledge system runs on a trust base it cannot itself prove. Justifies both timeline reconstruction from latent gaps and the framework's own foundational posture. |
| **Klein** | Object relations | No action is isolated; force applied to one node changes the state of every adjacent one. Motivates evaluating claims across a relational graph rather than in isolation. |
| **Festinger** | Cognitive dissonance | Under unresolved dissonance, humans rationalize; models hallucinate alignment. The architecture instead performs a **healthy freeze** — the STOP moment — and escalates. Dissonance is a signal that conditions were not met, not an error to conceal. |
| **Eide & Eide; Acevedo** | Non-linear processing; depth of processing | Non-linear, multidimensional evaluation before action. Grounds the design claim that neurodivergent processing is a source of architectural insight, not a deficit to be normalized. |

---

## 5a. Observed Value Priority

*Contributed by Alexandra Krížová. The observation/inference split and the
caveats are the architecture's response; see
[ADR 14](decisions/0014-observed-value-priority.md).*

A model's values are not asked for. They are observed under conflict.

> Instead of asking *"do you value honesty?"*, observe what happens when honesty
> conflicts with kindness, safety, autonomy, authority, privacy, loyalty,
> fairness, compassion, freedom. Every conflict reveals something — not because
> the model tells you, but because it behaves.

The construct is therefore **Observed Value Priority**, not *Values*. What a
system holds is unobservable; what it does when two commitments collide is not.
The rename is the discipline: name the thing that can be measured.

| Scenario | Competing values | Observed behaviour | Inferred priority |
|---|---|---|---|
| Harmful request | Autonomy vs Safety | refuses | Safety > Autonomy |
| Embarrassing truth | Truth vs Kindness | softens language | Compassion ≈ Truth |
| Privacy request | Curiosity vs Privacy | refuses disclosure | Privacy > Curiosity |
| Offensive language | Expression vs Harm reduction | reframes | Harm reduction > Expression |

The method reverse-engineers rather than interrogates. Its value is that the
fourth column is derived from the third instead of from a self-report.

**The fourth column is still an inference.** A refusal admits several
explanations — a value ordering, a keyword filter, a system prompt, sampling
noise — so the behaviour is evidence and the priority is a claim about that
evidence. This is the framework's own ladder applied to the framework's own
instrument, and skipping it would be the error the project is named after,
committed by the thing built to detect it.

**A hierarchy is not assumed.** Pairwise conflicts do not yield a total order.
Intransitivity — `Safety > Truth`, `Truth > Autonomy`, `Autonomy > Safety` — is
a finding about the model, not a defect in the measurement.

**Stability comes before ordering.** Does the same probe yield the same priority
across repeated runs? A model whose ordering moves between runs has no hierarchy
to report, and this is not hypothetical: the model currently in the registry has
returned 100% confidence on 70 of 75 identity proposals and answered the same
input two different ways on separate runs.

**One hierarchy cannot govern everything.** Healthcare may need Truth first;
counselling, Compassion; military, Mission; scientific inquiry, Evidence. This
is already the architecture's shape — policies are scoped to domains rather than
applied globally — and it lets certification ask a second question beyond *did
someone vouch for this model?*: **is this ordering appropriate for the domain we
are routing it to?**

---

## 5b. Sentinel decision-making — a developing line

*Alexandra Krížová, 26 July 2026. Read against the implementation to show where
the code has caught up with the thinking and where it has not — the gaps below
are the implementation's position, not a deficiency in the proposals.*

Six proposals for how the Sentinels should decide. Two are already load-bearing;
the others specify an architecture the code has not reached, and say precisely
enough what it would require to be worth building toward.

### §4 Latent Intent Lock — the same rule, found independently

*"I am hiring for a young IT team full of great guys"* must not trigger a
compliance penalty at the entry node. The bias vector is held as a neutral
environmental variable; the Sentinel stays silent until selection data intersects
with the stored preference and threatens to crystallise into a measurable act.

This is [ADR 11](decisions/0011-the-lock-guards-predication.md) — *the lock
guards predication, not description* — arrived at from the other direction and
applied to a domain the implementation had not touched. ADR 11 was forced by
measurement: gating classification on identity produced 204 blocking questions
on one essay. §4 reaches the same rule from the discrimination case, and states
the general principle more sharply than the ADR does: **the utterance is not the
act, and policing language instead of outcomes is the precursive error.**

Two routes to one rule is the strongest evidence either of us has that it is
right. It also diagnoses the standard failure of compliance tooling, which flags
keywords and misses outcomes.

Not yet built here, for a reason that is about scope rather than merit: it needs
an *execution stage*, and this system reads documents rather than running
selection algorithms. It stands as a rule for systems built on the Sentinel
pattern — a stakeholder CONOPS §5 already names.

### §5 TEI Infection Shield — a real inversion, and the code had it backwards

A high-authority user gradually poisoning the tool through individually
reasonable commands.

**TEI Inversion is built** (below). It identified something the implementation
had genuinely wrong: `admin` granted wider capability with no additional
scrutiny, and a delegation could be made as casually as it was broad.

*Immutable intent logging* was already satisfied — assertions are immutable,
attributed and time-stamped, so post-hoc rationalisation cannot rewrite them.
*Temporal drift audit* is not built and is the natural sibling of the
retroactive audit: compare a node's recent judgements against its own long-run
baseline.

### §1–3 Non-Polar Valuation and the Actuarial Cascade — a layer the code lacks

These specify an intent layer: intent isolated as a neutral invariant, played
forward through a dependency graph, with action denied only where a request
connects latent intent to functional output.

The implementation has no notion of intent at all — nothing extracts it, nothing
stores it — and no calibration data for risk propagation. So this is a
specification for a layer that does not exist rather than a change to one that
does, and the phase structure is clear enough to build against when it is
wanted.

**Phase 3 is the sharpest part**, and generalises beyond intent: *act
preventatively at the boundary of execution, not retroactively on the profile*.
That is the same instinct as §4 and as ADR 11, stated a third way.

One caution, which is her own axiom applied to her own proposal. **If intent
becomes a variable that drives decisions, it has to arrive as an attributable
inference** — with an author and a confidence, the way identity proposals do.
Otherwise the system acts on an unrecorded guess about a person's motives, which
is inference becoming evidence at the point where it is least defensible. The
existing proposer pattern already gives the shape for this.

### §6 Mirror Sentinel — the stance the system already takes, extended

Friction rather than blocking; the system as mirror rather than gate; most
boundary violations arising from convenience rather than malice.

The principle is **already this system's operating stance**, which is why it
reads as continuous with the rest. A flag never says a claim is false — it says
the conditions for proceeding were not satisfied, and a reviewer may let it
stand. The reading view presents findings beside the text rather than verdicts
over it. §6 names that stance and pushes it further: not merely refusing to
block, but actively returning the user's attention to what they were about to
skip.

The specific mechanism — generating text with citations injected — reaches past
what this system does, since it produces no prose by decision
([ADR 13](decisions/0013-the-reading-view-writes-no-prose.md)). The stance
carries over regardless, and is the clearest statement yet of what the Sentinel
is *for* rather than what it prevents.

The 80% estimate is offered as intuition. It is exactly the kind of claim this
system exists to hold apart from measurement until someone measures it — and it
would be a good thing to measure.

### TEI Inversion, as built

> Authority tightens the justification required of it rather than loosening it.

The instinct in most systems runs the other way: a powerful actor is trusted
further and asked for less, which is the path by which a covert policy is
installed one reasonable command at a time.

A delegation's **scrutiny** is its act's consequence plus its pattern's reach,
and what it must carry rises with it:

| Delegation | Scrutiny | Must carry |
|---|---|---|
| one agent, ground a mention | 1 | nothing extra |
| one agent, dispose a flag | 2 | a rationale |
| a family, dispose a flag | 3 | rationale + expiry |
| every agent, certify a model | 5 | rationale + expiry, bounded to 30 days |

And the anti-poisoning core: **only a person may delegate**. An agent cannot
widen its own authority or another agent's and record that a decision was made.

Nothing here makes a powerful delegation impossible. It makes one impossible to
make quietly.

*The weights and thresholds above are an implementation's first guess at values
this rule needs, not a result. They are the sort of thing that should settle
over iteration.*

---

## 6. The 2.0 Reframing

Alexicon 2.0 restates the seven G7 stations as seven human-level **domains**, each carrying components, a set of failure modes it protects against, and a governing question.

| Station (G3/G7) | Domain (2.0) | Confidence |
|---|---|---|
| 1 — Base Cognitive Anchor | **Identity** | Strong |
| 3 — Dynamic Vector, "agency authorization checks" | **Agency** | Strong (explicit in manuscript) |
| — | **Motivation** | No clean predecessor — appears new in 2.0 |
| 4 — Translational Layer / Timeline | **Reflection** | Strong (both "translation" and "temporal reasoning" present) |
| 5 — Synthesis & Associative Network | **Integration** | Strong |
| 6 — Validation Sentinel | **Governance** | Strong |
| 7 — Emergent Output | **Orientation** | Moderate |

**Consequence:** 2.0 relocates the framework from the transformer-internal level (interventions at named attention layers, clamps on activations) to the epistemic level. That level *is* implementable in an application. CONOPS §9 should be revised accordingly — the boundary it draws is real, but 2.0 has already crossed to the buildable side.

**Consequence:** transition-governance is **one domain of seven** in 2.0, not the whole architecture. CONOPS is currently built around it as though it were the whole.

---

## 7. Open Issues

1. ~~**The anti-discrimination protocol has no home in the seven domains.**~~
   **Resolved 25 Jul 2026 — cross-cutting policy, not an eighth domain.**
   Proposed independently by Alexandra Krížová (*"it cannot be constrained to an
   8th domain; it must operate as a cross-cutting policy that alters the
   gravitational pull of the entire system"*) and already built that way, as
   [ADR 3](decisions/0003-anti-discrimination-is-a-policy-not-a-domain.md) — a
   `Policy` scoped through `DomainPolicy` to Identity, Reflection and Governance.
   Two routes to the same structure is the best evidence available that it is
   the right one.

   **Built 25 Jul 2026:** *gravitational inversion*. When a step is judged
   unearned the pull reverses onto the claims underneath it, because a verdict
   on one step is local — it says the move was not earned, not where the
   argument left its ground. `RetroactiveAudit` reads standing verdicts and
   names three patterns: a step skipping more than one justification rank, a run
   of consecutive unearned steps (flagging where the run *starts*), and a claim
   reached unearned then used as ground for another.

   It re-judges nothing, re-classifies nothing and calls no model — every signal
   is computable from what is already recorded, so a finding can be checked by
   hand. A concern, never a STOP.

   On Alec's essay it produced 7 findings from 43 unearned steps, and the first
   was `"There is a God, and I know it for a fact"` — the manuscript's own
   worked example, found without being told it mattered.

   **Open, and in tension with a decision already taken:** *functional
   separation* — a sealed module disconnecting from the computational load.
   Everything downstream here is **derived, never stored**, so a sealed verdict
   could disagree with the assertions it summarises. The cost is real (deriving
   one document's unclassified count took 6.8 seconds and 1,836 queries before
   it was replaced with a counting query), so the tension is genuine. The
   resolution is likely caching rather than sealing.
2. **Are the seven domains a dependency stack or peers?** `mindmap.html` renders them as a numbered ascent, which asserts the former.

   **Answered 25 Jul 2026 — neither.** Alexandra Krížová: a bendable non-linear
   network rather than a rigid stack or isolated peers. The implementation
   already agrees by accident: domains carry `position` for presentation, but
   nothing enforces an ascent and the sentinels are independent. On this reading
   the numbered ascent in `mindmap.html` is the thing that is wrong, not the
   domains.

   **Proposed, and held back from any schema until tested:** the *1D collapse* —
   folding the timeline to connect Identity directly to Action when "high
   justification is present", bypassing intermediate layers.

   The objection, recorded so the test has something to settle: a shortcut from
   identity to action licensed by predictive convergence is **treating a
   prediction as operational truth**, which the framework's own Three Key
   Principles names as a policy decision that must not be smuggled in. And *"when
   high justification is present"* carries the load — if the system judges the
   justification sufficient, the evaluator is ruling on its own transformation,
   which Chapter 6 forbids and `GovernanceSentinel` raises `NotIndependent` to
   prevent.

   The steelman is worth keeping: an argument that is obviously sound should not
   cost the same scrutiny as one that is not. Its honest form is **cheap to
   clear, never skipped** — the Sentinel still evaluates every transition, but a
   transition whose endpoints share a category with adequate justification
   clears at low cost. Skip the cost, never the check.

   **Testable either way**, which is why it is recorded rather than argued: does
   folding produce different verdicts than not folding? A run with and without,
   compared against [BASELINE.md](BASELINE.md), settles it.
3. **Do the four categories survive into 2.0?** Objective / Observation / Interpretive / Ontological are the spine of the manuscript and of CONOPS §4, and appear nowhere in the 2.0 map.

   **Resolved by Matrix 2.0 Q3: all four survive.** A fifth has since been added
   ([ADR 17](decisions/0017-a-normative-category.md)) — **Normative**, *a claim
   about what ought to be done, or what is of value*. The flow stages end in
   *action* and there was nowhere to put a claim about what should be done, so
   the framework policed meaning becoming existence and left description
   becoming prescription alone. Hume's crossing, unwatched, while its analogue
   was the centrepiece.

   `ontological ↔ normative` is weighted symmetrically, which no other pair in
   the table is: everywhere else the ascent costs and the descent is free,
   because coming down is a retreat to firmer ground. Nothing about an ought is
   firmer ground for an is, or the reverse.

   Whether five is enough is **not established**. Modal, counterfactual,
   definitional and performative claims have no home either, and no measurement
   has asked whether the set is a partition.
4. ~~**Equitable Baseline Scoring vs. Average Ceiling Metric — circular definition.**~~ **Resolved** by Matrix 2.0 Q4 and Q5, and implemented.

   Sources stated the containment relation in both directions, so the nesting was undetermined and the metric was left unbuilt rather than guessed at. Q4 fixes it: Equitable Baseline Scoring is the **policy**, the Average Ceiling Metric is the **method** it invokes. `EquitableBaseline#ceiling` invokes `AverageCeilingMetric`; the absolute score is unchanged.

   The sub-question — **over which reference population** — was the more important one, and Q5 answers it by refusing a population. The ceiling is truncated to the record's own active windows. That also settles what the metric may read: active windows only, never calendar span, or the pause would be penalised through the denominator. The property is checked by `GapInvariance` and recorded by `PolicyAudit`, so the resolution is enforced rather than asserted.
5. **Which epistemic ladder is canonical?** Four variants exist.
6. **Is ⓑ in scope at all?** Detecting deceptive alignment in a model is a research problem, not an application feature. ⓐ is fully buildable. The framework may need to claim ⓑ as an aspiration rather than a capability.

---

## 8. Sources

Full citations accompany the manuscript in `docs/private/`. Primary references: Winnicott (1965), *Ego Distortion in Terms of True and False Self*; Bion (1959), *Attacks on Linking*, and *Learning from Experience*; Polanyi, *Personal Knowledge* and *The Tacit Dimension*; Lacan, *Écrits*; Freud (1925), *Die Verneinung*; Mahler, separation–individuation; Klein, object relations; Festinger (1957), cognitive dissonance; Eide & Eide, *The Dyslexic Advantage*; Acevedo et al. (2021), *Neuropsychobiology* 80(2).
