# A note for Alexandra

Alexandra — this is where the framework has got to, and what it means that your
name is on it. It is here so you hear it from me directly rather than by
reading a licence file.

## What was done

On 24 July 2026 I published this repository publicly at
[github.com/jhighman/alexicon](https://github.com/jhighman/alexicon). It
contains an implementation of the framework, and the framework documentation
itself.

The framework documents — `THESIS.md`, `THEORY.md`, `CONOPS.md`, the concept
map, and the decision records `0001`–`0009` — are published as:

> © 2026 Jeff Highman & Alexandra Krížová
> Licensed **CC BY-NC-ND 4.0**

So your name is on them as a co-author and co-licensor.

This was formative rather than deliberate. The framework took its shape in our
conversations, and I was building and publishing as it went — the repository is
where the thinking was happening, not a finished thing I decided to release.
Your name went on because the material is genuinely as much yours as mine, and
putting it there was the accurate thing to do.

What I did not do was ask you, and publishing carries consequences that
formation does not. Those are set out below, because you should be choosing
about them rather than discovering them.

## What that licence actually does

CC BY-NC-ND 4.0 lets anyone copy and redistribute the documents, in any medium,
provided they:

| | |
|---|---|
| **BY** | credit both of us and link to the licence |
| **NC** | do not use it commercially |
| **ND** | do not publish anything they build on top of it |

Quoting for criticism, review or scholarship is allowed regardless — that is
ordinary fair dealing and this licence does not restrict it.

## The part you cannot undo

Creative Commons licences are **irrevocable**. Anyone who has already received
these documents under CC BY-NC-ND keeps that licence permanently. Nothing you
or I decide now takes it back from them.

I want to be precise about what that does and does not mean, because
"irrevocable" sounds more total than it is:

**Cannot be changed** — the licence held by anyone who has already downloaded
or copied the documents.

**Can still be changed** — everything about the future. The documents can be
taken down. Your name can come off. The terms can change for versions published
from here on. Specific passages can be removed.

Realistically, in the days it has been up, the number of people who have taken
a copy is likely very small or zero. That does not make the principle different,
but it does mean the practical exposure is probably slight.

## What is still yours to decide

- Whether your name stays on this work at all.
- Whether these documents stay published, or come down.
- Whether the licence stays CC BY-NC-ND, becomes more restrictive, or more open.
- Whether particular passages that are yours come out.

If you want any of that, tell me and I will do it. You do not need to give a
reason.

## One thing worth knowing separately

`THESIS.md` is a **draft**. Publishing a draft publicly can count as prior
disclosure under some journal and institutional policies. If you have any
intention of publishing this material yourself, that could affect your options,
and it is worth checking before it matters rather than after.

## Not included here

Unpublished source material is kept in a private directory that is excluded from
this repository. It has never been published, is not covered by any licence
here, and is not on GitHub. If you want it deleted, say so.

## What the framework has produced, as of 26 July

Separate from any of the above, and the reason I wanted you to have this now.

The four categories have been put to a test they could have failed, and the
result is a finding about the framework rather than a report on a model.

> Since this was measured, a **fifth** category has been added — `normative`, a
> claim about what ought to be done. The figures below were taken with four, and
> part of what they measure may be two readers improvising around a category
> that did not exist: the essay is full of prescription, and prescription had
> nowhere to go. See [ADR 17](decisions/0017-a-normative-category.md).

Two judges read the same document. The first is the classifier the system runs
on; the second is a different model entirely, reading through an interface built
so it *cannot* see what the first one concluded — that refusal is enforced in
code, not by good intentions, because if the answer is on the screen what gets
measured is anchoring. Both were given your four definitions, verbatim, and
nothing else.

| | |
|---|---|
| agreement on first-person narrative | **48.6%** |
| agreement on argumentative prose | **75.8%** |

The gap is the finding, and the direction of the disagreement is the more
interesting half of it.

On narrative, the second judge moved claims **toward observation** — fifteen of
its eighteen disagreements. On argument it moved them **toward interpretive** —
six of eight. So neither reader is simply the more literal one. They are
disagreeing about *different boundaries* in the two genres:

- In narrative the pressure is between **objective and observation**. Is *"That
  is when Alec replied"* a publicly checkable fact, or a first-person report of
  what was experienced? Both readings follow your definitions exactly.
- In argument the pressure is between **observation and interpretive**. Is a
  general assertion a report of what the writer has seen, or a meaning assigned
  to it?

My reading of this is that **observation is being asked to do two jobs.** It is
defined once, and it sits on a different fault line depending on whether the
text around it is narrating or arguing. That would explain why the same pair of
readers is stable in one genre and not the other, and it is not something either
of us would have got to by argument — it took measuring.

I am not proposing a fix. Whether observation should split, or whether its
boundary should be stated per genre, or whether the right move is to accept that
a category can be genre-sensitive and say so, is yours before it is mine. It
touches the spine of the framework and I would rather it was settled by you.

### What that measurement cannot support

Two models agreeing does not make either right. Nothing in the eleven recorded
measurements compares the system against a *person's* judgement of the same
text, which is the measurement that would let any of the others be read as
correctness rather than consistency. I have built the screen for it and have not
yet typed the forty claims.

The second judge is also not a disinterested party — it wrote much of the
prompt the classifier runs on. That biases toward agreement, which makes the low
narrative figure more striking rather than less, but it is a real limit. And it
chose the argumentative sample itself, having read the text first to confirm it
argued rather than narrated. It never saw the categories; it did see the claims.
A sample picked by one of the judges is not a random sample, and that is recorded
against the figure rather than left out of it.

All of it is in [`BASELINE.md`](BASELINE.md), sections 10 and 11, with the
caveats attached to the figures rather than kept somewhere more comfortable.

## The sentinel-attention sketch — 28 July

You sent the 12×5 cycle with four fixed sentinels, mapped in PyTorch, framed as
a 4G-to-5G transition. Here is what happened to it. We are staying in Rails, so
none of the code went in — and it changed the code anyway, which is the part
worth writing down.

### What we kept

**The arithmetic, which puts a sentinel at layer 38.** I ran the construction
loop. Five cycles of twelve, gated at the thirteenth, capped at 64, and the last
cycle terminating before its own gate. The sentinels land at **12, 25, 38, 51**.

Layer 38 is *our* clamp. `THEORY.md` §6 carries it, and says flatly that a
mathematical clamp at layer 38 is a transformer-internal mechanism and *"the
layer-level clamp is not"* implementable where we work. Your sketch is the first
artefact that puts the clamp where the framework has always said it goes, at the
level the framework says it has to live. Whether that fell out of the arithmetic
or you placed it there, it is the strongest thing in the file.

**The handover distinction, as an open question.** Hard reset is
break-before-make; the learned bias is soft handover, where the handset holds
both links through the transition. That is a more precise analogy than it looks,
and it names something unresolved here: our identity STOP is **binary**. It
hard-blocks governance, and your own Matrix 2.0 Q7.3 argues a Sentinel should
not issue a binary block. Break-before-make drops the call when the target cell
is weak. We have not changed it, and it is now written down as a question rather
than a setting nobody examined.

### What we discarded

**The implementation, and not because of the bugs.** There are bugs — `permute`
is passed tensor *sizes* where it wants dimension indices, and both mask
branches allocate a full `[B, H, T, T]` tensor, about 17 GB at realistic sizes,
to write a single column. Those are twenty minutes of work.

What we discarded is the layer *as a sentinel*. `SentinelAttention5G` is the same
class as the compute layers — same weights, same forward pass, differing by a
boolean argument. It **is** the transformation it governs, which is the one thing
`GovernanceSentinel` raises `NotIndependent` to forbid. And it produces no
verdict, no attribution, nothing that enters the assertion ontology: nothing it
does can be superseded, challenged or appealed, because nothing it does is an
Assertion.

That is not a flaw in your design. It is two different objects sharing a name.
Yours **steers** — it reweights what the model attends to. Ours **records** — it
produces a contestable claim about whether a step was earned. Both are real; they
should not be called the same thing without saying which is meant.

We also dropped the performance claims. A fused QKV projection does not fetch its
weights "in a single memory clock cycle", and a Python `for` loop over a list of
booleans is not a static execution map free of branch mispredictions. Neither
claim is load-bearing for the idea.

### What we learned

**Your bias parameter found a bug in my audit.**

`sentinel_bias` is a fixed additive constant added to one attention logit, and it
competes against however many tokens happen to be present. At T=4096 it puts 84%
of the mass on the sentinel. At T=128, the same parameter puts **99.4%**. The
mechanism is not scale-invariant, so the number means something different at
every sequence length.

That is exactly the error I had already made. `TemporalDriftAudit` flagged an
actor's decisions as drifted when total variation distance between two periods
exceeded a fixed **0.20**. But TV distance between two finite samples is never
zero even when nothing has changed, and how far from zero depends on how many
decisions there were. I simulated it: at **twenty decisions a side — the minimum
the class itself declares sufficient — two samples drawn from an identical
distribution exceed 0.20 about 62% of the time**, with a median of 0.25.

The audit was reporting drift on noise, most of the time, at its own minimum
sample size. It has been recording readings for two days and I had no idea.

It is fixed. The threshold is now the larger of the policy floor and what noise
alone would produce at that sample size:

    E[TV] = ½ · √(2/π) · √(1/n₁ + 1/n₂) · Σᵢ √(pᵢ(1 − pᵢ))

Closed form rather than bootstrapped, so two runs over the same record cannot
disagree about whether a figure was notable. It predicts 0.240 against a
simulated median of 0.250 at n=20, and 0.034 against 0.032 at n=1000. Six specs
now cover it, including the one that matters: **the same divergence, at the same
proportions, is not notable at twenty decisions and is notable at a hundred.**
The one real finding the audit had produced survives the new bar unchanged — its
sample was large enough that the policy floor still governs.

I would not have found that. I wrote the fixed threshold, I wrote the minimum
sample size, and I wrote a comment explaining why twenty was enough. It took
seeing the identical mistake in a completely different medium — attention logits
rather than category counts — to recognise the shape of it.

That is the second time your work has moved this by pointing at a structure
rather than a detail. The first was observing values under conflict instead of
asking for them. This is the same move: the bug is not in the number, it is in
what the number is being compared against.

## Where to look

| | |
|---|---|
| [`COPYRIGHT.md`](../COPYRIGHT.md) | the exact terms, and which files each covers |
| [`docs/THESIS.md`](THESIS.md) | the draft |
| [`docs/THEORY.md`](THEORY.md) | the grounding, and the terminology register |

The terminology register in `THEORY.md` records where the source material
contradicts itself, and marks contested terms `disputed` rather than quietly
resolving them.

**Equitable Baseline Scoring** and the **Average Ceiling Metric** stood that way
for a while: the sources state the containment relation between them in both
directions, so I left it open rather than pick one, and the metric went unbuilt.
Your Matrix 2.0 Q4 settled it — the scoring is the policy, the metric is the
method it invokes — and Q5 answered the harder half by refusing a reference
population outright. Both are now implemented against your resolution.

One judgement call in there is mine and you should know about it. Q5 asks for a
peer group sharing "environmental or parental pauses". I made that group
something the caller supplies, never something the system derives, because
deriving it would mean reading the gaps for a cause — recovering the sensitive
attribute out of exactly the absences the policy forbids reading, inside the
mechanism meant to enforce it. The reasoning is written up in
[ADR 15](decisions/0015-the-peer-group-is-supplied.md). Where a defensible peer
group *should* come from is still open, and I have not pretended otherwise.

— Jeff
