# 13. The reading view writes no prose

**Date:** 2026-07-25
**Status:** Accepted

## Context

The review surface rendered 72 identity cards beside 244 claim rows and 243 step
rows — the working memory of the analysis, not something anyone reads. On the
document in question none of it had run, so it was a parts bin with a
stylesheet.

The proposal considered was to have the model reframe the document as a
narrative with commentary annotations.

## Decisions

### The narrative is the one that was written

`DocumentReading` slices the body on claim offsets and returns the text in
order, with judgements attached to the sentences they concern: category shading,
a marker where a step was judged unearned, findings listed as they arise, and a
header saying what to look for before reading.

### No generated prose

A model retelling the document in its own words would read as more authoritative
than the record while being **less accountable** than it. The retelling would
become the artifact people cite, and the document would recede behind it. That
is fluency mistaken for grounding — the failure this project is named after.

It is the same reason `Polayani` was aliased rather than corrected: the document
said what it said.

### Reassembly is an obligation, pinned by spec

The segments must reassemble into *exactly* the body, and cover it once. The
first implementation dropped blank gaps because they contained no words — which
collapsed the essay into a single wall of text, reintroducing the readability
problem the view exists to fix.

### An empty finding column says it is empty

Where nothing has been judged the header says so, rather than showing a clean
column that reads as a clean bill of health.

## Rejected

**Model rewrites the document as the primary view.** Most readable, and it makes
the retelling the record.

**Model commentary alongside the text.** Not rejected in principle — the honest
form is a commentator agent whose synthesis is an attributable assertion with
confidence, visually marked as inference and sitting beside the text rather than
replacing it. Deferred rather than refused; the reading view had to exist first.

## Consequences

A reader sees the essay, shaded by what each sentence does, with the unearned
steps called out where they happen. What the view cannot yet show is the column
that matters most — governance stays gated on identity by
[ADR 11](0011-the-lock-guards-predication.md).
