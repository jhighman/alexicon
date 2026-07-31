# 23. Ingest unwraps before it segments

**Date:** 2026-07-31
**Status:** Accepted; `Document#normalise_body` on create, `source_body`
retained, existing documents untouched
**Source:** Running the dissertation through the Python kernel, which segmented
2,840 claims from 21,184 words and produced sentence fragments for over half of
them. Verified identical in the Ruby implementation before anything was changed.

## Context

`MarkdownStructure#boundaries` returns every line's start and end, not only the
structural ones. `ClaimSegmenter` adds those boundaries to its cut list whenever
a document contains any markdown block at all — one `#` heading is enough. So in
a markdown document every line break becomes a cut, and the
lowercase-continuation guard in `line_cuts` never gets the chance to protect a
hard-wrapped sentence.

The result is that prose wrapped at 72 or 80 columns is segmented into
line-length pieces:

| # | text |
|---|---|
| 2 | `Everything to this point governs transitions between claims.` |
| 3 | `This chapter asks a` |
| 4 | `question one level down, about the unit over which a judgment is entitled to be` |
| 5 | `made at all, and the answer changes the architecture.` |

`Security` and `They are failures of` arrive as claims. Each is then typed,
stepped over and judged.

On the dissertation, measured both ways:

| | as ingested | unwrapped first |
|---|---|---|
| Claims | 2,840 | 1,660 |
| Unterminated fragments | 1,365 (55% of substantive) | 244 |

Hard wrapping inflates the claim count by **1.71×**, and every extra claim costs
a model call at whatever repeat count the run is using.

**What this is not.** It is not a defect in the recorded baselines. Documents 27
and 30 were checked directly:

| Document | Substantive claims | Fragments | |
|---|---|---|---|
| 27 — the essay (v3 §1, §3) | 293 | 49 | 16.7% |
| 30 — the letter (v3 §4–§11) | 105 | 2 | **1.9%** |

Document 30 carries the case-scoped control and the 0.00 SE finding, and is
effectively clean. On document 27, fragmentation does not predict instability —
fragments went untyped at 3.6% against 3.0% for whole sentences — and the two
judges agreed on 100% of fragments against 53.6% of whole sentences. Fragments
are trivially easy to agree about, so if anything they were inflating the
inter-judge figure rather than depressing it.

So this is a forward-looking correction, not a repair.

## Decision

**A document is normalised once, at creation.** `Document#normalise_body` runs
`before_validation on: :create` and replaces `body` with
`MarkdownReflow.unwrap(body)`. The text as submitted is kept in `source_body`.

**The unwrap reuses `MarkdownReflow`.** What must not be joined — tables,
headings, rules, fences and their contents, blockquote structure, list items,
markdown hard breaks — is already defined there, and defining it a second time
is how two definitions drift apart. `unwrap` is `call` at a width wide enough
that nothing wraps. Reflowing to a finite width would leave the prose
hard-wrapped at that width, which is the condition being removed.

**Normalisation happens before claims exist, not during segmentation.** Ingest
still segments the body "by offset, without modifying it", and that sentence
stays true. By the time a `Document` exists, its body is what claims will be
offset against.

**The source is kept, so the transformation is recorded rather than performed
and forgotten.** `source_body` holds the submitted bytes; `normalised?` says
whether anything changed; the normalisation can be re-derived from the source
and checked.

**Existing documents are not backfilled and not re-segmented.** Their claims are
recorded measurements. Re-deriving them would move every figure taken from them
while leaving the record that says what was measured unchanged — which is the
precise failure this framework exists to prevent, committed against its own
baselines. `source_body` is NULL for those rows, and NULL means *the body is the
source*.

## Alternatives

**Fix `boundaries` to return only structural lines.** The narrower change, and
it was rejected. Those boundaries do real work: they stop a claim running from a
heading into the paragraph beneath it and across a table row. Narrowing them to
structural lines only would reintroduce exactly the leakage they were added to
prevent, and the fragmentation would remain wherever a line break fell
mid-sentence in a plain-text document.

**Reflow for segmentation only, leaving `body` untouched.** Rejected because
every claim's `char_start`/`char_end` would then point into a text that is
nowhere stored. A claim that cannot be traced to a span of something real is not
traceable at all.

**Do nothing and reflow inputs by hand.** Rejected. It makes correct
segmentation a property of how carefully somebody pasted, which is not a
property a measurement can rest on.

## Consequences

**Claim counts change for hard-wrapped documents, and that is a change of
conditions.** A figure taken from a document ingested after this decision is not
comparable with one taken from the same text ingested before it. The code
revision already travels with every figure, which is what makes the two
distinguishable — but a comparison across this boundary should be refused
rather than explained.

**Cost falls with the claim count.** Repeated reading multiplies model calls per
claim, so a 1.71× reduction on wrapped documents is a 1.71× reduction in spend
for those runs.

**`source_body` is a second copy of every document.** Storage in exchange for an
auditable transformation, which is the same trade the assertion record makes
everywhere else.

**What is deliberately not built:** no renormalisation path, no
re-segmentation task, and no backfill. A document is normalised once or never.
