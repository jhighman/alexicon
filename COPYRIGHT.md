# Copyright and Licensing

This repository contains two kinds of work under two different terms. Read the
part that applies to what you intend to use.

---

## Source code — All rights reserved

**© 2026 Jeff Highman. All rights reserved.**

Applies to everything except the `docs/` directory: the Ruby source in `app/`,
`db/`, `lib/`, `config/`, `bin/`, the test suite in `spec/`, and all
configuration.

No licence is granted. You may view this code and fork the repository, because
publishing publicly on GitHub grants those rights under GitHub's Terms of
Service. You may **not** use, copy, modify, merge, publish, distribute,
sublicense, or sell any part of it without prior written permission.

The absence of a `LICENSE` file is deliberate, not an oversight. Permissions
can be granted later; they cannot easily be withdrawn once given.

For permission, contact the copyright holder.

---

## Documentation — CC BY-NC-ND 4.0

**© 2026 Jeff Highman & Alexandra Krížová.**

Applies to the co-authored documentation: `docs/THESIS.md`, `docs/THEORY.md`,
`docs/CONOPS.md`, `docs/mindmap.html`, `docs/ARCHITECTURE.md`, and the decision
records in `docs/decisions/`.

### The architecture is now co-authored

**Revised 31 July 2026.** This section previously excluded
`docs/ARCHITECTURE.md` and `docs/decisions/0010` onward on the grounds that they
describe the implementation rather than the framework and were authored by Jeff
Highman alone. That was accurate when it was written. It is no longer accurate,
and the record in this repository is what shows it:

- `docs/decisions/0014` — *observed value priority* — records its source as
  Alexandra Krížová: the method and the domain argument.
- `docs/decisions/0015` — *the peer group is supplied* — records its source as
  Matrix 2.0 Q5, jointly authored.
- `docs/decisions/0020` — *judgment waits for closure* — records its source as
  Alexandra Krížová's answer to the third call, with Jeff's reframe of it. The
  `Case` unit and closure-as-constructor exist because of that exchange.
- `docs/decisions/0021` — *a role is an assertion* — records its source as
  Alexandra Krížová's addendum, and `0022` is the audit that `0021` deferred.
- `docs/ARCHITECTURE.md` itself already attributes two built mechanisms to her
  by name — the TEI inversion, and the sentinel that holds `executable?` false
  until a person answers.

Excluding the architecture from joint authorship while the architecture credits
her inside it was a contradiction, and it under-credited rather than
over-credited. The earlier wording said that attributing this material to both
authors would credit work one of them did not do. On the present record the
reverse is true.

**Not every decision here has a dual origin, and none is being reassigned.**
Decisions `0016`–`0019` and `0022` record Jeff's decisions and audits;
`0010`–`0013` are implementation calls. Each decision states its own source, and
those statements are the authority on provenance. What is being said here is
narrower and is about the body of work rather than its parts: **the architecture
as a whole is now jointly authored**, and it is licensed accordingly.

The same reasoning applies going forward. Where a decision originates with one
author, its record says so. Joint authorship of the document does not flatten
the record of who proposed what, and the record is not evidence of an equal
split in any particular decision.

Licensed under the Creative Commons
**Attribution-NonCommercial-NoDerivatives 4.0 International** licence.

- Summary: https://creativecommons.org/licenses/by-nc-nd/4.0/
- Full text: https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode

You are free to **share** — copy and redistribute the material in any medium
or format — provided you:

| Term | Meaning |
|---|---|
| **BY** — Attribution | Credit both authors, link to the licence, and indicate if changes were made |
| **NC** — NonCommercial | Not for commercial purposes |
| **ND** — NoDerivatives | If you remix, transform, or build upon the material, you may not distribute the result |

Quoting for criticism, review, scholarship, or news reporting is generally
permitted under fair use or fair dealing regardless of this licence, and
nothing here purports to restrict those rights.

### Note on joint authorship

The framework documentation is co-authored, and both authors assent to these
terms. Alexandra Krížová was told what had been published, under which licence,
and that a Creative Commons grant is irrevocable, and confirmed on 25 July 2026
that her name should stay on the work — see
[`docs/FOR-ALEXANDRA.md`](docs/FOR-ALEXANDRA.md).

This paragraph previously recorded the opposite: that the notice was *not* a
representation that both authors had separately assented. That was true when it
was written and is no longer true, which is why it has been changed rather than
removed.

Creative Commons licences are also **irrevocable**. Distribution can be
stopped, but the grant cannot be withdrawn from anyone who already received
the material under it.

---

## Third-party material

`docs/THEORY.md` and `docs/THESIS.md` cite published scholarly work — Winnicott,
Bion, Polanyi, Lacan, Freud, Mahler, Klein, Festinger, Eide & Eide, Acevedo.
Those works remain the copyright of their respective holders. Short quotations
appear with attribution for scholarly commentary.

Unpublished source material held privately in `docs/private/` is excluded from
this repository and is **not** published under any licence here.

---

## Status of the thesis

`docs/THESIS.md` is a **draft**. Publishing a draft publicly may constitute
prior disclosure under some institutional or journal policies. Anyone intending
to rely on, cite, or submit this material should confirm its status with the
author first.
