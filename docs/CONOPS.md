# Alexicon — Concept of Operations

**Status:** Draft v0.1
**Date:** 2026-07-24
**Applies to:** `jhighman/alexicon`

> This document is public. It describes the framework and the system only.
> Source material containing personal disclosures lives in `docs/private/`
> and is git-ignored — do not quote it here.

---

## 1. Purpose

Alexicon is a **claim-classification and transition-governance system**. It does not decide whether statements are true. It decides what *kind* of statement each one is, and whether a move from one kind to the next has been earned.

The governing axiom:

> **Trust is the discipline of preventing inference from becoming evidence.**

The recursive question the system exists to answer:

> **"What kind of statement is this, and has it earned the right to become the next kind of statement?"**

### What the scoring layer is, and is not

`EquitableBaseline`, `AverageCeilingMetric`, `GapInvariance` and `Timeline` score
a **record of relationships**, not claims, and nothing in the application invokes
them — no controller, view, job or task. That is correct, and is worth stating so
it is not mistaken for an unfinished feature.

Their job is to be **the thing the anti-discrimination policy is audited
against**. `GapInvariance` states the policy's one enforceable claim as a
property a scorer either has or does not; a property needs a scorer to check;
`EquitableBaseline` is that scorer, and `PolicyAudit` records the result as an
assertion, pass or fail. Without them the policy would be a statement of intent.

So it is a proof of implementability with real stakes, not a product surface.
This system does not score people, has never claimed to, and gains nothing by
being wired to do so. It follows that `Policy` is deliberately **not** scoped to
a framework, unlike categories, promotions, values and domains: the policy is a
constraint on the implementation rather than a claim within a framework's
epistemology, and it binds whatever framework is current.

## 2. Problem Statement

Reasoning — human or machine — slides between claim types without announcing it:

```
Observation → Experience → Meaning → Interpretation → Belief → Worldview
```

Each step increases abstraction and therefore requires more justification. Natural language makes the slide frictionless, so it usually goes unmarked. In high-stakes settings the consequence is that an inference gets treated as evidence, and downstream decisions inherit a confidence the underlying evidence never supported.

Two failure modes matter operationally:

- **Human**: a narrative climbs the ladder in public, and readers absorb the ontological conclusion as though it carried the observational claim's warrant.
- **Machine**: when context is incomplete, a transformer's attention mechanism generates probabilistic completion — converting a statistical guess into synthetic evidence, then reasoning on its own hallucinated priors.

Alexicon addresses both by making the transition visible rather than by adjudicating content.

## 3. Operating Principles

1. **Categories differ in kind, not in rank.** No category outranks another. Merging them is the error to be caught.
2. **The system never returns True/False.** On an unearned promotion it returns *"the confidence of the statement exceeds the evidence class presented."*
3. **Agency is preserved.** The user is free to hold the belief. The promotion is merely made visible.
4. **Prediction is unavoidable; treating a prediction as operational truth is a policy decision**, not a cognitive necessity.
5. **The observer does not perform the task.** It asks whether the conditions for performing the task have been satisfied.
6. **A refusal to promote is not a rejection of mystery.** It is what keeps an open question open instead of prematurely resolved.

## 4. The Categories

| Category | Definition | Source of confidence |
|---|---|---|
| **Objective** | Publicly checkable fact or mechanism | External evidence, measurement |
| **Observation** | First-person report of what was experienced | Subjective experience |
| **Interpretive** | Meaning assigned to an observation | Personal inference, narrative |
| **Ontological** | Claim about what ultimately exists or is true of reality | Philosophical or existential commitment |
| **Normative** | Claim about what ought to be done, or what is of value | Moral or practical commitment |

**Illustrative behavior.** Given "I experienced overwhelming peace" → *Supported* (an observation, presented as one). Given "…therefore everyone should take this drug," "…therefore consciousness survives death," or "…therefore God exists" → *Sentinel*, in each case. Not because the conclusion is wrong, but because the claim changed category without a corresponding increase in justification.

**Normative was added fifth** ([ADR 17](decisions/0017-a-normative-category.md)). The flow ends in *action* and there was nowhere to put a claim about what should be done, so the framework policed *meaning becoming existence* and left *description becoming prescription* alone — Hume's crossing, unwatched, while its analogue was the centrepiece. Note that the first example above, "therefore everyone should take this drug," was always a normative claim being scored as an ontological one.

`ontological ↔ normative` is weighted **symmetrically**, which no other pair is: everywhere else the ascent costs and the descent is free, because coming down is a retreat to firmer ground. Nothing about an *ought* is firmer ground for an *is*, or the reverse.

Whether five is enough is **not established**. Modal, counterfactual, definitional and performative claims have no home either.

## 5. Stakeholders

| Actor | Interest |
|---|---|
| **Author / analyst** | Submits a text and receives a map of its epistemic structure |
| **Reviewer** | Audits where a document's conclusions came from, not whether they are correct |
| **System designer** | Applies the Sentinel pattern at decision boundaries in other systems |
| **Subject of a claim** | Protected from inference about them being recorded as evidence about them |

## 6. Operational Scenarios

### 6.1 Document audit (primary)
An analyst submits a document. The system segments it into claims, classifies each, detects transitions between adjacent claims, and flags promotions that outrun their justification. Output is an annotated document plus a transition ledger. The analyst can accept, reject, or annotate each flag; their disposition is recorded and does not overwrite the original classification.

### 6.2 Interactive composition
A writer drafts in the system. Classification runs incrementally and surfaces the ladder as it is climbed, so the author sees a promotion at the moment it happens rather than in review.

### 6.3 Screening / evaluation guard
Applied to evaluative pipelines. A gap in a record is an **absence of evidence**, not evidence of degradation. The system refuses to let a statistical inference about that gap be recorded as an objective finding — the anti-discrimination case that motivated the framework.

### 6.4 STOP moment
Where entity ambiguity, broken causality, or out-of-distribution input crosses an uncertainty threshold, the system halts and escalates rather than generating a plausible answer. **Dissonance is a signal that conditions were not met, not an error to be smoothed over.** A healthy freeze is a correct outcome, not a failure.

## 7. Functional Requirements

| ID | Requirement |
|---|---|
| F1 | Ingest a text and segment it into individually classifiable claims |
| F2 | Assign each claim exactly one of the framework's categories — five since ADR 17 — with a confidence and a rationale |
| F3 | Record the evidence class actually offered in support of each claim |
| F4 | Detect transitions between adjacent claims and classify each as *earned* or *unearned* |
| F5 | Emit a Sentinel flag on unearned promotion, stating the category jump — never a truth verdict |
| F6 | Halt and escalate rather than guess when input crosses an ambiguity threshold (§6.4) |
| F7 | Preserve provenance: original text, classification, rationale, and human disposition are all separately retained and independently auditable |
| F8 | Make every classification reversible and annotatable by a human without destroying the machine's original judgment |
| F9 | Where a step is judged unearned, propose what that **step** put first and what it set aside — a claim about the move, never about its author, and recorded as interpretive with a confidence |
| F10 | Render a document's epistemic structure as a report whose every section cites the assertions it rests on, and which refuses to render a section that has no source |
| F11 | Expose every act a person can perform through REST and a command line, and the record itself through a read-only query layer, with one authorisation path shared by all of them |
| F12 | Report disagreement rather than resolving it by recency: distinguish two judges disagreeing from one judge changing its own answer, and report the first as a state with no verdict |
| F13 | Attribute every judgement to whoever actually made it, including identity resolutions answered by a person and rulings made under a named set of premises |
| F14 | Hold two incompatible sets of premises over the same text simultaneously, with both sets of verdicts standing and neither superseding the other |
| F15 | Obtain a reading from a judge that cannot see the system's own conclusion, and refuse to disclose that conclusion until the reading is recorded |
| F16 | Observe a subject's value priority under a **constructed** conflict, and report no ordering until the same probe has been shown to yield the same priority across runs |

**On F9.** It does not work well enough to be read as a finding, and the figure
is measured rather than suspected: presented with claim pairs from unrelated
parts of the same document, the judge reads them almost as often as real steps.
Three designs give gaps of 3.08, 0.29 and 0.54 standard errors, and the only one
that discriminates is the one that invents most. Its output is shown as prompts
for a person to look at the step themselves. See
[`BASELINE-v3.md`](BASELINE-v3.md).

**On F12 and F14.** These are ordered: a system that resolves competing
judgements by recency cannot be asked to compare two premises, because it cannot
hold both long enough for a comparison to exist. Preservation is a precondition
for adjudication rather than a refinement of it.

**On F16.** The constructed conflict is what separates this from F9. A probe
builds the dilemma, so its existence is not in doubt before anything rules on it;
a step found in a text either contains one or does not, and there is no
independent way to tell.

## 8. Non-Goals

Stated explicitly, because each is a plausible misreading:

- **Not a truth engine.** It never adjudicates whether a claim is correct.
- **Not a skepticism tool aimed at personal experience.** Observations are accepted as observations.
- **Not primarily an AI alignment technique**, though the pattern applies there.
- **Does not resolve ontological questions.** It only refuses to let them enter disguised as observation or interpretation.
- **Not a content moderation or fact-checking system.** Both require truth verdicts, which are out of scope by construction.

## 9. Architecture Boundary (important)

The framework is described at two levels that must not be conflated in implementation:

| Level | Description | Buildable here? |
|---|---|---|
| **Epistemic layer** | Four categories, the Sentinel, transition governance, STOP moments | **Yes** — this application |
| **Transformer-internal layer** | G3/G7 column-and-station model, interventions at specific attention layers, clamps on latent activations | **No** — requires model-internal access, not an application concern |

This application implements the **epistemic layer**. It treats any language model it calls as an untrusted black box behind an adapter interface: the model proposes a classification, and the system records that proposal as an *inference*, never as *evidence*. Applying the framework's own axiom to its own implementation is deliberate — a classifier that promoted its own guesses to findings would refute the thesis it exists to defend.

The G3/G7 material is retained as **design vocabulary and documentation**, not as a specification of runtime components. Where its concepts have application-level analogues, those analogues are named honestly rather than presented as the layer-level mechanism:

- *Subject Anchor* → entity resolution, so claims attach to stable identities
- *Action Polarity* → negation and valence handling, so defensive or indirect phrasing is not misread as rejection
- *Context Reconstruction* → provenance and boundary conditions carried with each claim

## 10. Constraints and Assumptions

- **Classification is itself inference.** The system's own output is a machine judgment, subject to the same discipline it applies to its inputs. It is recorded as such and is always human-reviewable (F7, F8).
- **Category assignment is contestable.** Reasonable readers will disagree on Interpretive vs. Ontological in particular. The system must make disagreement cheap to express and cheap to audit, not suppress it.
- **Cross-linguistic input distorts polarity.** Constructions that are idiomatic politeness in one language read as negation in another; surface grammar is not trusted as ground truth.
- **A public deployment processes other people's words.** Consent and retention policy are prerequisites to any hosted multi-user operation, not follow-ups.

## 11. Success Criteria

1. Given a text that climbs the ladder, the system identifies the specific sentence where the promotion occurs.
2. Flags read as *"this changed category"* and are never mistaken for *"this is false"* — verified with real readers, not asserted.
3. A human can overturn any classification, and the record shows both judgments afterward.
4. Ambiguous input produces a STOP, not a confident guess. Measured as a rate, and expected to be non-zero.
5. The system flags unearned promotions in its **own** generated output.
6. Where two judges disagree, the system reports that it does not know rather than reporting the later answer.
7. **The outstanding one: a person's reading of the same text.** Every figure the system holds is currently the system agreeing or disagreeing with itself, and a model can be perfectly consistent and consistently wrong. Until a reader who did not produce the answer has typed the same claims blind, none of the other figures can be read as more than consistency.

## 12. Open Questions

> **Partly resolved.** See `docs/decisions/` — ADR 0001 (categories and domains are
> different axes), 0002 (domains ordered, not dependent), 0003 (anti-discrimination
> is a policy), 0004 (the framework is data). Question 4 below is settled by the
> schema: transitions link arbitrary claim pairs, so a branch is representable
> even though adjacency is the default.

1. **Claim segmentation granularity** — sentence, clause, or argumentative move? Determines everything downstream.
2. **Is "earned" binary or scalar?** A scalar is more honest and harder to act on. Narrowed rather than answered: a verdict has no weight to attenuate, since a claim cannot be 30% asserted. What a record carries instead is *standing*, so the graded version would be a **provisional** verdict rather than a weighted one — and `undetermined` is already that state.
3. **Which model backs classification**, and how is its own uncertainty surfaced rather than absorbed?
4. **Does the transition ledger form a graph or a linear chain?** §6.1 assumes adjacency; real arguments branch.
5. **Multi-user or single-user?** Determines whether §10's consent constraint is on the critical path.
6. **What is the durable artifact** — the annotated document, the ledger, or both?
7. **Should `Policy` be framework-scoped?** Every other framework object is. Two traditions differing on a cross-cutting constraint cannot currently be expressed, and it is not settled whether that is a gap or the correct separation of procedure from substance.
8. **Does the value layer survive?** Three designs have failed to distinguish a real step from an unrelated pair. The remaining test puts a person in the machine's place on the same decoy condition: a reader who discriminates says the question has ground truth and the model failed; a reader who cannot says the question is ungrounded in a found text and the layer should be retired.

## 13. References

Framework source material is held privately (see `docs/private/`, git-ignored) pending the authors' publication decision. Theoretical grounding spans Polanyi (tacit knowledge, fiduciary epistemology), Lacan, Freud, Mahler, Winnicott, Bion, Klein, and Festinger; full citations accompany the manuscript.
