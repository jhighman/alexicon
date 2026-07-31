# 20. Judgment waits for closure: the case is its unit

**Date:** 2026-07-31
**Status:** Accepted; `Case` derived from structure, `CaseObserver` built and
measured against the recorded pair-scoped controls
**Source:** Alexandra Krížová's answer to the third call (encoder or decoder,
asked three times), and Jeff's reframe of it. Her worked example is *Life is
Beautiful*: a father in a camp invents a game to shield his son, and every rule
he invents is a lie. A judge scoped to the sentence sees the lie and fires; only
a judge scoped to the closed episode can see Kindness put before Truth, which is
what the episode actually establishes.

## Context

She is keeping the Encoder. Her argument: a strictly masked decoder lives in the
present token, and a conscience that lives in the present token is "a blind,
rigid bureaucrat" — it catches the untruth and misses what the untruth was for.
Her mechanism is an asymmetric space-time geometry: forward-facing attention
attenuated much faster than backward-facing context, which caps the energy leak
of a symmetric window while keeping the global field connected.

Jeff's reframe separates two things her account runs together. The requirement
is real: **judgment must operate over completed causal structures, not
tokens** — a jury hears the whole case, deliberates, and only then judges,
because the ending is allowed to reinterpret the beginning. But the requirement
does not name the layer. In a transformer it must be met at the *representation*
layer, because you cannot defer evaluation over a representation that never
captured the horizon; her asymmetric decay is that layer's honest form of it. An
evaluation system has a different form available: **deferred evaluation** — do
not evaluate until the case closes. Same requirement, met where each
architecture can actually meet it.

This also bears directly on the value layer's recorded failure. Three designs
could not tell a real step from an unrelated pair, and the recorded diagnosis
was *the question has no ground truth in a found text*. Her answer sharpens the
diagnosis into something testable: perhaps the ground truth is not in the
**pair**, because nobody judges isolated sentences — it is in the closed
episode, which none of the three designs was ever shown.

## Decision

**A `Case` is the unit judgment waits for**, and it is a `Relationship` like
`Transition`: an edge from the first claim of an episode to its last, with
standing derived from assertions.

**Closure is the constructor, not a gate.** A case does not carry an `open`
flag a judge must remember to check; a case that has not closed *does not
exist*. `Case.derive!` creates a case only where its right boundary is
established — a structural claim (a heading restarts an argument; a signature
ends a letter), or the end of a completed document. In a growing document the
final run of claims is not a case yet, and nothing can be asked about it. The
invariant is enforced by what can be constructed, which is where this codebase
puts its guards.

The boundaries come from **structure**, which ingest already marks and which is
deliberately rule-based: where an episode begins and ends is a decision
everything downstream inherits, so it is not a model's to make. On document 30
the single structural claim is the signature — the letter closes where the
letter signs off, and the case is the whole narrative.

**`CaseObserver` asks the pair-scoped question at case scope.** Identical
question — a conflict at this step, or none — identical answer shape, with only
the visible scope changed. That identity is deliberate: it makes the
discrimination control comparable across scopes, so "was scope the missing
variable?" is a measured comparison rather than a design argument. The observer
proposes and does not rule.

## On the fourth-attempt commitment

Baseline v3 records: *"a fourth structural attempt should not be made on the
evidence of three; the remaining options are that a person validates the
readings, or the layer is retired."* This decision is adjacent to that line and
must answer to it.

The three attempts varied the vocabulary and the precondition **at fixed
scope** — pair in, judgement out. None varied the scope, and the diagnosis they
produced is a claim *about* scope: no ground truth **in a found text**, where
"text" meant the two sentences shown. Testing whether the ground truth appears
at the scope where humans actually judge is a test **of the diagnosis**, not a
fourth variation on the failed design. The distinction has teeth in both
directions: if the case-scoped control discriminates, the layer was a scope
problem; if it does not, the diagnosis survives its strongest challenge and the
retirement case is much stronger than three same-scope failures ever made it.

Nothing judged in the control is persisted as a standing reading, so the
person-validates-or-retire gate is untouched either way.

## Consequences

The composition scenario (CONOPS 6.2) inherits the invariant for free: text
still being written has an unclosed final run, so the observer structurally
cannot be asked about it — no flag to forget, nothing to check.

The 2×2 the value layer's fate now rests on, with the person-controls from the
worksheet:

| | pair scope | case scope |
|---|---|---|
| **machine** | 3.08 / 0.29 / 0.54 SE (v3) | this control |
| **person** | `ValueWorksheet` | open |

What is deliberately not built: no case-scoped verdicts, no case-level
`record_verdict!`, no report section. A capability is built when its measurement
exists, and the only measurement so far is the discrimination control. If the
control fails, none of that machinery should ever exist; if it discriminates,
each piece gets built against a figure rather than a hope.

## Result

**It failed, flatter than any design before it.** A conflict was found at 24 of
28 real steps and 24 of 28 pairs that were never an argument — 85.7% in both
arms, **0.00 standard errors** ([v3 §10](../BASELINE-v3.md)).

The direction is the finding. The closed episode did not ground the question; it
raised the decoy find-rate to the highest of any design. More context is more
material to build a dilemma from, and the caution recorded before the run — that
*Life is Beautiful* is the best possible case for scope, and that context made
the open-vocabulary judge invent more — is what the data shows.

So the diagnosis survives its strongest challenge: four designs, two scopes,
and the question has no ground truth in a found text at any scope a machine has
been given. The retirement case for the value layer now rests on that, and the
constructed conflict remains the only grounded way to ask a value question.

**The `Case` unit and closure-as-constructor are retained.** Deferred
evaluation was not what failed — judgment still should not outrun the episode,
and the composition scenario still needs an unaskable unclosed run. What failed
is the value question asked at that scope. No case-scoped judgement machinery
is built, per the paragraph above, and none should be.
