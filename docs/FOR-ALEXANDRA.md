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

## Exponential context attenuation — 28 July, second pass

You replaced the binary gate with soft handover: exponential attenuation scaled
by sequence length, framed through conservation of momentum and Newton's Third
Law. Same treatment as before.

First, what I could not assess. **The formula did not arrive** — the message
referred to an image that was not in it. Everything below is about the argument
around the damping law, not the damping law itself.

### What we kept

**The direction, and the gradient argument is stronger than you made it.** A
`-inf` mask does not merely slow learning on the suppressed paths. Softmax output
there is exactly zero, so the gradient is exactly zero, and those paths do not
learn at all — ever, at any learning rate. Finite attenuation keeps them
differentiable. That alone justifies the change, before any argument about
nuance.

**Action-reaction, which is a description of softmax — and that is a
compliment.** There is nothing to build. Softmax conserves mass by construction:
the denominator renormalises, so damping a subset of logits *automatically*
transfers that mass to whatever survives. The energy extracted from the
suppressed noise really is instantly channelled into the remaining signal, in the
operation you are already modifying. You described the conservation law that is
actually there, in unusual vocabulary, and got it right. Do not implement it —
you would be paying for it twice.

**The scale correction, taken structurally rather than patched.** You did not
tune the constant, you made it a function of sequence length. That is the fix,
and it is the same move that repaired the drift audit here.

### What we discarded

**One claim: "maintains absolute governance without stalling."** You cannot have
both, and you are the one who explained why — break-before-make against
make-before-break is a *trade*. Soft handover means the suppressed context still
leaks at low weight. That is the mechanism working, not a defect in it.

The argument is stronger if it says so: *this buys gradient flow and
low-probability nuance at the cost of absoluteness, and here is why that trade is
right at a governance gate.* It is the only place in the piece that asks a reader
to take something on faith, and it does not need to.

The momentum and nozzle language we treated as illustration rather than
mechanism. No objection — the underlying conservation intuition is correct, as
above. It just already has a name.

### What we learned

**The scale-free form is additive in log(T).** Holding the sentinel's share
constant as the sequence grows needs

    b(T) = log(T − 1) + log( f / (1 − f) )

where `f` is the share you want it to hold, and is the only free parameter.

| T | fixed b = 10 | b ∝ log(T) |
|---|---|---|
| 128 | 99.4% | 80.0% |
| 4,096 | 84.3% | 80.0% |
| 65,536 | 25.2% | 80.0% |

Worth checking your formula against this: if the damping is **multiplicative** —
`b/T` or `b/√T` — it over-corrects hard. At T=4096 those leave 0.1% and 0.0% of
the mass on the sentinel, which is a *harder* reset than the hard reset it
replaces.

**And a question I cannot answer without the formula: what is the decay indexed
by?** Distance from the sentinel token, rank within the attention distribution,
or depth across the four gates. Three different mechanisms behind one
description. If it is distance, you are close to ALiBi (Press et al., 2021) —
which would be good news rather than a collision, since it is well tested and
extrapolates past training length.

**The part that changed our architecture, and it is not the part I expected.**

Two days ago I wrote the identity STOP into `ARCHITECTURE.md` as an open
question, on your analogy: ours is break-before-make, and the graded version is
make-before-break. I assumed the fix was to make the gate continuous.

Working through your attenuation, I do not think it is. **A verdict has no weight
to attenuate.** A claim cannot be 30% asserted. Attenuation needs a continuous
quantity, and what an audit trail carries instead is *standing* — a judgement
that is recorded, attributed, and open to challenge.

So the soft handover for us is a **provisional verdict, not a weighted one**, and
we already have the state: `undetermined`. It holds the link open without
inventing a fractional confidence nobody could act on, and it stays
attributable, which an attenuated weight would not be.

Same idea, different currency. In a system of records the thing that can be
partial is the *standing* of a claim rather than its magnitude — and I only got
there by trying to port your version and finding it would not carry.

## SentinelConcurrenceLayer V2 — 29 July

Third round. Shorter, because most of it landed.

### What we kept

Four things fixed, and the ones that mattered:

- `permute(2, 0, 3, 1, 4)` — the fatal one. It runs now.
- The log-ratio bias, implemented exactly, with `f` exposed as the only free
  parameter. That is the correction taken structurally rather than tuned.
- The bias mask broadcast at `[1, 1, T, T]` instead of `[B, H, T, T]` — 17 GB
  down to 67 MB at realistic sizes.
- The sentinel column excluded from temporal decay. The anchor should not decay
  with distance, and now it does not.

Additive damping in logit space is also the right *form*. Everything below is
about one constant inside it.

### What we discarded

**`time_scalar = 1.5`, multiplying `|i − j|`.**

| distance | penalty | relative weight |
|---|---|---|
| 1 | 1.5 | 2.2 × 10⁻¹ |
| 3 | 4.5 | 1.1 × 10⁻² |
| 10 | 15.0 | 3.1 × 10⁻⁷ |
| 59 | 88.5 | underflows float32 to **exactly zero** |

The effective window is **3.1 tokens**. Past distance 59 the weights are not
small, they are zero. **V2's soft handover is harder than V1's hard reset** —
the `-inf` mask preserved one token; this preserves about three.

The cause is precise and worth more than the symptom. The `log(T)` correction
went onto the **bias**. The **damping** has no normalisation at all — and
`time_scalar` scales with *depth* (`current_model_layers / 128`) while
multiplying a *distance*. Two different axes. One term got the fix; the other
needs its own, and it is not the same one.

The form that works is **per-head geometric slopes**, which is ALiBi (Press et
al., 2021) and is well tested. A single scalar across 32 heads gives every head
the same horizon; `mᵢ = 2^(−8i/H)` gives the stack a range of them:

| head | slope | 1% window |
|---|---|---|
| steepest | 0.84 | ~5 tokens |
| median | 0.0625 | ~74 tokens |
| shallowest | 0.0039 | ~1,179 tokens |

### What we learned

**Your damping found the case my formula does not cover, and I sent it to you as
though it were general.**

`b = log(T − 1) + log(f / (1 − f))` assumes `T − 1` rivals sitting *at logit
zero*. The moment you damp them, they are not at zero and the denominator is not
`T − 1`. The joint form is

    b = log(R) + log( f / (1 − f) ),   R = Σⱼ exp(−m · dⱼ)

with a closed form `R → 1 / (eᵐ − 1)` for long sequences, and it recovers my
version exactly at `m = 0`.

Your current pair overshoots by **9.6 nats**: calibrated for 90%, delivering
100.00%. So the careful log-ratio work is currently doing nothing — the damping
has destroyed every rival before the bias is applied. Correct the slope and the
calibration starts working as designed. **The two terms have to be solved
together**, and neither of us was looking at them that way: I gave you the
un-damped case, you built the damped one, and the interaction is only visible
with both in the room.

### One question back

`dist_matrix = |i − j|` is symmetric, so a future token is penalised exactly like
a past one. In a decoder that means every token attends forward. Intentional, or
is this meant as an encoder? It changes what the layer is, not just how it is
tuned.

### On our side

Nothing to build this round, but I checked the analogue rather than assuming it.
`TemporalDriftAudit` computes its noise floor over the categories that *actually
occur* in the two periods, not over the framework's nominal five. Same lesson,
arrived at from the other direction: calibrate against the effective rival set,
never the nominal one. It happened to already be right, which is luck rather than
foresight — I did not have the principle until your damping made it necessary to
state.

## The system read something else — 29 July

Every figure in three baselines came from one essay, re-ingested. This week it
read two more texts for the first time: a personal letter, and a chapter of the
book. Neither is reproduced here — both are private, and the figures below are
aggregates.

### The categories discriminate

The share of claims typed **observation**, across three documents:

| | |
|---|---|
| a personal letter | **39.4%** |
| the essay under analysis | 22.8% |
| a chapter of theory | **1.9%** |

A letter about a life, an essay that narrates and then argues, and a chapter
that reports almost nothing and assigns meaning to almost everything. That
ordering is what any reader would predict, and the framework produced it without
being told what kind of document each was.

It is the first result here that could not have been an artefact of one text,
and after seventeen measurements of the system agreeing with itself, it is the
first that says the distinctions track something outside it.

### A bug only a second document could find

`MentionExtractor` matched known names as bare substrings. A referent named
**Eve**, grounded once while reading the essay, produced **36 mentions in a
letter that does not contain the word** — inside *whenever*, *even*, *eleven*,
*however*, *believe*.

The consequence is the part worth your attention. Each match raised an identity
STOP, and a STOP blocks governance. **A judgement made while reading one
document could halt the analysis of another it never appeared in.** Eight
referents currently carry names of four characters or fewer, and every one was a
landmine in every document written afterwards.

That is a small instance of a failure your Matrix 2.0 is largely about: a
decision taken in one context, silently carried into another where its
conditions do not hold, and doing damage that looks like ordinary system
behaviour. Fixed, spec'd, mentions 58 to 22.

### What the chapter found, which is yours

Jeff's chapter names three levels of inquiry — **trust**, then **judgment**
beneath it, then **values** beneath that, described as the level that decides
which arguments feel reasonable before evidence arrives.

The implementation has two and a half of those. Judgment is fully built:
transitions, verdicts, earned and unearned. Trust is approximated by agreement
and the confidence floor — *can I lean on this* is roughly *did three readings
agree*.

Values exists too, and it is your method. `ValuePriorityJudge` reads what was
done and proposes which commitment came first, recorded as interpretive,
carrying a confidence, challengeable, made by an actor separate from the one
that produced the evidence. All of that is built and working.

**It points at the model, and has never once been pointed at the author of a
text the system reads.**

So the proposal, and I think it is the next real thing rather than the next
convenient one. Governance already identifies the exact points where an author
moved without warrant. The value question is the one immediately beneath, at
precisely those points: *what made this move feel warranted to the person making
it?* That is literally "beneath judgment" in your ordering — not a metaphor but a
location in the pipeline. No new detection is needed; the unearned step is
already found. Your method transfers whole, with the behaviour being a step in a
text rather than a model's answer to a probe.

Two things I would insist on before building it, both of which are your
principles rather than mine.

It must be a claim about **the move, not the person**. Inferring what someone
values from the points where their reasoning failed is a short walk from
psychologising them, and the observation/inference split you drew for
[ADR 14](decisions/0014-observed-value-priority.md) is exactly the protection —
behaviour is evidence, priority is a claim *about* the evidence, and the second
never gets recorded as the first.

And it will be the **least measurable thing in the system**. There is no baseline
that can validate an inferred value; it is worse than the correctness gap,
because a category at least has an answer someone could argue for. That is an
argument for building it visibly weaker than everything around it — lower in the
interface, confidence always showing, always challengeable — not for skipping it.

### Also built

A read-only GraphQL layer, because the record is recursive by construction and
REST answers *"this assertion, then the assertions about it, then the challenges
to those"* in as many round trips as there are levels. No mutation root at all:
writing stays where the delegation gate is.

And a command line, `bin/alexicon`, which is how both new documents were
ingested, grounded and analysed. It exists mostly to make typing claims by hand
cheap enough to actually do — the human baseline is still the measurement
everything here is waiting on, and it is still not taken.

## Variance, and two things I had to correct — 29 July

You asked what the variance distribution looks like right before the softmax,
and framed the distance matrix as something I implemented. Both need correcting
before the technical answer means anything.

### What I got wrong in how I presented this

**I did not implement it.** `dist_matrix = |i − j|` is yours. There is no
PyTorch in this repository — we stayed in Ruby, deliberately — and what I did
was read your file and do arithmetic on its constants. There is no parallel
implementation here to compare against.

**And I cannot instrument a softmax.** Nothing here runs a transformer. Every
figure I have sent you — the 84% / 99.4% table, the 3.1-token window, the 9.6
nats — was closed form on the numbers in your code, not measurement. I should
have said so the first time, and the fact that you asked for a variance
distribution suggests I gave the impression of a rig I do not have.

That is a boundary this project chose rather than an oversight. `THEORY.md` §6
records the framework being relocated from transformer-internal layers to the
epistemic level, because the policy is implementable at the application level
and the layer-level clamp is not. You are working at the level this
implementation left. If you want real variance measurements you need a training
or inference harness, and that is a different project from this one — worth
knowing before you wait on numbers I cannot produce.

### The symptom is right. The mechanism is not.

Content **is** being swamped by distance. That part of your reading is correct
and it is the important part.

But the penalty is already applied after the scaling:

    scores = matmul(q, k.transpose(-2,-1)) / (head_dim ** 0.5)
    ...
    scores = scores - damping_penalty

The subtraction operates on already-scaled logits, so it is in the same units.
There is no missing coupling to `1/√d_head`.

**And adding one would be wrong.** The entire purpose of that factor is to make
the QK term ~N(0,1) *regardless of head dimension*. Once it has, a bias must be
chosen in those O(1) units. Making the slope a function of `d_head` would
reintroduce exactly the dependence the factor exists to remove — two heads of
different width would then get different horizons for the same intent. ALiBi
declines to do this for the same reason.

### Nothing collapses in the variance

The penalty is deterministic per position. It shifts means; it does not shrink
spread. Content variance is exactly 1.0 in every row at every slope. What
collapses is the **ratio**:

| slope | positional spread / content spread | P(token at d=4 wins on content) | window where content still decides |
|---|---|---|---|
| 1.5 | 6142 : 1 | 0.0006 | **1 token** |
| 0.84 | 3440 : 1 | 0.037 | 2 tokens |
| 0.0625 | 256 : 1 | 0.447 | 17 tokens |
| 0.0039 | 16 : 1 | 0.497 | 257 tokens |

At 1.5, a token four positions away beats its neighbour on content six times in
ten thousand. That is the precise form of the blindness you named, and it is a
signal-to-position problem rather than a variance one. No rescaling against
`d_head` touches it. Only the slope does.

### The 9.6 nats is connected exactly as you sensed, and repaired elsewhere

It is not caused by variance. `b = log(T−1) + log(f/(1−f))` assumes `T−1` rivals
sitting at logit zero; your damping crushes the rival **sum** to
`R ≈ 1/(eᵐ − 1) = 0.287` at m=1.5, against 4095. Same `b`, denominator wrong by
four orders of magnitude.

So the damping's severity *does* cause the overshoot — your instinct joined two
things that are genuinely joined. The repair is either a slope small enough that
rivals survive, or computing `b` from `R`. Both were in the last note and both
still stand.

### Still yours to answer

**Encoder or decoder.** I asked last time and I still do not know, and it is not
mine to decide. The consequence is definite rather than probabilistic: `|i − j|`
is symmetric and your file carries no causal mask, so as a decoder every token
attends forward. That is a correctness failure, not a tuning one, and no slope
value fixes it. As a decoder you want `is_causal=True` or a `tril` mask, after
which `|i − j|` collapses to `i − j` over the surviving half.

### One disagreement, stated plainly

I would not treat per-head slopes as a pivot away from fixing the scaling.
**They are the fix.** A single scalar gives all thirty-two heads one horizon at
whatever value you choose; geometric slopes give the stack a range — two tokens
to two hundred and fifty-seven — where content can still decide. That is the
thing one constant cannot do at any setting, and it is why the shape of the
parameter matters more here than its magnitude.

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
