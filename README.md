# Alexicon

An epistemic governance system. It does not decide whether claims are true. It
decides what *kind* of claim each one is, and whether a move from one kind to
the next has been earned.

> **Trust is the discipline of preventing inference from becoming evidence.**

The recursive question the system exists to answer:

> *What kind of statement is this, and has it earned the right to become the
> next kind of statement?*

## Documentation

| Document | What it covers |
|---|---|
| [`docs/REPRODUCIBILITY-REQUIREMENT.md`](docs/REPRODUCIBILITY-REQUIREMENT.md) | Which uses actually need high reproducibility, and which do not |
| [`docs/ATAM-interpretive-ontological.md`](docs/ATAM-interpretive-ontological.md) | Architecture tradeoff analysis of the framework's central boundary |
| [`docs/BASELINE.md`](docs/BASELINE.md) | What the system has measured about the model it runs on, and what those figures cannot tell you — **generated** from the recorded measurements, never hand-written |
| [`docs/BASELINE-v2.md`](docs/BASELINE-v2.md) | The same, re-measured after the segmentation changed. Not a revision of v1: the sample differs by construction |
| [`docs/FOR-ALEXANDRA.md`](docs/FOR-ALEXANDRA.md) | A note to the co-author about how this came to be published |
| [`docs/LEXICON.md`](docs/LEXICON.md) | Every term the system uses, generated from its own data — with the words that carry more than one meaning named rather than tidied away |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | How it is built — pipeline, record model, where the locks bite, diagrams |
| [`docs/THESIS.md`](docs/THESIS.md) | The Sentinel Principle — ontology, the Assertion Principle, the Binding Problem |
| [`docs/CONOPS.md`](docs/CONOPS.md) | Concept of operations: scenarios, functional requirements, non-goals |
| [`docs/THEORY.md`](docs/THEORY.md) | Psychoanalytic and epistemological grounding; terminology register |
| [`docs/mindmap.html`](docs/mindmap.html) | Alexicon 2.0 concept map — seven domains |
| [`docs/decisions/`](docs/decisions/) | Architecture decision records |

## What is built

**Identity Sentinel and referent resolution** — the input boundary. A name
arriving without established reference is *Entity Noise*, and nothing may be
predicated of it until it resolves.

The resolver is deterministic rather than model-backed: its purpose is to
refuse to guess, and a probabilistic resolver would reintroduce the guess it
exists to prevent. Three non-resolving outcomes, matching the framework's three
detection criteria:

| Outcome | Trigger |
|---|---|
| `ambiguous` | Attention-map dispersion — several candidates, or a surface form with non-entity senses |
| `out_of_distribution` | No match in memory |
| `unanchored` | Cognitive Passport (`Name → Subject → Role`) could not be assigned |

On any of these the Sentinel escalates to a person, and the lock is enforced
rather than advisory. What it locks is **predication** — judging that a step
between claims was earned — not description. Classifying asks what *kind* of
statement something is, and that does not depend on who a name inside it refers
to: "Polanyi said we can know more than we can tell" is an objective claim
whichever Polanyi it is.

That distinction is load-bearing rather than academic. Gating classification on
resolution meant one essay citing unfamiliar authors produced 204 blocking
questions and could not be read at all — and names like "God" would never
resolve, because that is a contested ontological question, not missing data.

One entity may go by several names. A misspelling, a surname alone, a fuller
form — "Polayani", "Polanyi" and "Michael Polanyi" are one philosopher, and
grounding them separately would break object constancy over a transposed
letter. Declaring a name to be another spelling records an **alias** against
the existing referent; the document's text is never corrected, because the
misspelling is evidence that it was there. The Identity Proposer suggests these
links too, and on a real essay it found both that existed.

Identity accumulates in the graph, not in the document. Writing does not
introduce the people it names, and requiring it to would require prose to be
self-contained in a way it never is. So a name is asked about **once**, however
often it appears and in whichever document, and the answer applies wherever the
name occurs. Disposing of the flag lifts it; what is not possible is reasoning
past it silently.

**Markdown is understood at ingest.** Headings, tables, fenced code and rules
are kept as structure rather than offered as claims, so a table of definitions
is never asked what kind of assertion it is and no reasoning step is drawn from
one of its rows. Plain prose still works; a narrow heuristic covers headings
where no markup exists.

**Framework as data.** Domains, claim categories, and flow stages are seeded
rows scoped to a framework version, not constants. A terminology register
tracks names that have drifted, and records contested ones as `disputed`
rather than silently resolving them.

**Model registry** — a model may not influence any judgement until an admin
certifies it. Every call is recorded: model, tokens, cost, latency, outcome,
linked to the judgements it produced.

**Where the model is asked, and what it is asked for.** The extractor is a
regex, so it cannot tell "Michael Polanyi" from "Fortunately" — that difference
is world knowledge. That gap used to be filled by a person, one form at a time,
while the model was busy sorting single sentences into four buckets and
returning 1.0 confidence on all of them. The hard work was going to the human
and the easy work to the model.

So the Identity Proposer reads a whole document and proposes what each
unfamiliar name refers to — or that it is not a name at all, or that it cannot
tell. It sits behind the same fence as the classifier: it *proposes*, its
output is an attributable inference, it may abstain, and it is deliberately not
the Identity Sentinel that would accept it. **Nothing it says lifts a STOP.** A
person accepts or corrects, and that acceptance is recorded under their name.

Classification is batched with surrounding context for the same reason. One
sentence per call threw away the argument it sat in — which is why confidence
was uniformly 1.0 and the abstention floor was decorative.

Providers, models and routing are administered in the browser. Anthropic,
OpenAI and Gemini each have an adapter; the classifier speaks only the adapter
interface, so which vendor answers is a governed decision rather than a fact
about the code.

Two things a provider needs before it can be used, and the registry keeps them
apart: an **adapter**, so the code can call it, and a **credential**. A provider
without an adapter may still be registered — it just cannot be certified,
because vouching for a model this application cannot reach would claim a
capability that does not exist.

A credential can be set in the browser or exported into the environment. Either
way it stays out of the audit trail: assertions and invocations record who
judged, on which model, at what cost — never the key.

**A third level, beneath judgement, that does not yet work.** Where a step is
judged unearned, `StepValueJudge` proposes what that **step** put first and what
it set aside — a claim about the move, enforced by the shape of the record
rather than the prompt, since the assertion's subject is the `Transition` and a
Referent cannot be named as one.

Its vocabulary is framework data
([`FrameworkValue`](app/models/framework_value.rb), sixteen values under the
Motivation domain, with provenance marking which were already in the record and
which are proposed). Swap the framework and the vocabulary swaps with it — a
second framework carrying Rand's cardinal values and virtues reads the same
steps and reaches for different things.

But two controls say it does not currently distinguish signal from noise.
Presented with claim pairs from unrelated parts of a document it reads them
almost as often as real steps: a gap of **0.29 standard errors**. So its output
is shown as prompts for a person, never as findings, and its confidence is not
used as a filter because it carries no information. Recorded in
[`BASELINE-v3.md`](docs/BASELINE-v3.md).

**Blind typing — the only measurement that is not the system checking itself.**
A person, or a second model through the API, types the same claims without
seeing what the classifier concluded. The blindness is enforced in the object
rather than the template: asking what the machine said, about a claim the reader
has not answered, raises. So far: 48.6% agreement on first-person narrative,
75.8% on argumentative prose, against a classifier that reproduces *itself*
87.9% of the time.

**The anti-discrimination policy is a constraint rather than a statement.** It
is cross-cutting — binding Identity, Reflection and Governance without being an
eighth domain — and `GapInvariance` states the one claim it makes as a property
a scorer either has or does not: *two records identical in what they establish
score the same, however they are spaced in time.* `PolicyAudit` records the check
as an assertion, pass **or** fail. `AverageCeilingMetric` is the measure the
policy applies, averaged over a record's own active windows and never over a
population, with the peer group supplied rather than derived
([ADR 15](docs/decisions/0015-the-peer-group-is-supplied.md)).

**Review surface** — paste a text, see its claims and their categories, and answer
the flags waiting on a person. Flags are never presented as claims of falsehood:
they state that the conditions for proceeding were not satisfied, and a reviewer
may let one stand or set it aside.

Authorisation and provenance are separate concerns. A **User** carries the
credential and the role; its **Referent** carries the authorship. Every
judgement is attributed to the Referent, so credentials never appear in the
audit trail.

| Role | May |
|---|---|
| `viewer` | read documents, claims and flags |
| `reviewer` | + submit texts, run analyses, answer flags, ground names |
| `auditor` | read + the model registry and every invocation |
| `admin` | everything, including certifying and revoking models |

## Driving it programmatically

Every act a person can perform has a REST endpoint, and `bin/alexicon` and any
agent use the same one. A token belongs to a **Referent**, not to a user session, so
whatever calls the API attributes its judgements to itself — an agent can never
leave a record saying a person decided.

```sh
bin/rails "alexicon:token[avery,laptop]"                  # a person's token
bin/rails "alexicon:agent[review-agent,Review Agent]"      # an agent, and its token
```

Two gates, and both must pass. The **policy** is the same Pundit policy the
browser uses — there is no second authorisation path. The **delegation** applies
to judgements only: a person's token passes it by being the person the gate was
asking for; an agent's needs a standing decision, granted per act by a named
person, that this class of judgement may be made with nobody present.

Nothing is delegated by default, so a fresh agent may read every question and
answer none of them:

```
POST /api/v1/mentions/12/ground
{ "error": "not_delegated",
  "detail": "Review Agent may not ground mention without a person.",
  "act": "ground_mention", "acting_as": "review-agent" }
```

That is the difference between delegating judgement and bypassing it. The person
does not stop deciding; they decide once, about a class of judgement, instead of
repeatedly about instances.

`Delegation` applies **TEI inversion**: the wider the pattern and the heavier the
act, the more a delegation must carry to exist at all — a rationale, then an
expiry, then a bounded one. A delegation granted by an agent is invalid however
wide its role. And `TemporalDriftAudit` watches what happens *after* the grant,
comparing an actor's recent decisions against its own earlier ones, since a
covert policy arrives as a slow shift across many defensible commands rather than
as one suspicious one.

### Reviewing what it concluded

```sh
bin/alexicon review 30      # y let it stand · n set it aside · s skip · q stop
```

The counterpart to `type`, and deliberately a different command. There the
answer is withheld, because the point is an independent reading. Here it is
shown, because the point is correction — so **nothing recorded through this can
measure whether the system was right.** An informed reader agreeing with it is
not evidence.

It **never serves a claim classification**, however unsettled. If it did, a
reviewer would see the machine's category for the same claims the blind surface
needs them naïve for, and the only measurement here that is not the system
checking itself would stop being worth taking. Claims are typed blind or not at
all; judgements are reviewed here.

Weakest first: value readings before step verdicts, because three controls say
that layer cannot tell a real step from an unrelated pair, and a person's
disposal is the only filter that works. Each one carries that warning where the
reviewer will read it.

Accepting an unearned step does not overrule the Sentinel. The flag stays, the
verdict is undisturbed, and a named person is on the record saying it may stand
anyway — which is a different thing from saying it was earned.

### Profiles

An end-to-end report on a document's epistemic structure, from the recorded
assertions.

```sh
bin/alexicon profile 30                          # epistemic-structure (default)
bin/alexicon profile 30 --template=brief         # or: governance
```

Two rules shape it. **The subject is the document, not its author** — every
section describes how a text is built, and nothing attributes a belief, a value
or a tendency to a person, because the system holds no evidence that would
support one. `StepValueJudge` makes the subject of a value reading structurally
a `Transition` so that "this author values X" cannot be written; a report that
reintroduced it at the presentation layer would undo that where nobody was
looking.

And **every section cites what it rests on, or does not render.** A template may
only name sections that have a source; ask for one that does not and the render
fails loudly rather than filling the gap with prose. Adding a section means
building the measurement first — which is why there is no "symbolic density"
here, and will not be until something measures it.

The weakest section carries its own false-positive rate inline: the value layer
produces a confident reading on unrelated claim pairs **61%** of the time, so a
single row is not a finding.

### Reading the graph

`POST /api/v1/graphql` — **queries only.** The record is recursive by
construction: everything is an assertion, including assertions about assertions,
and REST answers *"this document, then its claims, then every assertion about
each, then the challenges to those"* in as many round trips as there are levels.

```graphql
{ assertion(id: 114) {
    act subjectLabel asserter { name }
    assertions { act asserter { name primitive } assertions { act } } } }
```

There is **no mutation root** — not an empty one, none. Writing goes through
REST, where the delegation gate lives, and a second write path would be a second
thing to keep in step with it. The recursion that makes the layer worth building
is also unbounded by nature, so `max_depth 12` and `max_complexity 400` are
load-bearing rather than boilerplate: a query that asks for too much is told so
rather than truncated into a plausible-looking partial answer.

Same token, same Referent, same policies. The schema exposes what a viewer may
already read in the browser; the one capability question inside it is a baseline
measurement, which needs the role that may see the model registry.

### The command line

`bin/alexicon` is a thin HTTP client over the same endpoints. It boots no Rails —
an interactive session should feel like a terminal, and half a second of
framework startup per claim is the difference between forty claims being a task
and forty claims being a chore.

```sh
export ALEXICON_TOKEN=...        # or ~/.alexicon, or --token=
bin/alexicon type 27             # type a document's claims blind, one keystroke each
bin/alexicon comparison 27       # agreement with the classifier, and where you part
bin/alexicon profile 27          # the document's epistemic structure, as markdown
bin/alexicon mentions 27         # names awaiting an answer
bin/alexicon ground 1940 --subject=Person --role=Mother
bin/alexicon ignore 1945         # ...or record that it is not a subject at all
bin/alexicon documents           # documents · show · ingest · classify · govern
```

`type` is the reason it exists. It shows the claim with the same four-claim
context window the classifier was given, the categories with their definitions,
and nothing else — no reading, no flags, no neighbours' categories. A number
types the claim, `u` marks an answer you could argue the other way, `.` records
that you cannot tell, `q` stops and the session resumes where you left it.

A token belongs to a **Referent**, so what you record from a terminal is
attributed exactly as it would be from the browser, and an agent driving the same
command still needs the delegation a person would not.

### Typing claims blind

The act the programmatic surface was built for: a review decision the
application expects a person to make, made by an agent instead, on the record,
as itself.

```
GET  /api/v1/documents/:id/blind_reading             next claim, context, categories
POST /api/v1/documents/:id/blind_reading             record a reading or an abstention
GET  /api/v1/documents/:id/blind_reading/comparison  agreement, and where they part
```

Reading needs no delegation, because the endpoint has nothing to disclose: the
payload is byte-identical whether or not the classifier has typed the claim.
Recording one needs `type_claim`.

An agent's blind reading is a **second opinion, not a further vote** — it is
recorded in full, excluded from the classifier's tally, and the response says so
in `counts_toward_classification`. Merging two judges' readings into one majority
would be two instruments reported as one measurement. A person's reading still
settles the claim, as it does everywhere else.

## Setup

Requires Ruby 3.4.8 and PostgreSQL 16+.

```sh
bundle install
bin/rails db:prepare   # create, migrate, seed
bundle exec rspec
bin/dev                # http://localhost:3000

bin/rails "alexicon:user[avery,a-good-password,admin]"
```

Then sign in and certify a model at `/llm_models` — nothing will classify until
you do, which is the intended posture: no model influences a judgement because
a constant named it.

Classification needs a key for whichever provider you route to. Set one at
`/llm_providers` — encrypted at rest, shown afterwards only as its last four
characters plus who set it and when, and filtered out of the logs. Or export it:

```sh
export ANTHROPIC_API_KEY=...   # or OPENAI_API_KEY, or GEMINI_API_KEY
```

A stored key wins over the environment, because setting one is a deliberate act
by a named person and an exported variable is ambient; clearing it falls back.
`/llm_providers` states which of the two is actually in effect for each provider.

Encryption uses `config/master.key`, so it protects database dumps, backups and
replicas — not someone holding both the database and the master key.

With no key in either place, `ClaimClassifier` raises `MissingCredentials`
naming both places to look, rather than failing obscurely. Everything else —
ingest, identity resolution, governance — runs without a key at all.

Adapters report failure in one taxonomy rather than their vendor's, because
the decision that depends on it is the same either way:

| Failure | Retried |
|---|---|
| `RateLimited` (429), `ServerError` (5xx), `ConnectionFailed` | yes, five attempts, backing off |
| `RequestRejected` (4xx), missing credentials, no routed model | no — retrying reaches the same answer |

A retry re-runs the whole document, which is cheap: a claim with a standing
classification is skipped, so it resumes rather than repeating calls already
paid for.

The Gemini and Anthropic adapters have both been exercised against their live
APIs. The OpenAI adapter is written against the published request format and
has not been called; certification is where a person puts their name to "this
works", and nobody has done so for it.

`config/database.yml` reads `PGHOST` and `PGPORT`, defaulting to
`localhost:5433`. On a standard PostgreSQL install you will want:

```sh
export PGPORT=5432
```

The non-standard default exists because this was developed on a shared machine
where port 5432 belonged to another account.

## Licence

Two kinds of work, two sets of terms — see [`COPYRIGHT.md`](COPYRIGHT.md).

- **Source code** — © 2026 Jeff Highman. All rights reserved. Viewable and
  forkable; no use, modification, or redistribution without written permission.
- **Documentation** (`docs/`) — © 2026 Jeff Highman & Alexandra Krížová.
  [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/).

`docs/THESIS.md` is a draft. Confirm its status with the author before citing
or relying on it.
