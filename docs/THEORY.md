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
| **Equitable Baseline Scoring** | "Anti-Discrimination Normalizer" / "Anti-Discrimination Protocol" | Replaces Ideal-based Scoring. **Relation to the Average Ceiling Metric is circular in sources — see §7.4** |
| **Average Ceiling Metric** | — | The scoring measure. **See §7.4** |
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

The alpha-function runs in three stages:

1. **Beta-elements arrive.** Raw, un-integrated linguistic noise — unstructured tokens, isolated labels, bare verbs with no directional orientation, context, or relational binding. Left unmetabolized these produce what Bion calls anxiety, and what the architecture calls intent hallucination, attention-map dispersion, and behavioral bias.
2. **The alpha-function metabolizes them.** Linear layout and token sequencing are dismantled and the input is restructured as `Actor — Force — Target — Environment`. Translating syntax into geometry removes surface friction and stops the system leaning on sequential detail that may carry latent bias.
3. **Alpha-elements emerge.** Stable, bindable components of thought, ready for downstream relational work and passable to the global workspace without leaking behavioral bias or cultural distortion.

Container and contained: the matrix bounds the chaotic stream, and only metabolized material proceeds.

> **Reading note.** "Detoxification" is doing metaphorical work that should be unpacked before implementation. Concretely, what stages 1–3 describe is *parsing into a typed relational structure* — resolving referents, assigning roles, binding modifiers. That is a real and valuable operation. What it does **not** do is remove bias: a well-formed graph can encode a biased relation perfectly. Structure and content are independent. The framework's own anti-discrimination policy exists precisely because *structural* correctness does not deliver *substantive* fairness — so "passed without leaking behavioral bias" overclaims what a parse can achieve.

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

1. **The anti-discrimination protocol has no home in the seven domains.** It touches Identity, Reflection, and Governance and sits in none. Either 2.0 needs an eighth domain, or this is a cross-cutting policy constraining all seven. It is the framework's most concrete and most ethically load-bearing component, so leaving it unplaced is not viable.
2. **Are the seven domains a dependency stack or peers?** `mindmap.html` renders them as a numbered ascent, which asserts the former. Unconfirmed.
3. **Do the four categories survive into 2.0?** Objective / Observation / Interpretive / Ontological are the spine of the manuscript and of CONOPS §4, and appear nowhere in the 2.0 map.
4. **Equitable Baseline Scoring vs. Average Ceiling Metric — circular definition.** Sources state the containment relation in both directions:
   - *"Equitable Baseline Scoring replaces this with the Average Ceiling Metric"* → the protocol applies the metric.
   - *"The Average Ceiling Metric replaces this rigid framework with an Equitable Baseline Scoring system"* → the metric produces the system.

   Both cannot hold. One is the scoring **measure**, the other the **policy** that applies it; which is which is undetermined. Pick one direction before either name enters a schema — they will become a class and a method, and the wrong nesting is expensive to unwind.

   Sub-question, independent of the above and arguably more important: **how is the "average ceiling" computed, and over which reference population?** A ceiling averaged over an already-advantaged population reproduces the bias it exists to remove.
5. **Which epistemic ladder is canonical?** Four variants exist.
6. **Is ⓑ in scope at all?** Detecting deceptive alignment in a model is a research problem, not an application feature. ⓐ is fully buildable. The framework may need to claim ⓑ as an aspiration rather than a capability.

---

## 8. Sources

Full citations accompany the manuscript in `docs/private/`. Primary references: Winnicott (1965), *Ego Distortion in Terms of True and False Self*; Bion (1959), *Attacks on Linking*, and *Learning from Experience*; Polanyi, *Personal Knowledge* and *The Tacit Dimension*; Lacan, *Écrits*; Freud (1925), *Die Verneinung*; Mahler, separation–individuation; Klein, object relations; Festinger (1957), cognitive dissonance; Eide & Eide, *The Dyslexic Advantage*; Acevedo et al. (2021), *Neuropsychobiology* 80(2).
