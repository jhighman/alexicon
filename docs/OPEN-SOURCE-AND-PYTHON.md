# Python, Open Source, and What It Does to the Paper

**Decision brief, 31 July 2026.** Not an ADR — nothing is decided here. Companion
to [`BUILD-PLAN.md`](BUILD-PLAN.md), which recommended staying on Rails, and
which this brief partly revises.

The question: the reference implementation is Ruby on Rails and works. Python has
a far larger community. If this goes open source, what should it be written in,
and what does that do to the dissertation's argument?

---

## 1. The measurement that changes the answer

The instinct is to compare "Rails app" against "Python app" and weigh 11,245
lines of working Ruby against a rewrite. That is the wrong comparison, because
the paper does not rest on 11,245 lines.

| | Lines | What depends on it |
|---|---|---|
| **The kernel** — assertion, claim, relationship, transition, case, referent, mention, framework, promotion weights, the sentinels, the classifier, the segmenter, blind reading, the baseline | **2,544** | **Every measured claim in the dissertation** |
| Everything else — controllers, GraphQL, views, admin, JS, policies, mailers | ~8,700 | Nothing the paper claims |

Every figure in the baselines, every invariant the dissertation argues for, and
the whole of Chapter 9 sit inside that 2,544 lines. The web application around it
is real work and is irrelevant to the argument.

**So the choice is not "port the app or don't." It is "should the kernel exist in
a second language."** That is a few weeks of work, not a migration.

---

## 2. Replication is not replacement, and the difference is the whole answer

`BUILD-PLAN.md` §1.1 argued against a rewrite because the code revision is a
recorded condition of every measurement, and changing the instrument makes every
prior figure incomparable. That argument is correct and it only applies to
**replacement**.

A second implementation that runs the same controls alongside the first is not a
changed instrument. It is a **second instrument**, and comparing two instruments
is a measurement this project already knows how to record — it does exactly this
for two judges, and refuses to tally them into one figure.

The distinction:

| | Replacement | Replication |
|---|---|---|
| Rails | retired | kept, remains system of record |
| Prior baselines | incomparable | untouched |
| Python's role | the system | a second instrument |
| If the two disagree | you have lost your history | **you have found something** |
| Cost | months | weeks, for the kernel |

If the two implementations return the same figures on the same controls, the
figures are properties of the question rather than of the instrument. If they do
not, one of them has a bug, and finding that out before publication is worth more
than either number was.

---

## 3. How the paper is rationalised — it gets stronger, and in the place it is weakest

### 3.1 The headline finding is negative, and negative findings attract one rebuttal

The dissertation's principal empirical result is that four designs across two
scopes could not distinguish a real argumentative step from an unrelated pair,
and that the widest scope returned **0.00 standard errors**.

There is exactly one cheap way to dismiss that result: *your implementation was
wrong.* A judge that finds conflict at 85.7% in both arms is, on its face, as
consistent with a broken control as with an ungrounded question. Nothing inside a
single implementation can separate those two readings.

A second implementation, written in another language against another data layer,
reproducing 0.00 standard errors, closes that off. It is the single highest-value
thing available for the credibility of the finding the dissertation leads with.

### 3.2 It restores the kind of independence Chapter 10 lost

§10.1 currently concedes that the instrument is not independent of the framework's
authors, and falls back on a narrower claim: pre-registration, and a control that
could fail and did.

That concession is honest and it is a weakened position. Implementation
independence is a different axis and it is recoverable — two implementations
agreeing is evidence no amount of authorial separation would give, and the
project already treats convergence from two directions as its strongest available
evidence ([ADR 3](decisions/0003-anti-discrimination-is-a-policy-not-a-domain.md),
[ADR 11](decisions/0011-the-lock-guards-predication.md)).

### 3.3 The framework's own epistemology asks for this

Chapter 6 lists, among the systems that share the Sentinel pattern, that
"scientific communities require independent replication before observations
become accepted knowledge." A dissertation that says so and then reports eleven
figures from a single unreplicated instrument is not wrong, but it is applying to
itself a weaker standard than the one it names.

### 3.4 Chapter 9 predicts that the language cannot matter

This is the part worth being precise about, because it cuts both ways.

Chapter 9's central move is that the requirement — judgment operates over
completed causal structures — **does not name the layer**. A transformer meets it
in representation; an evaluation system meets it in evaluation order. If that is
right, then nothing about the evaluation-order implementation's *language* can
bear on the thesis. Ruby is not load-bearing. Neither is Python.

So a port cannot strengthen the *thesis*. What it strengthens is the *evidence*.
And the reverse also holds, which is the risk worth naming: if the two
implementations disagree on the controls, the disagreement is not a language
finding. It is a bug in one of them, and the paper cannot report it as anything
more interesting than that.

### 3.5 What changes in the text

| Location | Change |
|---|---|
| §10.1 | Add implementation independence to what survives; the fallback stops being the only argument |
| §10.2 | "It can establish" gains: whether a figure is a property of the question or of the instrument |
| §10.3 | A fifth measurement commitment: figures from two implementations are reported side by side, never merged — the same rule already applied to two judges |
| §11.4 | The 0.00 result carries a second implementation's figure beside it |
| Ch. 13 | The limits section drops "one instrument" if replication lands |
| Appendix C | Conditions gain an `implementation` field |

---

## 4. The stack comparison, honestly

### 4.1 Where Python is genuinely better

**The audience.** The readership for a dissertation in information science and AI
governance reads and writes Python. A reviewer who wants to check a claim, a
research group that wants to replicate, a graduate student who wants to extend —
all of them can run Python and most cannot run a Rails app. For a research
artifact, *the language of the audience* is a stronger consideration than the
language of the author.

**The invariants can move into the type system.** This is the substantive
technical argument and it is not about community at all. `BUILD-PLAN.md` §1.2
rejected a typed rewrite while conceding the argument was real: "closure is the
constructor" wants a type that cannot be constructed without a right boundary,
and Ruby enforces it in a class method. Python with Pydantic v2 and `mypy
--strict` gets much of that — a `ClosedCase` that is unconstructible without its
boundary, an `Assertion` frozen at construction, a `GroundedMention` distinct in
type from an ungrounded one. Invariants checked by the type checker rather than
by discipline.

**`hypothesis`.** The best property-based testing library in any ecosystem, and
`BUILD-PLAN.md` §3.4 asks for exactly property-based tests over the six
invariants. This is a direct fit.

**The representation track is Python anyway.** Phase 3 of the build plan is
PyTorch. A Python kernel means one language across both halves of Chapter 9,
which matters more than it sounds — the two tracks would share the controls, the
decoy construction, and the statistics rather than reimplementing them.

**Contribution.** An outside pull request to a Python research repository is
plausible. To a Rails one, in this domain, it is close to hypothetical.

### 4.2 Where Rails is genuinely better, and it is not nothing

Rails 8 gives, out of the box and already configured here: background jobs
without a second datastore, caching, a deployment story, an auth model, GraphQL,
and 57 spec files of accumulated behaviour. The Python equivalent is FastAPI +
SQLAlchemy + Alembic + Pydantic + a job runner + assembling deployment — more
decisions, more surface, more to keep current.

For the *application* — the thing people log into and read documents in — Rails
is the better tool and there is no reason to move it.

### 4.3 The recommendation this produces

Not a migration. A **split by purpose**:

| | Language | Role |
|---|---|---|
| **Kernel** — the invariants, the controls, the measurement | **Python** | The open-source artifact. What the paper cites. What others replicate. |
| **Application** — reading UI, review workflow, delegation, GraphQL, deployment | **Ruby on Rails** | Stays. System of record. Not published, or published later. |

The kernel is the part the paper rests on, it is 2,544 lines, it is the part an
outside researcher would want to run, and it is the part that has no business
depending on a web framework at all. Extracting it is good architecture
independent of any language question — a kernel that cannot be run without
booting Rails is a kernel with a dependency it does not need.

---

## 5. Licensing — the part that will bite

Going open source is not just a repository setting, and the current terms are not
ready for it.

**The code has no licence at all.** `COPYRIGHT.md` says all rights reserved and
that the absence of a `LICENSE` file is deliberate. Publishing a repository
without a licence grants nobody the right to use it; a research artifact nobody
may legally run is not open source. **Recommendation: Apache-2.0** rather than
MIT — the express patent grant matters given the surrounding work, and it is the
default expectation for a governance-adjacent research artifact.

**The docs are CC BY-NC-ND, and ND is the problem.** NoDerivatives means nobody
may publish a modified version — no translations, no corrections, no adaptation.
NonCommercial additionally excludes most industrial research labs. Both are
reasonable protections for a manuscript and both are incompatible with an
open-source project's documentation. **Recommendation: CC BY 4.0 for the
documentation that describes the framework**, keeping NC-ND on the dissertation
manuscript itself if that is wanted — they are different artifacts and can carry
different terms.

**Two constraints on how this is done:**

- The CC BY-NC-ND grant already made is **irrevocable**. A more permissive
  licence can be added; the existing one cannot be withdrawn. Adding is fine and
  is the normal path.
- The documentation is co-authored, and relicensing needs Alexandra's agreement
  — a fresh one. She agreed to CC BY-NC-ND on 25 July, and the note in
  `FOR-ALEXANDRA.md` already owes her a second conversation about the widened
  architecture attribution. Licence changes belong in the same conversation.

**One asymmetry worth stating plainly:** open-sourcing the kernel makes the
dissertation's negative result *more* falsifiable by strangers. That is the
point, and it should be a deliberate choice rather than a side effect.

---

## 6. What this costs, and the order

| Step | Effort | Gate |
|---|---|---|
| Extract the kernel's boundary in Ruby — make it runnable without booting Rails | ~1 week | none; good regardless |
| Port the kernel to Python — typed domain, invariants in the type system | 3–4 weeks | none |
| Property tests over the six invariants, both implementations | ~1 week | after port |
| Re-run the case-scoped control and the three pair-scoped ones on the Python kernel | ~1 week | after port |
| Compare, side by side, never merged | days | **the gate** |
| Licence rework + Alexandra's agreement | conversation | before any publication |
| Publish | — | after the gate and the licence |

**The gate.** If the two implementations agree within noise, publish both, cite
the replication in §10 and §11, and the negative result becomes very hard to
dismiss. If they disagree, do not publish either number until it is understood —
and be glad it surfaced before a reviewer found it.

---

## 7. What would make me wrong

- **If the kernel does not extract cleanly.** If the 2,544 lines turn out to be
  entangled with ActiveRecord in ways that make the port a reimplementation
  rather than a translation, the cost estimate is wrong and the replication is
  no longer independent in the way that matters — it becomes a rewrite that
  inherits the original's assumptions.
- **If a solo maintainer cannot carry two implementations.** Two codebases is
  two of everything. The mitigation is that the Python kernel is a research
  artifact with a slow release cadence, not a second production system — but if
  it starts accreting features, the split has failed.
- **If the replication is treated as authoritative rather than as a second
  reading.** Two instruments agreeing is evidence; two instruments merged into
  one figure is the exact defect this project already caught in itself when two
  judges' readings were being tallied into a single majority. The same rule
  applies here and will be tempting to break.
