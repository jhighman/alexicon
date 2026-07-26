# 16. A line ending in a colon is structure, not a claim

**Date:** 2026-07-26
**Status:** Accepted; `ClaimSegmenter#lead_in?`, and the reversed spec records
what it costs
**Source:** Jeff's decision. The rule was written, measured, backed out for
contradicting an earlier one, and put back on his instruction.

## Context

An investigation into why 30 claims in the essay under analysis received no
classifier reading at all found two populations. Most were the cells of a table
flattened to one cell per line before it was ever pasted — not reachable, and
[not something the segmenter should guess about](../../app/services/claim_segmenter.rb).
The rest were **lead-ins**: `Postscript:`, `What I learned in this:`, `Source
document:`, `The Enlightenment model is:`, `So, here we go:`.

The classifier declines to type them, correctly, because they are not claims
about anything. But they sat in the substantive queue, in the denominator of
every recorded measurement, and — more damagingly — they were typed on one
reading and declined on the next. Nine of the document's 41 unstably-read
claims are lead-ins. `BASELINE.md` §12 found coverage itself moving between
passes, 30 unread claims against 51, and this is part of why.

An earlier decision had gone the other way. A spec asserted that a
colon-terminated line is **not** structure, and its title gave the reason:
*"which introduces what follows."*

## The tension, stated honestly

The two positions are both defensible, and the disagreement is not about the
colon.

- `Postscript:` asserts nothing. It is a label.
- `Polanyi reverses it:` **asserts that Polanyi reverses it.** It is a claim
  that happens to introduce its own elaboration.

Separating those means deciding whether a line *predicates*. That is
interpreting the text — and segmentation is deterministic on purpose, because
it decides what counts as a claim and everything downstream inherits that
decision where nothing governs it. A rule that had to parse for a finite verb
would put a reading of the text underneath every later judgement.

So there is no rule here that is right everywhere. There are two rules, each
wrong somewhere:

| | leaves in the queue | hides from every later judgement |
|---|---|---|
| **no colon rule** | every lead-in, unstably read | nothing |
| **colon rule** | nothing | claims that end in a colon |

## Decision

Take the colon rule. A line is structure when it ends in a colon, sits alone on
its line, and is within the heading length bound.

The length bound is what keeps the loss small: a full sentence ending in a colon
is normally longer than 60 characters and stays a claim. `own_line?` is what
keeps it narrow: a colon mid-paragraph is untouched.

No isolation test, unlike the heading rule. Isolation exists because a *run* of
short unterminated lines is a flattened table whose cells may be real content. A
run of colon-terminated lines is not a shape tables take.

## Consequences

On the essay: structural segments go from 8 to 14 of 307.

**Content will be hidden.** `Polanyi reverses it:` is now structure and will not
be typed, judged, or counted, and it does make an assertion. The spec that used
to forbid this now asserts it, with a comment saying it is the price rather than
an oversight — a reversed decision should be visible in the test that reverses
it, not quietly deleted.

Marking real content as structure is the failure mode the segmenter's own
comment warns about, and this accepts a small amount of it on purpose. The
earlier and much larger instance — the rule that swallowed 49 claims including
the framework's own category definitions — remains refused. Isolation still
governs runs of short lines.

Segmentation is per-ingest, so this changes nothing already stored. Documents
ingested before this rule keep the claims they were given, which is the right
behaviour for an immutable record and means a re-ingested document is a
different sample rather than a corrected one. A measurement taken across the
change is not comparable, and `Baseline.compare` will say so.

## See also

- [0009 — Ingest is deterministic](0009-ingest-is-deterministic.md), the
  constraint this decision had to stay inside
- `BASELINE.md` §12 — coverage instability between passes, which lead-ins
  contribute to
