# Baseline v3

**Gemini 2.5 Pro · July 29, 2026**

*Generated from the recorded measurements — do not edit by hand. Re-render with
`rake "alexicon:baseline[v3]"`.*

What this system has measured about the model it runs on, written down so a
later reading has something to be compared against, and so the comparison is
honest rather than reassuring.

> **Taken across 3 code revisions** — `9831dc6`, `91dee52`, `376b990`. Figures
> within this baseline were not all measured against the same instrument, so a
> difference between two of them may be a difference in the code. Each section
> states its own revision.

Also recorded: `v1` ([BASELINE.md](BASELINE.md)) and `v2`
([BASELINE-v2.md](BASELINE-v2.md)). These are **not revisions of each other** —
each was taken under its own conditions, and `Baseline.compare` refuses a pair
whose conditions diverged rather than reporting a difference that may be the
instrument.

> **How to read a number here.** None of these say the model is right. They say
> whether it is *consistent*, which is a different and smaller claim. A model
> can be perfectly consistent and consistently wrong. Consistency is worth
> measuring because inconsistency makes every other question unanswerable.

Each figure is stored in the system as an assertion *about the model* —
attributable, challengeable, and superseded by a better measurement rather than
overwritten. If you re-measure, the earlier reading is still there.

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

The first measurement taken under five categories. Every earlier figure in v1
and v2 was taken under four.

The prediction was that a five-way choice would be harder than a four-way one
and reproducibility would fall. Unstably-read claims went 26 to 35, which looks
like the predicted cost and **is not evidence of it**: v2's own two passes
produced never-read counts of 30 and 35, so a swing this size is what this
measurement does when nothing changes at all.

This is the same discipline §12 arrived at from the other direction, and the
same one Alexandra Krížová's fixed attention bias exposed in the drift audit: a
number compared against a fixed expectation, with no account of what it does
under no change, is not a finding. **The cost may be real. This does not show
it.**

**Sample:** note the same source text as documents 20 and 26, re-ingested and
re-classified with five categories available, claims 293, document 27  
**Conditions:** majority strict — more than half, readings 3, batch size 12,
categories 5, segmentation current segmenter — 14 structural of 307, colon
lead-in rule (ADR 16), category keys objective, observation, interpretive,
ontological, normative, context claims 4, declines count toward readings yes  
**Code:** `9831dc6`

**What this cannot tell you.**
- Comparison against v2 confounds the category change with ordinary run-to-run
  variance. Section 2 put single-configuration reproducibility at 87.9%, so
  roughly 30 of 254 claims would move between any two runs regardless of the new
  category.
- The apparent rise in unstably-read claims — 26 under four categories, 35 under
  five — is NOT established. v2's own two passes produced never-read counts of
  30 and 35, and section 12 measured coverage as itself unstable, so a swing of
  this size is ordinary. A cost may well exist; this does not show it.
- Neither v1 nor v2 records the category count in its conditions, because nobody
  records a constant. Baseline.compare therefore cannot see that the instrument
  changed between them and v3 on that axis, and will report only the conditions
  it can see.

## 2. Category adoption (normative) — 20 of 254 typed claims

*A category added to the framework — is it used at all, and what does it take
claims away from?*

| | |
|---|---|
| rate | 7.9% |
| typed | 254 |
| drawn from — objective | 5 |
| drawn from — interpretive | 10 |
| drawn from — other or new | 5 |
| normative claims | 20 |

Whether a category added to the framework is actually used, and what it takes
claims away from.

It is used — 20 of 254 typed claims, about one in thirteen — so the category is
not decorative.

**The modal source is the surprise.** Prescription was not hiding in
*ontological*, which is where it was expected: it was being read as
**interpretive**, meaning assigned to an observation. "A man's purpose is one
thing" reads to a classifier as someone assigning meaning, not as a claim about
what exists. The category the framework was least worried about was the one
absorbing the missing one.

**Sample:** typed 254, claims 293, document 27  
**Conditions:** majority strict — more than half, readings 3, batch size 12,
categories 5, segmentation current segmenter — 14 structural of 307, colon
lead-in rule (ADR 16), category keys objective, observation, interpretive,
ontological, normative, context claims 4, declines count toward readings yes  
**Code:** `9831dc6`

**What this cannot tell you.**
- The modal source was INTERPRETIVE, not ontological. Prescription was being
  read as meaning assigned to an observation rather than as a claim about what
  exists — the opposite of what was expected when the category was added.
- Sources are inferred by matching claim text against the four-category reading
  of document 26, which is a different run. Some of the attribution is
  reproducibility noise rather than the new category drawing a claim away.
- 20 claims is a small denominator, and one document. It establishes that the
  category is used, not how well it is applied.
- Nothing here says the 20 were typed CORRECTLY. No person has read them.

## 3. Inter-judge agreement (argumentative prose) — 61.3%, down from 75.8% under four categories

*Both judges now have somewhere to put prescription. Did giving them one reduce
their disagreement where prescription lives?*

| | |
|---|---|
| drop | 14.5% |
| rate | 61.3% |
| moves — objective->normative | 1 |
| moves — normative->observation | 1 |
| moves — ontological->normative | 2 |
| moves — objective->interpretive | 4 |
| moves — observation->interpretive | 3 |
| moves — ontological->interpretive | 1 |
| agreed | 19 |
| neither | 1 |
| compared | 31 |
| only judge b | 2 |
| disagreements | 12 |
| only classifier | 2 |
| standard errors | 1.26 |
| typed by judge b | 36 |
| four category rate | 75.8% |
| sure disagreements | 4 |
| judge b normative from — ontological | 3 |
| judge b normative from — interpretive | 2 |
| judge b typed normative | 5 |
| classifier normative from — objective | 5 |
| classifier normative from — interpretive | 10 |

Tests the case for adding the category: did giving both judges somewhere to put
prescription reduce their disagreement where prescription lives?

**No — agreement fell, 75.8% to 61.3%.** That is the direction against the case
for adding the category, and it is 1.26 standard errors at these sample sizes,
with a 95% interval on the difference running from −0.08 to +0.37. **It spans
zero.** The direction is a warning; the magnitude is not a finding.

The specific result underneath it is sharper than the rate. Only 4 of the 12
disagreements involve *normative* at all — the rest are the boundaries that were
already unstable. And the two judges disagree about **where prescription was
hiding**: the second judge took 3 of its 5 from *ontological*, the classifier
took 10 of its 20 from *interpretive*. Both cannot be right about the same text,
and a category can be used confidently by two readers who are using it for
different things.

**Sample:** note the same 37 claims section 11 used, matched by text; one is now
structural under ADR 16 and dropped out, claims 36, document 27  
**Conditions:** judge a claim-classifier (gemini-2.5-pro), up to 3 readings,
batches of 12 with 4 of context, judge b claude-opus-5, single reading, via the
blind reading API, rate over claims both judges typed, categories 5, category
keys objective, observation, interpretive, ontological, normative, judge b
referent opus-reader-v3  
**Code:** `91dee52`

**What this cannot tell you.**
- IT DID NOT, and the drop is NOT established either. 75.8% to 61.3% is 1.26
  standard errors at these sample sizes, and the 95% interval on the difference
  runs from -0.08 to +0.37 — it spans zero. The direction is against the case
  for the category; the magnitude is not evidence.
- The two figures were taken against DIFFERENT classifier runs — section 11
  against document 20, this against document 27. Single-configuration
  reproducibility is 87.9%, so roughly 12% of claims move between any two runs
  regardless of how many categories exist.
- JUDGE B IS NOT AN INDEPENDENT READING. It had typed these same claims three
  days earlier and remembered its answers, changing only 5 of 36. That anchoring
  holds judge B's side still while the classifier's side moved freely, so the
  disagreement is disproportionately the classifier's movement rather than a
  fresh disagreement between two readers.
- Only 4 of the 12 disagreements involve normative at all. The other 8 are the
  boundaries that were already unstable — objective against interpretive,
  observation against interpretive.
- The two judges disagree about WHERE prescription was hiding. Judge B moved 3
  claims from ontological and 2 from interpretive; the classifier drew its 20
  normative claims mostly from interpretive (10) and objective (5), with at most
  3 from ontological. Both cannot be right about the same text, and nothing here
  says either is.

## 4. Value inference discrimination (shuffle control) — 92.9% on real steps, 60.7% on unrelated ones

*Asking what a move protects presupposes there is something to find. Is the
layer reading the step, or answering the question it was asked?*

| | |
|---|---|
| rate | 92.9% |
| difference | 32.1% |
| real pairs | 28 |
| real recorded | 26 |
| shuffled rate | 60.7% |
| shuffled pairs | 28 |
| confidence real | 0.9-1.0, median 0.9 |
| standard errors | 3.08 |
| shuffled recorded | 17 |
| confidence shuffled | 0.9-1.0, median 0.9 |

Whether the value layer is reading the step or answering the question it was
asked. Asking a model what a move protects presupposes there is something to
find, which is a question shape that produces an answer either way.

**It reads the step — and invents three times in five.** 92.9% on real unearned
steps against 60.7% on pairs from unrelated parts of the same document, a gap of
0.321 at 3.08 standard errors with an interval excluding zero. So it is not pure
confabulation, which was the thing worth ruling out.

**But the confidence is worthless, and that defeats the design.** Both arms
report 0.9 to 1.0, median 0.9. A reading at 0.9 on a real step and one at 0.9 on
a random pair are indistinguishable. The confidence was supposed to be what made
this layer visibly weaker than everything around it; it carries no information
about whether there was anything to read. Raising the floor would cut both arms
equally.

This was run because the layer's own author flagged a 25-of-28 hit rate as too
high for something designed to abstain readily. It was.

**Sample:** document 30, shuffled same category pair as each real step, source
and target drawn at least 20 positions apart, so no argumentative relation
exists, unearned steps 28  
**Conditions:** note both arms run through the same prompt and parser on the
same day; nothing was written to the record, judge step-value-judge via
gemini-2.5-pro, persisted no, categories 5, confidence floor 85.0%  
**Code:** `376b990`

**What this cannot tell you.**
- It DOES discriminate: 92.9% against 60.7%, a difference of 0.321 at 3.08
  standard errors, with a 95% interval of +0.117 to +0.526 that excludes zero.
  The layer is not pure confabulation.
- But the false-positive rate is 61%. On claim pairs with no inferential
  relation at all, it invents a commitment three times in five. Any single
  reading is far weaker evidence than it looks.
- AND THE CONFIDENCE IS USELESS. Both arms report 0.9 to 1.0, median 0.9. A
  reading at 0.9 on a real step and one at 0.9 on a random pair are
  indistinguishable. The design intended the confidence to be the signal that
  made this layer visibly weaker than the rest; it carries no information about
  whether there was anything to read, so it cannot do that job.
- Raising the confidence floor would not help. It would cut both arms equally,
  because both sit in the same narrow band.
- One document, 28 pairs each arm, one model. The shuffled arm preserves the
  category pair but nothing else, so it does not control for two claims
  happening to be relatable by coincidence — some of the 61% may be real
  readings of accidental relations rather than invention.

---

## Comparing a later reading

`Baseline.compare(from: "v3", to: "…")` **refuses** to call two figures
comparable when their conditions differ, and names which condition diverged. A
criterion measured once but not twice is reported as unmeasured rather than
dropped — a measurement that was not repeated is not a measurement that agreed.

The conditions stored with each figure include batch size, context window,
confidence floor, sample, and the code revision. Without those, a changed number
cannot be told apart from a changed instrument.

## What is not measured

- **Correctness.** 4 figures. 3 of them are the system agreeing or disagreeing
  with itself; 1 compares it against a second judge, which is agreement between
  two readers and not evidence that either is right. Nothing here compares the
  system's output to a *person's* judgement of the same text — which would be
  the most valuable next measurement, and is not a software task.
- **Any model but this one.** The OpenAI adapter has never been called.
