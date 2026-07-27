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
