# 2. Domains are ordered, not dependent

**Date:** 2026-07-24
**Status:** Accepted
**Decided by:** Claude, under delegated judgement.

## Context

The seven domains are presented in a fixed order: Identity, Agency, Motivation, Reflection, Integration, Governance, Orientation. It is a natural reading that each presupposes the one before it — no agency without a stable subject to hold it, no orientation without integration to orient.

But no source states this. The concept map lists them in sequence and says nothing about dependency.

## Decision

**Store `position`. Do not enforce dependency.**

Domains carry an integer position, unique per framework. Nothing in the model requires domain *n* to be satisfied before domain *n+1*.

The reasoning is asymmetric in cost. If they are a dependency stack and we model them as merely ordered, we lose an optimisation and some validation. If they are peers and we model them as a stack, we encode a false constraint into every downstream check and it becomes load-bearing before anyone notices.

Encoding a weaker claim that is true beats a stronger claim that might not be.

## Consequences

- `domains.position` is unique per framework, and ordering is presentation-level.
- The published concept map (`docs/mindmap.html`) numbers the domains 01–07 and describes them as an ascent. **That page asserts more than the model does.** If the domains turn out to be peers, the numbering there should be stripped.
- Adding an eighth domain is a seed change.
