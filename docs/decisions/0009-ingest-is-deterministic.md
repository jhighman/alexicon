# 9. Ingest is deterministic, and proposes rather than decides

**Date:** 2026-07-24
**Status:** Accepted
**Answers:** CONOPS §12 question 1 (segmentation granularity)

## Decisions

### Claims are sentences

Both source documents use the sentence as the unit in every worked example —
*"I experienced overwhelming peace."* / *"Therefore God exists."* Clause and
argumentative-move granularity were considered and rejected: neither can be
decided without interpreting the text, and interpretation is itself an
ungoverned transformation if it happens during ingest.

### Segmentation and extraction use no model

Segmentation is a binding. It decides what counts as a claim, and every later
judgement inherits that decision. A probabilistic splitter would place a
model's judgement underneath every subsequent judgement, where nothing governs
it. Both are therefore rule-based, testable, and legible in failure.

### The extractor proposes; the Sentinel disposes

Chapter 7.6 names "names become entities" as a binding requiring governance.
`MentionExtractor` never decides what a name refers to, and never decides that
an unrecognised name is not a name. It emits candidates; `IdentitySentinel`
rules on them.

Candidates come from two sources:

- **known** — surface forms already in the graph, matched in any case
- **capitalised** — capitalised token sequences, minus a stoplist of function
  words, with leading stopwords trimmed so "Therefore God" yields "God"

The second source is what makes out-of-distribution detection possible at all.
Without it an unknown name would never be extracted and so never flagged, and
the system would silently reason past every subject it had never met.

### Ingest builds the graph but does not judge it

Ingest creates claims, mentions and adjacent transitions, and verifies
identity. It records **no verdict** and classifies **nothing**. Chapter 6
requires the evaluator to be independent of the transformation it governs, so
the thing that constructs the graph must not also rule on it. Every transition
is left `proposed`, for a sentinel that did not build it.

Identity is verified during ingest because it precedes reasoning — a document
whose subjects are ungrounded is locked before anything can be classified.

## Known limitation: the extractor over-proposes

Run against real prose, capitalisation catches common nouns and brand names.
On a five-sentence excerpt it proposed *Ketamine*, *NMDA*, *Legos* and *God*
alongside the one real subject, and each became a STOP — locking the document
on four false positives.

This is the intended failure direction. Over-proposing produces noise a person
can dismiss; under-proposing produces silent reasoning about ungrounded
subjects, which is the failure the architecture exists to prevent. **But it is
noise, and at document scale it makes the lock impractical.**

### Resolved — but not the way this ADR proposed

Option 1 above, a common-noun lexicon, **is wrong**, and measurably so. The
system dictionary (`/usr/share/dict/words`) contains *alec* and *wednesday* but
not *ketamine* or *nmda* — it would suppress the real subjects and keep the
noise. Any general word list has this problem: personal names are words.

Option 2 was rejected on inspection. Suppressing sentence-initial capitalisation
kills *Ketamine* in "Ketamine blocks…" but also kills *Alec* in "Alec wrote…" —
real subjects start sentences as often as noise does.

**Structure cannot make this distinction.** "Ketamine" and "Alec" are both
capitalised words the extractor has never seen. The difference is world
knowledge, and no rule over the string will find it.

So the distinction is asked of a person **once**, and remembered:

| Answer | Effect |
|---|---|
| **Ground it** — this is a subject, here is its passport | Creates the referent, re-verifies the mention. The resolution *supersedes* the STOP, so one judgement stands. Resolves in every later document. |
| **Not a subject** | Records an `IgnoredForm` with its author, and *disposes* of the flag. The form is never proposed again. |

The two differ deliberately: grounding supersedes the flag, ignoring answers it.
Either way the record of why the document was ever blocked stays intact.

One structural rule did survive, because it follows the project's own axiom —
capitalisation that is *explained* is not evidence:

- **An all-capital token's case is explained by acronym convention**, not by
  proper-nounhood. `NMDA` is no longer proposed; a known acronym still matches
  through the `known` path, so `NASA` is unaffected.

Measured on the five-sentence excerpt from this ADR:

```
before:  Ketamine, Legos, God, Alec   (4 STOPs)
after:   God, Alec                    (0 STOPs — both grounded, both resolve)
taught:  Ketamine, Legos
```

This turns the extractor's weakness into the product's core loop: an unknown
name is not noise to filter, it is an ungrounded referent, and grounding it is
what the Cognitive Passport exists for.

**Residual limit.** The first document containing an unfamiliar name still
stops on it. That is the intended behaviour — it is the Sentinel refusing to
reason about a subject nobody has established — but it means the cost is paid
once per new name, not once per document. A named-entity model would reduce
the initial noise and would itself be a transformation requiring its own
governance; it is not needed to make the system usable.
