# ATAM: the interpretive → ontological boundary

**Architecture Tradeoff Analysis Method (SEI) · 25 July 2026**
Evaluated against measured behaviour, not against intent. Figures come from
[BASELINE.md](BASELINE.md) and from document 20 (Alec Brindell's essay, 306
claims, 305 steps).

---

## 1. Business drivers

The system exists to answer one question recursively: *what kind of statement is
this, and has it earned the right to become the next kind?* Its single stated
axiom is **trust is the discipline of preventing inference from becoming
evidence**.

Interpretation becoming ontology is the canonical instance of that failure. The
manuscript's worked example is *"the wall represented fear"* → *"there is a God,
and I know it for a fact"*. If the architecture is weakest anywhere, this is the
place it costs most.

## 2. Architectural approaches in scope

| | Approach | Where |
|---|---|---|
| **A1** | Four categories as seeded data with a `justification_rank` | ADR 4, framework-as-data |
| **A2** | Model proposes a category; recorded as inference with confidence; may abstain | `ClaimClassifier` |
| **A3** | Batched classification with a 4-claim context window | `ClaimClassifier::BATCH_SIZE` |
| **A4** | Governance judges the *transition*, by an actor independent of the classifier | `GovernanceSentinel` |
| **A5** | Category derived from standing assertions, never stored | `Claim#category` |
| **A6** | Retroactive audit flags rank skips, runs, load-bearing claims | `RetroactiveAudit` |
| **A7** | Confidence floor of 0.75 discards weak proposals | `ClaimClassifier::DEFAULT_CONFIDENCE_FLOOR` |

## 3. Utility tree

Ranked `(importance, difficulty)`, H/M/L.

```
Epistemic integrity
├── Reproducibility
│   ├── (H,H) Same claim, same conditions, twice → same category
│   │         MEASURED: 88% overall; interpretive is 16 of 28 disagreements
│   └── (H,M) Same claim negated → same KIND
│             MEASURED: 86% (12 of 14 checkable)
├── Detection of unearned promotion
│   ├── (H,L) observation → ontological is caught          MEASURED: 3 found
│   └── (H,H) interpretive → ontological is caught         MEASURED: see R1
├── Refusal integrity
│   ├── (H,M) The system abstains rather than guessing
│   │         MEASURED: 64 of 306 abstained
│   └── (H,H) Confidence discriminates                     MEASURED: see R2
└── Legibility
    └── (M,L) A finding can be checked by hand
              MEASURED: audit calls no model; every signal recomputable
```

## 4. Analysis

### Sensitivity point S1 — the rank scale

`justification_rank` assigns **three values to five categories**: objective 1,
observation 1, interpretive 2, ontological 3, normative 3.

> This analysis was written when there were four. Adding `normative`
> ([ADR 17](decisions/0017-a-normative-category.md)) did not relieve the
> sensitivity point below — it sharpened it. `ontological` and `normative` now
> **share a rank and are still not lateral**, where `objective` and `observation`
> share a rank and are. The rank scale cannot express that difference at all,
> and only the ordered-pair weighting can, which is the remedy this document
> recommended.

Every downstream judgement about *how far* a claim was promoted reads this
scale. It is the single number that decides whether a promotion looks large.

### Risk R1 — the audit is blind to the transition it most needs to see

`RetroactiveAudit` fires `rank_skip` when a step exceeds `MAX_RANK_STEP = 1`.

| Transition | Rank delta | `rank_skip` fires |
|---|---|---|
| observation → ontological | 2 | **yes** |
| **interpretive → ontological** | **1** | **no** |

The audit catches the crude version of the framework's central failure and is
structurally incapable of catching the subtle one *by that signal*. Document 20
contains **6 interpretive → ontological steps, and all 6 were judged unearned**
— governance caught every one. Of those six:

| | |
|---|---|
| flagged by `rank_skip` | **0 of 6** |
| flagged incidentally by `run` | 4 of 6 |
| producing no audit finding at all | **2 of 6** |

The four that surfaced did so because they happened to sit inside a run of
consecutive unearned steps, not because anything recognised the promotion. Two
were invisible to the audit entirely. A signal that catches two-thirds of its
target by coincidence is not covering it.

This is not a tuning problem. Lowering `MAX_RANK_STEP` to 0 would fire on every
single-rank promotion in the document, which is most of them, and a signal that
fires everywhere is not a signal.

**The cause is S1.** The scale compresses exactly where discrimination is
needed. `objective → interpretive` and `interpretive → ontological` are both
"+1" and are not remotely the same move: the first assigns meaning to a fact,
the second converts meaning into a claim about what exists.

### Risk R2 — the confidence floor is inert

| Category | n | mean confidence | below floor 0.75 | at exactly 1.0 |
|---|---|---|---|---|
| objective | 86 | 0.977 | **0** | 68 |
| observation | 52 | 0.988 | **0** | 47 |
| interpretive | 79 | 0.946 | **0** | 44 |
| ontological | 25 | 0.944 | **0** | 12 |

**Not one classification in 242 fell below the floor.** A7 is machinery pointed
at a signal this model does not emit. The floor cannot be the guard on the
interpretive/ontological boundary, because it has never rejected anything.

The refusal that *does* work is the model's own abstention — 64 of 306 — which
is A2's `uncertain`, not A7's threshold.

### Risk R3 — reproducibility is worst where the stakes are highest

Of 28 disagreements on re-classification, **16 originate from interpretive**,
and the largest single group is **8 × interpretive → ontological**. The
architecture's least stable judgement is the one its axiom is about.

Whether this is a model limitation or a definition problem is **not determined
by any measurement taken**. The categories are seeded data (A1) with one-line
definitions; nobody has independently typed a sample to establish ground truth.

### Tradeoff point T1 — context window versus independence

A3 (batching with context) raised agreement from 65% to 88%. It buys
reproducibility.

It costs a form of independence: a claim's category is now partly a function of
its neighbours. Two claims classified together can influence each other, and a
document read in a different order could type differently. The framework's own
principle — a claim is judged by what it *does*, not by its company — is
partially traded away for stability.

Nothing measured tells us how much. **The check does not exist**: classify the
same claims in a shuffled batch order and compare.

### Tradeoff point T2 — derivation versus auditability

A5 (derived, never stored) guarantees a category cannot disagree with the
assertions beneath it. It costs real time — one derived count took 6.8 seconds
and 1,836 queries before replacement — and Alexandra Krížová's *functional
separation* proposes sealing settled modules, which trades the guarantee for
the speed.

### Non-risk N1 — governance independence holds

A4 is enforced, not aspirational: `GovernanceSentinel` raises `NotIndependent`
rather than rule on a classification it authored, and `RetroactiveAudit` is a
third referent again. All 6 interpretive → ontological steps were caught by
governance despite the audit's blindness — the layers are genuinely redundant,
which is why R1 is a gap rather than a hole.

### Non-risk N2 — the categories are data

A1 means recalibrating ranks is a seed change, not a migration. Every remedy
below for S1 is cheap to try and cheap to reverse.

## 5. Risk themes

**Theme 1 — the framework's central distinction is its least instrumented.**
R1, R2 and R3 all converge on interpretive → ontological. The rank scale cannot
see it, the confidence floor never fires on it, and it is where the classifier
most disagrees with itself. Three independent mechanisms, none of them watching
the thing the system is named for.

**Theme 2 — measurement without ground truth.** Every figure records the system
reproducing *itself*. Nothing compares it to a human judgement of the same text.
Until a sample is independently typed, R3 cannot be attributed to the model or
to the definitions, and no remedy can be evaluated.

## 6. Recommendations

**Status 25 Jul 2026 — 1, 3, 4 and 5 done. 2 outstanding, and it is the one that matters.**


| | Action | Addresses | Cost |
|---|---|---|---|
| **1 ✅** | **Done.** `CategoryPromotion` weights every ordered pair as seeded data. `interpretive → ontological` = 2, `objective → interpretive` = 1, lateral and downward moves = 0. `RetroactiveAudit` reads the weight instead of the rank delta. **R1 closed: 6 of 6 caught, up from 0 of 6, with findings rising only 7 → 13.** | S1, R1 | seed change |
| **2** | **Independently type 40 claims**, stratified by category, and compare. | Theme 2, R3 | ~1 hour, human |
| **3 ✅** | **Done, and neither option taken.** The floor is a *policy*, not a tuning parameter — setting it from this model's distribution would make it a description of one provider, and the registry can route elsewhere tomorrow. Removing it would leave nothing when a model that does emit varied confidence arrives. What was wrong was the silence: `ClaimClassifier.floor_effectiveness` now reports what the floor has actually rejected, so `0 of 242 — inert; lowest confidence seen was 0.8` is visible rather than assumed. | R2 | small |
| **4 ✅** | **Done. T1 quantified: 87.9% in document order, 76.0% shuffled.** Batching helps because the context is *relevant*, not merely present — so a claim's category does depend on what precedes it, and the cost to judging a claim by what it does alone is about 12 points. | T1 | ~26 calls |
| **5 ✅** | **Done, and R3 confirmed with a clean split.** interpretive + ontological reproduce at **84.5%**; objective + observation at **93.8%**. The framework's central distinction is 9 points less reproducible than its periphery. | R3 | ~26 calls |

Recommendation 2 is now the only one left, and the others have made it more
urgent rather than less: 4 and 5 both sharpen the question without touching it.
The 9-point gap in 5 is either a model that cannot hold the distinction or a
distinction that is not sharp enough to hold, and no further measurement of the
system against itself can tell those apart.

Recommendation 2 is the precondition for the rest. Without ground truth, every
other number measures consistency and none measures correctness — and the
question actually at issue, *are these two categories distinguishable*, is not a
question about software.
