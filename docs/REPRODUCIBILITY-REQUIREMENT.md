# Which uses actually need high reproducibility

**Conjecture, 25 July 2026.** Measured where it says measured; reasoned
elsewhere and labelled as such.

Baseline v1 puts classification reproducibility at **88% overall** and **84.5%
on the interpretive/ontological pair** — the framework's central distinction.
The natural response is to treat that as a defect to be engineered away. The
question here is prior to that: *for which uses is it a defect at all?*

---

## What actually drives the requirement

Reproducibility is a proxy. What matters is that a judgement does not change for
reasons unrelated to the text. Three things decide how much that costs:

**D1 — Does a person examine every output?**
If yes, the human absorbs the variance and the requirement collapses. A flag
that is wrong one run in six is still worth raising if someone reads it and
decides. This is the dominant driver.

**D2 — Is the unit of consumption an item or a rate?**
Rates are far more stable than the items composing them. Re-segmenting the
essay changed 26 claims and moved the unearned rate from **21.2% to 20.8%**
(measured). A use that consumes "this document promotes interpretation to
ontology 21% of the time" needs much less per-item stability than one consuming
"*this sentence* was unearned".

**D3 — Must two subjects be treated alike?**
Where the output concerns people and comparability is the ethical requirement,
reproducibility stops being a quality attribute and becomes a **fairness**
property. Inconsistency between two equivalent records is not noise; it is
unequal treatment.

---

## The four scenarios in CONOPS

| Scenario | Person reviews each output? | Unit | Requirement |
|---|---|---|---|
| **6.2** Interactive composition | yes, immediately | item, in the moment | **low** |
| **6.1** Document audit *(primary)* | yes, flag by flag | item, with disposition | **low–moderate** |
| **6.4** STOP moment | yes, by construction — it escalates | item | **moderate** |
| **6.3** Screening / evaluation guard | **often not, at volume** | item, about a person | **high** |

Three of the four stated scenarios put a human on every output, and F8 makes
that structural: *every classification is reversible and annotatable by a human
without destroying the machine's original judgment*. The architecture already
assumes the human is the check.

**6.3 is the exception, and it is the one that motivated the framework.** The
anti-discrimination case is evaluative screening: a gap in a record must not
become evidence of degradation. There, D1 fails (volume), D2 is per-item (a
decision about *this* candidate), and D3 binds hardest. At 84.5%, roughly one in
six borderline records could read differently on a re-run — and two candidates
with equivalent histories could be treated differently for no reason located in
their records. That is precisely the harm the protocol exists to prevent,
reintroduced by the instrument.

**So the conjecture holds, with a sharp edge:** high reproducibility is required
in a minority of uses, and the framework's own founding use case is in that
minority.

---

## Beyond CONOPS

| Domain | Requirement | Why |
|---|---|---|
| Reflective reading of one's own argument | **low** | The system is a prompt for attention. Being wrong sometimes costs a moment. |
| Teaching people to notice category leaps | **low** | Disagreement is pedagogically useful; the student argues with it. |
| Editorial / pre-publication self-review | **low–moderate** | Author reviews everything; misses cost a weaker paragraph. |
| Corpus-level research — "how often does this genre promote interpretation to ontology?" | **low per item, high on the rate** | D2. Item noise averages out; rate stability is what must be established. |
| Longitudinal monitoring of one body of text | **moderate–high** | The instrument's noise must be smaller than the drift being detected. Unmeasured. |
| Screening, hiring, credit, admissions | **high** | D3. Reproducibility is the fairness property. |
| Regulatory or legal use where a finding is contested | **very high** | The finding must be defensible on re-examination by an adversary. |
| Automated gating with no human in the loop | **very high** | D1 fails completely. Not a use this system currently supports, and should not without it. |

---

## Two objections to the conjecture

**The trust objection, and I think it is the strongest.** Even where any single
wrong flag is harmless, a reviewer who runs the same document twice and sees
different flags stops believing the tool at all. Low reproducibility is tolerable
in review contexts *only while nobody notices it* — which is an uncomfortable
place for a system whose entire argument is that judgements should be inspectable.
The honest resolution is not to hide the variance but to report it: a flag shown
with "this judgement reproduced 4 times in 5" is more useful than a flag shown
bare, and costs only repeated classification.

**The set-churn objection, and it is currently unmeasured.** A rate can be
perfectly stable while the *membership* churns entirely. If 43 steps are unearned
on both runs but they are largely *different* 43, then "how weak is this
document" is stable while "*which* arguments are weak" is not — and every use in
the low-requirement column consumes the second, not the first. D2's comfort
depends on set stability, and nothing measured establishes it.

That check is cheap and needs no model call beyond a second governance pass:
compare the *sets* of unearned steps across runs, not the counts. Until it is
run, "the aggregate is stable" should be read as "the aggregate *count* is
stable", which is a weaker claim than it sounds.

---

## What this implies

1. **Do not tune the classifier for 6.1 and 6.2.** They are review contexts with
   a person on every output; effort spent on the last few points of agreement
   there buys little.

2. **Do not ship 6.3 at 84.5%.** Screening is where D1 fails and D3 binds, and
   the framework's founding case is exactly there. Either the reproducibility
   requirement is met first, or 6.3 is scoped to advisory output with mandatory
   human decision — which is a change to what it claims to be, not a caveat.

3. **Report variance rather than hide it.** Repeated classification with the
   agreement rate shown per flag converts an unmeasured weakness into visible
   information, and fits the system's existing habit of stating what it does not
   know.

4. **Measure set churn before relying on rate stability.** It is the assumption
   holding up the entire low-requirement column.

---

*Conjecture, not finding. The domain requirements above are reasoned from D1–D3
and from what CONOPS says each scenario does; only the figures marked measured
are measured. See [BASELINE.md](BASELINE.md) and
[ATAM-interpretive-ontological.md](ATAM-interpretive-ontological.md).*
