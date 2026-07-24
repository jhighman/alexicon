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

On any of these the Sentinel locks execution and escalates to a person. The
lock is enforced, not advisory — a claim in a locked document cannot be
classified at all, by a model or by a human. Disposing of the flag lifts it;
what is not possible is reasoning past it silently.

**Framework as data.** Domains, claim categories, and flow stages are seeded
rows scoped to a framework version, not constants. A terminology register
tracks names that have drifted, and records contested ones as `disputed`
rather than silently resolving them.

**Model registry** — a model may not influence any judgement until an admin
certifies it. Every call is recorded: model, tokens, cost, latency, outcome,
linked to the judgement it produced.

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

Classification calls the Claude API and needs a key:

```sh
export ANTHROPIC_API_KEY=...
```

Without one, `ClaimClassifier` raises `MissingCredentials` rather than failing
obscurely. Everything else — ingest, identity resolution, governance — runs
without it.

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
