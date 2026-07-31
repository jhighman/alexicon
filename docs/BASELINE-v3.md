# Baseline v3

**Gemini 2.5 Pro · July 31, 2026**

*Generated from the recorded measurements — do not edit by hand. Re-render with
`rake "alexicon:baseline[v3]"`.*

What this system has measured about the model it runs on, written down so a
later reading has something to be compared against, and so the comparison is
honest rather than reassuring.

> **Taken across 9 code revisions** — `9831dc6`, `91dee52`, `376b990`,
> `38722b1-dirty`, `71f1a4e`, `d256d57-dirty`, `a28a1c2-dirty`, `3a177ba-dirty`,
> `bf84928-dirty`. Figures within this baseline were not all measured against
> the same instrument, so a difference between two of them may be a difference
> in the code. Each section states its own revision.

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

## 5. Value inference discrimination (closed vocabulary) — 71.4% on real steps, 67.9% on unrelated ones

*The open vocabulary let the judge invent. Does giving it a fixed list to choose
from stop that?*

| | |
|---|---|
| rate | 3.6% |
| real rate | 71.4% |
| real recorded | 20 |
| shuffled rate | 67.9% |
| pairs each arm | 28 |
| standard errors | 29.0% |
| vocabulary size | 16 |
| shuffled recorded | 19 |
| open vocabulary real | 92.9% |
| open vocabulary shuffled | 60.7% |
| open vocabulary standard errors | 3.08 |

Whether closing the judge's vocabulary fixed the invention the open vocabulary
showed. It did not.

**No. It made it worse, and this was the proposed fix.** Closing the list cut
the real-step read rate 92.9% to 71.4% — the abstention it was meant to buy —
and raised the shuffled rate 60.7% to 67.9%. The gap fell from 3.08 standard
errors to **0.29**. The discrimination that survived an open vocabulary did not
survive a closed one.

The likely mechanism is untested and worth stating anyway: sixteen broad values
can be read into almost any pair of claims, so a menu that wide makes invention
*easier*. Which means Alexandra Krížová's design does not transfer as described
— her closed set is **two** values, the pair the probe put in conflict. The
defence is not closure, it is closure **scoped to the case**.

**Sample:** document 30, shuffled same category pair as each real step, source
and target at least 20 positions apart, unearned steps 28  
**Conditions:** judge step-value-judge via gemini-2.5-pro, persisted no,
categories 5, vocabulary alexicon-2.0, 16 values, closed — the judge picks a key
or answers none, confidence floor 85.0%  
**Code:** `38722b1-dirty`

**What this cannot tell you.**
- THE FIX FAILED AND MADE IT WORSE. Closing the list cut the real-step read rate
  from 92.9% to 71.4%, which is the abstention it was supposed to buy — but it
  RAISED the shuffled rate from 60.7% to 67.9%. The gap fell from 0.321 (3.08
  standard errors, interval excluding zero) to 0.036 (0.29 standard errors). The
  discrimination that survived the open vocabulary is gone.
- The likely mechanism, and it is UNTESTED: sixteen broad values — Generality,
  Purpose, Affirmation, Coherence — can be read into almost any pair of claims.
  A menu that wide makes invention easier rather than harder, because something
  on it always plausibly fits.
- Which means Alexandra Krížová's design does not transfer the way it was
  described. Her judge's closed set is TWO values, the pair the probe itself put
  in conflict. The defence is not closure, it is closure SCOPED TO THE CASE. A
  global menu is nearly as permissive as no menu.
- The judge's own read rate is not stable between runs. The same vocabulary on
  the same 28 steps gave 23 readings in one run and 20 in another — 82% against
  71% — so differences below about ten points mean nothing here.
- One document, 28 pairs an arm, one model, one vocabulary. A vocabulary of more
  specific values might discriminate where this one does not; nothing here tests
  that.

## 6. Vocabulary substitution (a second account of what is protected) — 23 of 28 read against one list, 11 against another

*Is the value vocabulary a parameter of the framework, or one worldview seeded
and called structure?*

| | |
|---|---|
| rate | 39.3% |
| steps | 28 |
| shared keys | 2 |
| alexicon rate | 82.1% |
| alexicon read | 23 |
| alexicon values | 16 |
| objectivist rate | 39.3% |
| objectivist read | 11 |
| objectivist values | 11 |
| alexicon reached for — agency | 2 |
| alexicon reached for — purpose | 4 |
| alexicon reached for — autonomy | 1 |
| alexicon reached for — coherence | 1 |
| alexicon reached for — generality | 9 |
| alexicon reached for — affirmation | 5 |
| alexicon reached for — independence | 1 |
| objectivist reached for — reason | 1 |
| objectivist reached for — honesty | 1 |
| objectivist reached for — purpose | 3 |
| objectivist reached for — self-esteem | 1 |
| objectivist reached for — independence | 4 |
| objectivist reached for — rational self-interest | 1 |

Whether the value vocabulary is genuinely a parameter of the framework or one
worldview seeded and called structure.

**Structurally, yes.** A second framework carrying Rand's cardinal values and
virtues slots in, the judge reads against whichever list it is given, and the
reading records which one produced it. Where the two vocabularies share a key
they agree; everywhere else they diverge — the vocabulary is doing the work, not
the model's prior.

**And the comparison is rigged in the home vocabulary's favour.** Its eight
proposed values were written hours earlier by reading this document's own value
readings. It fits this letter because it was fitted to it, so 82% against 39%
says nothing about which account of what people protect is better.

**Sample:** document 30, unearned steps 28  
**Conditions:** judge step-value-judge via gemini-2.5-pro, persisted no,
categories 5, vocabulary a alexicon-2.0, 16 values, vocabulary b
objectivist-1.0, 11 values — Rand's three cardinal values and seven virtues  
**Code:** `38722b1-dirty`

**What this cannot tell you.**
- STRUCTURALLY IT IS A PARAMETER. A second framework carries its own values, the
  judge reads against whichever it is given, the reading records which
  vocabulary produced it, and the first vocabulary is untouched. Swapping it
  changes the reading substantively rather than cosmetically.
- THE COMPARISON IS NOT FAIR AND THE ALEXICON SIDE IS THE CHEAT. Its eight
  proposed values were written hours earlier by reading this document's own
  value readings. It reads this letter well because it was fitted to this
  letter. The 82% against 39% is not evidence that one account of what people
  protect is better than the other.
- Where the two vocabularies share a key — purpose, independence — they agree.
  Everywhere else they diverge. That is the vocabulary doing the work rather
  than the model's prior, which is the one thing this does establish.
- The Objectivist vocabulary declined 17 of 28. Whether that is a vocabulary
  that does not fit the text, or simply one whose values are more specific and
  therefore harder to apply, is NOT settled here and the two are easily
  confused.
- Both arms are single runs, and the judge's read rate moves about ten points
  between runs on identical input.

## 7. Framework substitution (a tradition that rejects hume's guillotine) — 4 verdicts differ of 20 pairs, 0 outside the two that changed

*The promotion weights encode a meta-ethics. Can the architecture carry a
tradition whose central move it currently flags by construction — and does the
disagreement stay where the traditions actually differ?*

| | |
|---|---|
| rate | 100.0% |
| essay steps | 223 |
| letter steps | 104 |
| ordered pairs | 20 |
| differing moves — normative->ontological | 2 |
| differing moves — ontological->normative | 2 |
| weights changed | 2 |
| verdicts that differ | 4 |
| essay unearned alexicon | 55 |
| essay unearned lewisian | 54 |
| letter unearned alexicon | 28 |
| letter unearned lewisian | 25 |
| divergences outside the changed pairs | 0 |

Whether the architecture can carry a tradition whose central move it currently
flags by construction, and whether the resulting disagreement localises where
the traditions actually differ.

**It localises exactly.** Two weights changed of twenty ordered pairs — the
is/ought crossing in both directions, from 2 to 0 — and every one of the four
differing verdicts across 327 steps is one of those two pairs. Zero divergences
elsewhere. A tradition can be swapped in and the disagreement stays legible
rather than diffusing through the whole judgement.

**What this does not show is more interesting than what it does.** Four of 327
steps is a fact about a personal letter and an essay, neither of which argues
the point; a text arguing *for* objective morality would diverge far more and
none has been run. And it tests governance only — the classifications are
shared, so nothing here says the **category boundaries** are tradition-neutral,
and §3 already shows two readers of the same text do not agree on them.

The finding that prompted it stands on its own: `ontological → normative` was
weighted 2 with a rationale naming Hume. That is a meta-ethical commitment
seeded as though it were structure, and it flags the central argument of several
traditions before any model reads a word.

**Sample:** documents 30, 27, judgeable steps 327  
**Conditions:** persisted no, categories 5, framework a alexicon-2.0 —
ontological <-> normative weighted 2 in both directions, rationale naming Hume,
framework b lewisian-1.0 — identical in all 20 ordered pairs except those two,
which are 0: what a thing is determines what it is for, and an obligation
experienced as objective points beyond preference, classifications shared and
unchanged — no text was re-read and no model was called  
**Code:** `71f1a4e`

**What this cannot tell you.**
- IT LOCALISES EXACTLY. Every one of the four differing verdicts is one of the
  two pairs that were changed; zero divergences elsewhere. That is the property
  being tested — a tradition can be swapped in and the disagreement stays
  legible instead of diffusing through the whole judgement.
- THE EFFECT IS SMALL BECAUSE THESE DOCUMENTS BARELY ARGUE THE POINT. Four of
  327 judgeable steps. That is a fact about a personal letter and an essay, not
  evidence of robustness. A text that argues FOR objective morality would
  diverge far more, and none has been run.
- This tests the GOVERNANCE layer only. The classifications are shared, so
  nothing here says the category boundaries are themselves tradition-neutral —
  and sections 3 and 4 of this baseline already show those boundaries are
  underdetermined between two readers of the same text.
- Two weights were changed, deliberately, to isolate the variable. A fuller
  Lewisian framework would likely differ in more than two — justification_rank
  for ontological, at least — so this establishes that a two-weight difference
  localises, not that the architecture can carry Lewis.
- Policy is the only framework object NOT scoped to a framework, so both
  frameworks share the anti-discrimination policy. A tradition differing on a
  cross-cutting constraint cannot currently be expressed.

## 8. Value priority judge control (responses revealing no priority) — abstained on 8 of 8 ambiguous responses

*§4 of v1 reads four unanimous probes as order stability. That holds only if the
judge declines when a response reveals nothing. Does it?*

| | |
|---|---|
| rate | 100.0% |
| by kind — refusal | 3 of 4 named |
| by kind — both-and | 0 of 4 named |
| by kind — restates | 0 of 4 named |
| by kind — off-topic | 3 of 4 named |
| by kind — too-brief | 2 of 4 named |
| all responses | 20 |
| abstained on those | 8 |
| named a winner overall | 8 |
| named a winner on those | 8 |
| behaviour revealing responses | 12 |
| genuinely ambiguous responses | 8 |

The control BASELINE v1 section 4 never had. It records four probes, all
unanimous, and reads that as order stability — which holds only if the judge
declines when a response reveals nothing.

**It declines — 8 abstentions out of 8** on responses that genuinely reveal
nothing: a both-and answer, or a restatement of the question. §4 stands.

The control's first design was wrong in a way worth recording. It counted
refusal, deflection and one-word compliance as non-revealing; they are not. The
judge's own taxonomy names *refused* and *deflected* as behaviours, and refusing
to help somebody stop their medication **is** choosing Safety over Autonomy.
Reading those is the method working. Correcting the control strengthened the
result rather than weakening it, which is not the usual direction.

**Set against §5 this is the sharpest contrast in the file.** The step value
judge named a commitment on 68% of claim pairs with no relation at all; this one
abstained on everything ambiguous it was shown. The difference is the answer set
— **two values scoped to the case** against sixteen on a global menu. Closure
scoped to the case does real work; closure as such does not.

**Sample:** total 20, probes 4, responses per probe 5  
**Conditions:** note independent of the claim categories; the probe layer does
not use them, judge value-priority-judge via gemini-2.5-pro, persisted no,
answer set closed to the two values the probe put in conflict — a reading is
discarded unless both come from that pair, confidence floor 70.0%  
**Code:** `d256d57-dirty`

**What this cannot tell you.**
- SECTION 4 STANDS, on the responses that actually test it. Presented with a
  both-and answer or a restatement of the question — responses that genuinely
  reveal no priority — the judge abstained 8 times out of 8.
- MY CONTROL DESIGN WAS PARTLY WRONG, and correcting it strengthens the result
  rather than weakening it. I counted refusal, deflection and a one-word
  compliance as non-revealing. They are not: the judge's own taxonomy names
  `refused` and `deflected` as behaviours, and refusing to help someone stop
  their medication IS choosing Safety over Autonomy. Reading those is the method
  working, not the method confabulating.
- So the headline 40% is misleading and the 8-of-8 is the figure. It is also
  n=8, which is small.
- This contrasts sharply with the step value judge, which named a commitment on
  68% of claim pairs that had no relation at all. The difference between the two
  is the answer set: two values scoped to the case here, sixteen on a global
  menu there. Closure scoped to the case is doing real work; closure as such is
  not.
- Four probes, one model, one run. The probes were written by the same person
  who wrote the method.

## 9. Value inference discrimination (conflict as a precondition) — 60.7% on real steps, 53.6% on unrelated ones — attempt three

*Her probe builds the conflict, so her judge rules on one known to exist. A step
found in a text has none built. Does supplying the missing precondition fix what
closing the vocabulary did not?*

| | |
|---|---|
| rate | 7.1% |
| real rate | 60.7% |
| real found | 17 |
| shuffled rate | 53.6% |
| pairs each arm | 28 |
| shuffled found | 15 |
| standard errors | 54.0% |
| attempt 3 two stage | 54.0% |
| attempt 1 open vocabulary | 3.08 |
| attempt 2 closed vocabulary | 29.0% |

The third repair. Alexandra Krížová's probe CONSTRUCTS a conflict, so her judge
rules on a dilemma known to exist; a step found in a text has no such
construction. Making the conflict a precondition was meant to supply what was
missing.

**No, and that is three.** A tension was found in 61% of real steps and 54% of
unrelated pairs — 0.54 standard errors. Open vocabulary 3.08 SE but inventing
three times in five; closed vocabulary 0.29; conflict-as-precondition 0.54.
**The only version that discriminated is the one that invented most.**

The diagnosis that fits all three: *the question has no ground truth in a found
text*. Her method works because the probe **builds** the conflict, so its
existence is not in doubt. A found step either has one or does not and there is
no independent way to tell — so asking whether a conflict exists is itself an
ungrounded judgement. The repair moved an ungrounded judgement one stage earlier
and grounded nothing.

**An architecture cannot fix this, and a fourth structural attempt should not be
made.** What remains is a person validating the readings, or retiring the layer.

**Sample:** document 30, shuffled same category pair, source and target at least
20 positions apart, unearned steps 28  
**Conditions:** design two stage — StepTensionProposer asks whether two
commitments are in conflict at all and may answer none; only then does
StepValueJudge rule on which came first, as a binary with a refusal, persisted
no, categories 5, measured at stage 1, which is the gate  
**Code:** `a28a1c2-dirty`

**What this cannot tell you.**
- IT FAILED TOO. A tension was found in 61% of real steps and 54% of unrelated
  pairs — 0.54 standard errors, indistinguishable from none. Three attempts now:
  open vocabulary 3.08 SE but inventing three times in five, closed vocabulary
  0.29, conflict-as-precondition 0.54. The only version that discriminated is
  the one that invented most.
- THE DIAGNOSIS THAT FITS ALL THREE: the question has no ground truth in a found
  text. Her method works because the probe builds the conflict, so its existence
  is not in doubt. A found step either has one or does not, and there is no
  independent way to tell — so asking a model whether a conflict exists is
  itself an ungrounded judgement. The repair moved an ungrounded judgement one
  stage earlier rather than grounding anything.
- An architecture cannot fix this. A fourth structural attempt should not be
  made on the evidence of three; the remaining options are that a person
  validates the readings, or the layer is retired.
- The two-stage design was kept despite showing no gain, and that is a judgement
  rather than a finding. It reads fewer steps, splits proposing from ruling as
  the Sentinel Principle asks, and costs one extra call per step. None of that
  is measured improvement.
- One document, 28 pairs an arm, one model, one run — and the judge's own read
  rate moves about ten points between runs on identical input, which is most of
  the gap being reported.

## 10. Premise preservation (two moral premises held at once) — 3.2%

| | |
|---|---|
| rate | 3.2% |
| steps | 104 |
| agreeing | 90 |
| differing | 3 |
| drifting steps | 0 |
| contested steps | 0 |
| differing moves — normative -> ontological | 1 |
| differing moves — ontological -> normative | 2 |
| ruled under both | 93 |
| outside the changed pairs | 0 |

The measurement that could not previously be taken. Verdicts were derived
newest-wins across every ruling regardless of origin, so a second framework's
rulings were indistinguishable from the first framework's sentinel changing its
mind. The earlier Lewisian run is recorded in this same baseline as `persisted:
false` for exactly that reason.

**Sample:** document 30, frameworks alexicon-2.0, lewisian-1.0, differing
weights {"normative -> ontological" => "hume 2, lewis 0", "ontological ->
normative" => "hume 2, lewis 0"}  
**Conditions:** judge GovernanceSentinel, which is DETERMINISTIC — it reads
CategoryPromotion weights and calls no model. The classifications it rules on
came from gemini-2.5-pro, which is why a model is named here at all, design each
ruling carries the framework it was made under; verdicts are read per framework
rather than newest-wins, persisted yes, categories 5  
**Code:** `3a177ba-dirty`

**What this cannot tell you.**
- THE ARCHITECTURE NOW HOLDS TWO INCOMPATIBLE PREMISES WITHOUT COLLAPSING
  EITHER. Hume and Lewis both rule on all 93 steps; both sets stand; neither
  supersedes the other. They differ on 3, all of them `ontological <->
  normative` — the two pairs whose weights differ and no others.
- That localisation is the result, and it is a weaker claim than it looks. It
  shows a premise change propagates only where the premise changed, which is a
  property of a deterministic weight lookup rather than evidence that the
  framework 'survives' a foreign moral premise in any deeper sense.
- THE DIFFERENCE IS NOT AN EVALUATION. Nothing here says Hume or Lewis reads the
  document better. Which premise is right is not a question this system can put,
  and the reports refuse to rank them.
- SIX STEPS IN THE WIDER RECORD CARRY TWO CONTRADICTORY RULINGS from the same
  sentinel under the same framework. They are now reported as drift rather than
  silently resolved to the later one. The Sentinel is deterministic, so its
  inputs moved — the claims were re-classified between runs — which makes these
  a fact about classification stability, not about the Sentinel.
- ZERO CONTESTED STEPS EXIST. Nothing has yet been ruled on by two different
  judges under the same premises, so the contested path is exercised only by
  specs. The capability is built and unmeasured.
- One document, one pair of frameworks, one run, and both frameworks were
  written by the same people who wrote the system.

## 11. Value inference discrimination (case scope — deferred evaluation) — 0.0%

| | |
|---|---|
| rate | 0.0% |
| real rate | 85.7% |
| real found | 24 |
| shuffled rate | 85.7% |
| pairs each arm | 28 |
| shuffled found | 24 |
| standard errors | 0.0% |
| attempt 3 two stage | 54.0% |
| attempt 4 case scope | 0.0% |
| attempt 1 open vocabulary | 3.08 |
| attempt 2 closed vocabulary | 29.0% |

The test of the diagnosis, not a fourth variation on the failed design. The
three prior attempts varied vocabulary and precondition at fixed pair scope;
this varied the scope itself, to the unit where humans actually judge — the
closed episode. If ground truth existed anywhere in a found text, case scope was
its best remaining hiding place.

**Sample:** case the whole letter — one closed episode, claims 1-105, bounded by
the signature, document 30, shuffled same category pair, source and target at
least 20 positions apart, drawn fresh under seed 1; construction-identical to
the recorded controls, not the same decoy instances, unearned steps 28  
**Conditions:** design deferred evaluation — CaseObserver is shown the COMPLETE
closed episode with the step marked, and asks the same stage-1 question as the
pair-scoped proposer: a conflict at this step, or none. Closure is the
constructor: a case that has not closed cannot be asked about, source Alexandra
Krížová's answer to the third call — judgment operates over completed causal
structures, and the ending may reinterpret the beginning, persisted no,
categories 5  
**Code:** `bf84928-dirty`

**What this cannot tell you.**
- ZERO DISCRIMINATION — the flattest result of the four designs. A conflict was
  found at 24 of 28 real steps and 24 of 28 pairs that were never an argument:
  85.7% in both arms, 0.00 standard errors.
- THE DIRECTION IS THE FINDING. The closed episode raised the decoy find-rate to
  the highest of any design (54-68% at pair scope, 85.7% here). More context did
  not ground the question; it supplied more material to build a dilemma from.
  The caution recorded before the run — that an episode is more to invent with,
  and Life is Beautiful is the best possible case for scope — is what the data
  shows.
- THE DIAGNOSIS SURVIVES ITS STRONGEST CHALLENGE. Four designs, two scopes, one
  conclusion: the question has no ground truth in a FOUND text, at any scope a
  machine has been given. The retirement case for the layer now rests on four
  failures rather than three same-scope ones, and the constructed conflict — the
  probe layer, where the dilemma is built rather than found — remains the only
  grounded way to ask a value question of anything.
- WHAT THIS DOES NOT TEST: deferred evaluation as an architecture. Closure as
  the constructor stands on its own argument — judgment should not outrun the
  episode — and the Case unit is retained for it. What failed is the value
  question asked at that scope, by this model.
- The 2x2 has one cell still open that matters: a PERSON at pair scope (the
  worksheet, generated and unanswered). A person discriminating where four
  machine designs could not would reopen the layer as a model problem; a person
  failing too would close it on the only evidence that is not a model's failure.
- One document, 28 pairs an arm, one model, one run. The decoys are
  construction-identical to the recorded controls but freshly drawn, so
  arm-level figures are comparable and item-level ones are not.

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

- **Correctness.** 11 figures. 10 of them are the system agreeing or disagreeing
  with itself; 1 compares it against a second judge, which is agreement between
  two readers and not evidence that either is right. Nothing here compares the
  system's output to a *person's* judgement of the same text — which would be
  the most valuable next measurement, and is not a software task.
- **Any model but this one.** The OpenAI adapter has never been called.
