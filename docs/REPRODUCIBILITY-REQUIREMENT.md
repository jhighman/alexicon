# Which uses actually need high reproducibility

**Revised 25 July 2026**, against a measurement that contradicted the first
version. What changed and why is recorded at the bottom rather than quietly
edited away.

Baseline v1 puts classification reproducibility at **88% overall** and **84.5%
on the interpretive/ontological pair**. The natural response is to treat that as
a defect to engineer away. The prior question is *for which uses is it a defect
at all* — and the answer turns on a measurement that was not taken until after
the first draft of this document argued from its absence.

---

## The measurement that decides it

The essay was classified twice under identical conditions, and the verdicts
derived from each set of categories:

| | |
|---|---|
| Unearned steps, run 1 | **43** |
| Unearned steps, run 2 | **34** |
| In both | **26** |
| Only in run 1 | 17 |
| Only in run 2 | 8 |
| **Jaccard similarity** | **0.51** |
| Count difference | 20.9% |

**The count moved 21%. The membership moved 49%.** Run the same document twice
and roughly half the flagged steps are different steps.

This matters more than the headline reproducibility figure, because almost
nothing consumes "88% of claims were typed the same". What gets consumed is
*which* claims and *which* steps.

---

## What actually drives the requirement

**D1 — Does a person examine every output, and does that help?**

Partly, and asymmetrically. A reviewer reading a flag can dismiss it, so human
review absorbs **false positives**. It does nothing about **false negatives**:
nobody reviews the flags that were not raised. Of run 1's 43 findings, 17 did
not appear in run 2 — and a reviewer working from run 2 has no way to know they
are missing.

So "a human checks everything" is weaker protection than it sounds. It bounds
what the system wrongly says, not what it silently fails to say.

**D2 — Item or aggregate?** *(rewritten; the first version had this backwards)*

The first draft claimed rates are far more stable than the items composing them,
citing the unearned rate holding at 21.2% → 20.8% across a re-segmentation. That
comparison was between two *different segmentations*, where the rate happened to
land in the same place. Under plain re-classification the rate itself moves 21%.

A rate is more stable than its membership **only when aggregated over enough
items**. Within one document it is not stable, and a single document's 21% should
be read as "roughly a fifth, ±a fifth". Across many documents item noise would
average out — but that is an assumption here, not a measurement.

**D3 — Must two subjects be treated alike?**

Unchanged, and now with more force. Where the output concerns people and
comparability is the ethical requirement, reproducibility is a **fairness**
property. Two equivalent records receiving different treatment is not noise; it
is unequal treatment.

---

## Where the churn actually lives

Only one component is non-deterministic. Segmentation, mention extraction,
identity resolution, governance-given-categories and the retroactive audit are
all rule-based and produce identical output every run — verified: governance
makes no model call, and its verdicts follow from categories by fixed rules.

**Classification is the sole source, and everything downstream inherits it.** A
step's verdict churns because its endpoints' categories churn. That is bad news
for the figures above and good news for remedy: there is one place to fix, not
five.

---

## Revised requirement by use

| Use | Requirement | Why |
|---|---|---|
| Corpus-level rate over many documents | **low** | D2 holds here and only here — averaging is what makes the rate mean something |
| Interactive composition | **low** | A missed nudge is a missed opportunity. The writer is composing, not relying. |
| Teaching category leaps | **low** | Disagreement is pedagogically useful |
| Reflective reading of one's own argument | **low–moderate** | Tolerable, but the reader should know a second pass would surface different sentences |
| **Document audit (CONOPS 6.1, primary)** | **moderate–high** ⚠ | *Revised upward.* An audit that differs by half its findings between runs is not an audit of the document; it is a sample of it. |
| STOP moment (6.4) | **not affected** | Identity resolution is deterministic; this path does not churn |
| Longitudinal monitoring | **high** | Instrument noise must be below the drift being detected; 49% churn is not |
| **Screening / evaluation (6.3)** | **high** | D1 fails at volume, D3 binds hardest |
| Regulatory or contested findings | **very high** | Must survive adversarial re-examination |
| Automated gating, no human | **very high** | Not supported, and should not be |

The first version of this document put **document audit — the primary scenario**
— in the low column. That was wrong, and the set-churn measurement is what shows
it. It remains true that most uses do not need 95%; it is no longer true that the
system's own primary use case is among them.

---

## What follows

1. **Report variance instead of hiding it.** Classify each claim two or three
   times and show the agreement beside the flag. This was a nicety in the first
   draft; at Jaccard 0.51 it is the minimum honest presentation. A flag reading
   "surfaced in 3 of 3 runs" and one reading "1 of 3" are different objects, and
   the system currently presents them identically.

2. **Prefer stable findings when coverage can be traded.** Keeping only findings
   that reproduce across runs would raise trust at the cost of surfacing fewer —
   a trade that can be measured rather than guessed, and one the current
   architecture supports without change.

3. **Fix classification, not the layers below it.** The churn has a single
   source. Effort spent on segmentation or governance stability buys nothing.

4. **Do not ship 6.3 or 6.1 on current numbers.** Screening was already excluded;
   document audit now joins it, unless the output is presented as a sample of
   what a reader should examine rather than as the document's audit.

---

## What changed in this revision

The first version argued that reproducibility matters in only a few uses, and
put document audit and reflective reading safely in the low column. It rested on
D2 — that rates are stable even when items are not — supported by a figure
(21.2% → 20.8%) that compared two different segmentations rather than two runs.

I flagged the gap in that version as an objection and called the check "cheap".
It was, and it came back against the argument: within one document, the rate is
not stable and the set is barely half stable.

I also proposed the wrong check. A second **governance** pass would have returned
identical verdicts, since governance is deterministic given categories — it would
have shown zero churn and been reported as reassurance. The churn is in
classification, and the check had to re-classify to find it.

The conclusion that survives: **most uses do not need high reproducibility, but
more of them need it than the first version claimed, and the primary scenario is
one of them.**

---

*Measured: the churn table, and that governance and the resolver are
deterministic. Reasoned: the requirement column, from D1–D3 and from what CONOPS
says each scenario does. n=1 on the churn comparison — one pair of runs, not a
distribution. See [BASELINE.md](BASELINE.md) and
[ATAM-interpretive-ontological.md](ATAM-interpretive-ontological.md).*
