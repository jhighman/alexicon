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

The fix is better candidate detection, not a weaker sentinel. Options, roughly
in order of cost:

1. A common-noun lexicon, so capitalised dictionary words are not proposed.
2. Proposing only where capitalisation is unexplained by sentence position.
3. A named-entity model — which is itself a transformation and would need its
   own governance rather than being trusted directly.

Recorded rather than fixed, because the right answer depends on what documents
this is actually pointed at.
