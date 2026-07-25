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
| [`docs/FOR-ALEXANDRA.md`](docs/FOR-ALEXANDRA.md) | A note to the co-author about how this came to be published |
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
- **Documentation** (`docs/`) — © 2026 Jeff Highman & Alexandra Křížová.
  [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/).

`docs/THESIS.md` is a draft. Confirm its status with the author before citing
or relying on it.
