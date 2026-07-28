# Baseline v2

**Gemini 2.5 Pro · July 26, 2026**

*Generated from the recorded measurements — do not edit by hand. Re-render
with `rake "alexicon:baseline[v2]"`.*

What this system has measured about the model it runs on, written down so a
later reading has something to be compared against, and so the comparison is
honest rather than reassuring.

> **Taken across 2 code revisions** — `67fcc97`, `67fcc97-dirty`. Figures within this baseline were not all measured against the same instrument, so a difference between two of them may be a difference in the code. Each section states its own revision.

Also recorded: `v1` ([BASELINE.md](BASELINE.md)) and `v3` ([BASELINE-v3.md](BASELINE-v3.md)). These are **not revisions of each other** — each was taken under its own conditions, and `Baseline.compare` refuses a pair whose conditions diverged rather than reporting a difference that may be the instrument.

> **How to read a number here.** None of these say the model is right. They
> say whether it is *consistent*, which is a different and smaller claim. A
> model can be perfectly consistent and consistently wrong. Consistency is
> worth measuring because inconsistency makes every other question
> unanswerable.

Each figure is stored in the system as an assertion *about the model* —
attributable, challengeable, and superseded by a better measurement rather
than overwritten. If you re-measure, the earlier reading is still there.


---

## 1. Repeated reading — agreement and coverage — 26 unstably read, was 41

*Thirteen lead-ins and headings are no longer queued as claims. What did that buy, and what did it leave?*

| | |
|---|---|
| steps | 281 |
| typed | 259 |
| claims | 293 |
| unearned | 50 |
| never read | 30 |
| undetermined | 51 |
| unstably read | 26 |
| readings per claim — 0 | 30 |
| readings per claim — 1 | 12 |
| readings per claim — 2 | 14 |
| readings per claim — 3 | 237 |
| readings requested | 3 |

The first measurement under v2 segmentation. Its purpose is the comparison against v1, which used a segmentation that marked nothing structural at all.

What the segmentation change bought, and what it did not. Claims given an unstable 1 or 2 readings of 3 fell from **41 to 26**, and what remains is mostly prose rather than fragments.

The never-read population did not move at all: 30 either way. Those are the cells of a table flattened to one line per cell before the text was ever pasted, plus the title block. The segmenter refuses to guess about runs of short unterminated lines — the rule that did once swallowed 49 claims including the framework's own category definitions — so this was expected rather than a shortfall.

**Sample:** note the same source text as document 20, re-ingested under the current segmenter, claims 293, document 26, segments 307, structural 14  
**Conditions:** majority strict — more than half, readings 3, batch size 12, segmentation current segmenter — 14 structural of 307, including the colon lead-in rule (ADR 16) and the own_line? whitespace fix, context claims 4, declines count toward readings yes  
**Code:** `67fcc97`

**What this cannot tell you.**
- NOT comparable to v1 section 8 as a like-for-like figure: the sample is different by construction. 293 substantive claims against 306, because 13 lead-ins and headings are now structure. Baseline.compare refuses the pair and names the condition that diverged, which is the correct behaviour.
- The segmentation change did what was claimed of it and no more. Unstably read claims — those given 1 or 2 readings of 3 — fell from 41 to 26, a 37% drop, and the remainder are mostly genuine prose rather than fragments.
- It did NOT reduce the never-read population, which is 30 in both. Those are the cells of a table flattened to one line per cell before the text was pasted, plus the title block. The segmenter deliberately refuses to guess about runs of short unterminated lines, so this was expected and is not a shortfall against what was attempted.
- Coverage was measured once at each segmentation. Section 12 found coverage itself unstable between passes — 30 unread against 51 on the same document — so a single reading of the coverage figure carries that variance and the 41-to-26 improvement is not established beyond it.

## 2. Finding-set churn (coverage-corrected) — 75.0% judging the same steps, 63.9% overall

*When two passes flag different steps, is it because they disagree about the step, or because one of them could not judge it at all?*

| | |
|---|---|
| rate | 75.0% |
| in both | 39 |
| only pass1 | 11 |
| only pass2 | 11 |
| jaccard raw | 63.9% |
| unearned pass1 | 50 |
| unearned pass2 | 50 |
| claims compared | 293 |
| claims typed alike | 254 |
| claims typed pass1 | 259 |
| claims typed pass2 | 252 |
| steps judgeable pass1 | 230 |
| steps judgeable pass2 | 220 |
| zero reading claims pass1 | 30 |
| zero reading claims pass2 | 35 |
| jaccard where both could judge | 75.0% |
| only pass1 undetermined in pass2 | 6 |
| only pass2 undetermined in pass1 | 3 |
| only pass1 judged earned in pass2 | 5 |
| only pass2 judged earned in pass1 | 8 |

The same churn measurement as v1, taken after 13 lead-ins and headings stopped being queued as claims.

**The asymmetry v1 could not explain is gone.** It was 20 steps flagged in one pass against 6 in the other; here it is 11 against 11, and the unearned counts are identical at 50 and 50 where v1 moved 55 to 41.

Everything moved the same way once 13 lead-ins stopped being queued as claims — raw 0.574 to 0.639, corrected 0.70 to 0.75, count movement 25% to nothing. That is **consistent with** the lead-ins having been the unstable population, and it is one pair of passes at each segmentation. Four indicators from one pair are not four confirmations.

**Sample:** note the same source text as document 20, re-ingested under the current segmenter, steps 281, claims 293, passes 2, document 26, readings per pass 3  
**Conditions:** pass1 the recorded three-reading state, persisted, pass2 three fresh readings held in memory, nothing written, majority strict — more than half, batch size 12, segmentation current segmenter — 14 structural of 307, colon lead-in rule (ADR 16) and the own_line? whitespace fix, context claims 4, corrected over steps both passes could judge  
**Code:** `67fcc97-dirty`

**What this cannot tell you.**
- The asymmetry v1 could not explain is GONE. It was 20 steps flagged only in one pass against 6 in the other; here it is 11 against 11, which is what exchangeable passes should look like. Unearned counts are identical at 50 and 50, against 55 and 41 in v1.
- Every indicator moved the same way — raw Jaccard 0.574 to 0.639, corrected 0.70 to 0.75, count movement 25% to 0%, asymmetry 20:6 to 11:11 — but this is ONE pair of passes at each segmentation. Four indicators from one pair are not four independent confirmations.
- NOT a like-for-like comparison with v1. The sample is different by construction: 293 claims against 306, 281 steps against 305. Baseline.compare refuses the pair and names segmentation as the condition that diverged. The improvement is consistent with the lead-ins having been the unstable population; it is not established by this.
- A batch failed with a connection error during round 3 of pass 2, and that round took 1464s against roughly 570s for the others. Pass 2 ended with 35 claims unread against pass 1's 30, and some of that is infrastructure rather than the model declining.
- Still one document, still a pair of passes.

---

## Comparing a later reading

`Baseline.compare(from: "v2", to: "…")` **refuses** to call two figures
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
