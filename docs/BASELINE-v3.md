# Baseline v3

**Gemini 2.5 Pro · July 28, 2026**

*Generated from the recorded measurements — do not edit by hand. Re-render
with `rake "alexicon:baseline[v3]"`.*

What this system has measured about the model it runs on, written down so a
later reading has something to be compared against, and so the comparison is
honest rather than reassuring.

Taken at code `9831dc6`.

Also recorded: `v1` ([BASELINE.md](BASELINE.md)) and `v2` ([BASELINE-v2.md](BASELINE-v2.md)). These are **not revisions of each other** — each was taken under its own conditions, and `Baseline.compare` refuses a pair whose conditions diverged rather than reporting a difference that may be the instrument.

> **How to read a number here.** None of these say the model is right. They
> say whether it is *consistent*, which is a different and smaller claim. A
> model can be perfectly consistent and consistently wrong. Consistency is
> worth measuring because inconsistency makes every other question
> unanswerable.

Each figure is stored in the system as an assertion *about the model* —
attributable, challengeable, and superseded by a better measurement rather
than overwritten. If you re-measure, the earlier reading is still there.


---

## 1. Repeated reading — agreement and coverage — 254 of 293 typed, 35 unstably

*A fifth category is now on offer. Does a harder choice cost anything?*

| | |
|---|---|
| steps | 281 |
| typed | 254 |
| claims | 293 |
| unearned | 55 |
| categories — normative | 20 |
| categories — objective | 87 |
| categories — observation | 58 |
| categories — ontological | 24 |
| categories — interpretive | 65 |
| never read | 31 |
| undetermined | 58 |
| unstably read | 35 |
| readings per claim — 0 | 31 |
| readings per claim — 1 | 21 |
| readings per claim — 2 | 14 |
| readings per claim — 3 | 227 |
| readings requested | 3 |

The first measurement taken under five categories. Every earlier figure in v1 and v2 was taken under four.

The prediction was that a five-way choice would be harder than a four-way one and reproducibility would fall. Unstably-read claims went 26 to 35, which looks like the predicted cost and **is not evidence of it**: v2's own two passes produced never-read counts of 30 and 35, so a swing this size is what this measurement does when nothing changes at all.

This is the same discipline §12 arrived at from the other direction, and the same one Alexandra Krížová's fixed attention bias exposed in the drift audit: a number compared against a fixed expectation, with no account of what it does under no change, is not a finding. **The cost may be real. This does not show it.**

**Sample:** note the same source text as documents 20 and 26, re-ingested and re-classified with five categories available, claims 293, document 27  
**Conditions:** majority strict — more than half, readings 3, batch size 12, categories 5, segmentation current segmenter — 14 structural of 307, colon lead-in rule (ADR 16), category keys objective, observation, interpretive, ontological, normative, context claims 4, declines count toward readings yes  
**Code:** `9831dc6`

**What this cannot tell you.**
- Comparison against v2 confounds the category change with ordinary run-to-run variance. Section 2 put single-configuration reproducibility at 87.9%, so roughly 30 of 254 claims would move between any two runs regardless of the new category.
- The apparent rise in unstably-read claims — 26 under four categories, 35 under five — is NOT established. v2's own two passes produced never-read counts of 30 and 35, and section 12 measured coverage as itself unstable, so a swing of this size is ordinary. A cost may well exist; this does not show it.
- Neither v1 nor v2 records the category count in its conditions, because nobody records a constant. Baseline.compare therefore cannot see that the instrument changed between them and v3 on that axis, and will report only the conditions it can see.

## 2. Category adoption (normative) — 20 of 254 typed claims

*A category added to the framework — is it used at all, and what does it take claims away from?*

| | |
|---|---|
| rate | 7.9% |
| typed | 254 |
| drawn from — objective | 5 |
| drawn from — interpretive | 10 |
| drawn from — other or new | 5 |
| normative claims | 20 |

Whether a category added to the framework is actually used, and what it takes claims away from.

It is used — 20 of 254 typed claims, about one in thirteen — so the category is not decorative.

**The modal source is the surprise.** Prescription was not hiding in *ontological*, which is where it was expected: it was being read as **interpretive**, meaning assigned to an observation. "A man's purpose is one thing" reads to a classifier as someone assigning meaning, not as a claim about what exists. The category the framework was least worried about was the one absorbing the missing one.

**Sample:** typed 254, claims 293, document 27  
**Conditions:** majority strict — more than half, readings 3, batch size 12, categories 5, segmentation current segmenter — 14 structural of 307, colon lead-in rule (ADR 16), category keys objective, observation, interpretive, ontological, normative, context claims 4, declines count toward readings yes  
**Code:** `9831dc6`

**What this cannot tell you.**
- The modal source was INTERPRETIVE, not ontological. Prescription was being read as meaning assigned to an observation rather than as a claim about what exists — the opposite of what was expected when the category was added.
- Sources are inferred by matching claim text against the four-category reading of document 26, which is a different run. Some of the attribution is reproducibility noise rather than the new category drawing a claim away.
- 20 claims is a small denominator, and one document. It establishes that the category is used, not how well it is applied.
- Nothing here says the 20 were typed CORRECTLY. No person has read them.

---

## Comparing a later reading

`Baseline.compare(from: "v3", to: "…")` **refuses** to call two figures
comparable when their conditions differ, and names which condition diverged. A
criterion measured once but not twice is reported as unmeasured rather than
dropped — a measurement that was not repeated is not a measurement that agreed.

The conditions stored with each figure include batch size, context window,
confidence floor, sample, and the code revision. Without those, a changed
number cannot be told apart from a changed instrument.

## What is not measured

- **Correctness.** 2 figures. All of them are the system agreeing or disagreeing with itself.
  Nothing here compares the system's output to a *person's* judgement of the
  same text — which would be the most valuable next measurement, and is not a
  software task.
- **Any model but this one.** The OpenAI adapter has never been called.
