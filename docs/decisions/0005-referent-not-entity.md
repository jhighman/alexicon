# 5. What a mention resolves to is a Referent, not an Entity

**Date:** 2026-07-24
**Status:** Accepted
**Decided by:** Claude, under delegated judgement.

## Context

The thesis (Chapter 3) defines five primitives, two of which are:

- **Person** — a human individual with agency, consent, accountability, and moral and legal standing.
- **Entity** — "organizations, institutions, corporations, governments, and other legal constructs... Unlike persons, entities persist through changing membership."

The G3/G7 material uses "entity" in an unrelated sense: *Entity Noise*, *entity resolution*, *the Entity Resolution Problem* — meaning any referent an identifier might denote. Its worked example, `Wednesday → Family → Sister`, is a **person** under the thesis ontology.

Our model was called `Entity` and held exactly that. Two incompatible meanings of "Entity" in one project implementing both documents is indefensible.

## Decision

**Rename the model to `Referent`: the thing a mention refers to, whatever primitive it turns out to be.**

`Referent` is the superclass of the resolution target. A mention may resolve to a Person, an Entity, a System, or a Process — the thesis's four actor primitives — so a `primitive` column records which. It is nullable, because the G3/G7 material never specifies it and inventing a value would be exactly the guess the resolver exists to prevent.

**Process terms keep the framework's vocabulary.** *Entity Noise* and *entity resolution* remain in comments and documentation: they are established names for the failure mode and the activity, and the thesis does not use them. Only the noun denoting a stored record changed.

## Consequences

- `entities` → `referents`, `entity_aliases` → `referent_aliases`, `resolutions.entity_id` → `referent_id`.
- `EntityResolver` → `ReferentResolver`. `IdentitySentinel` is unchanged; both documents use "identity" the same way.
- `referents.primitive` accepts `person | entity | system | process`, unenforced pending a decision on whether the full ontology is modelled.
- "Entity" is now free to mean what the thesis means by it, if and when institutional actors are modelled.

## Deferred

**The five primitives are not modelled.** `Person`, `Entity`, `System`, `Process` and `Relationship` are a substantially larger change than a rename, and Relationship-as-first-class-object (Chapter 3) restructures the schema rather than extending it.

Two open questions block it:

1. **Is this application implementing the thesis, or the G3/G7 semantic layer?** Chapter 7.6 says the latter is a special case of the former — but a semantic sentinel governing text is a much narrower build than a general trust graph.
2. **Does `Relationship` subsume `Transition`?** Both are governed edges with their own lifecycle and evidentiary requirements. They may be the same construct at different altitudes, or genuinely distinct.

Recorded rather than resolved, because guessing wrong here is expensive in a way the rename was not.
