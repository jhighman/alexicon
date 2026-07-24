# 1. The four categories and the seven domains are different axes

**Date:** 2026-07-24
**Status:** Accepted
**Decided by:** Claude, under delegated judgement. Reversible — see Consequences.

## Context

The manuscript and CONOPS are built on four claim categories — Objective, Observation, Interpretive, Ontological. The Alexicon 2.0 concept map is built on seven domains — Identity through Orientation — and does not mention the four categories anywhere.

This read as a possible deprecation: did 2.0 drop the taxonomy? The answer determines whether claims carry a category at all, which is the core of the data model.

## Decision

**Both survive. They classify different things.**

- A **category** answers *what kind of claim is this?* It is a property of a statement.
- A **domain** answers *what kind of check applies here?* It is a property of a governance question.

A claim gets a category. A check belongs to a domain. A Sentinel flag references both: it is raised *by* a domain *about* a category change.

2.0 did not drop the taxonomy — it maps a different axis. The absence is a change of subject, not a deletion.

## Consequences

- `claims` are classified against `claim_categories`; `sentinel_flags` optionally reference a `domain`.
- Both are seeded rows scoped to a `framework`, so a future version may revise either independently.
- If this is wrong and 2.0 genuinely retires the categories, the correction is a seed change plus dropping a nullable association — not a schema rewrite.

## Open

The categories are seeded under `alexicon-2.0` because they are in active use. If they properly belong to the earlier framework version, reseed them under a `g3-g7` framework row and let 2.0 reference that.
