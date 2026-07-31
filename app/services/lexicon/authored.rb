# The part of the vocabulary that no row and no constant holds.
#
# Everything here is hand-written and therefore able to drift, so each entry
# names the file it describes. Where a concept HAS a home in the data it is not
# repeated here — it is generated instead, and a duplicate would break the rule
# that a term is filed exactly once.
class Lexicon
  module Authored
    def self.term(key, name, cluster, kind, definition, distinct_from: nil, see_also: [])
      Term.new(key: key, name: name, cluster: cluster, kind: kind, definition: definition,
               distinct_from: distinct_from, see_also: see_also, source: "authored")
    end

    TERMS = [
      # --- the record ---------------------------------------------------------
      term("assertion-record", "Assertion", "record", "record type",
           "The only record type there is. An accountable claim by someone, about " \
           "something — including about another assertion, which is what makes the " \
           "record recursive. Immutable once written: `readonly?` is `persisted?`. " \
           "`app/models/assertion.rb`",
           distinct_from: "**Assertion (flow stage)**, which is a step in the epistemic " \
                          "flow rather than a row. The record type is what the system " \
                          "stores; the flow stage is what a person does.",
           see_also: %w[Standing Superseded Act]),
      term("standing", "Standing", "record", "state",
           "An assertion nothing has superseded. `Assertion.standing` is the scope " \
           "everything derived reads from — a superseded assertion is kept and stops " \
           "counting. `app/models/assertion.rb`",
           see_also: [ "Superseded", "Derived" ]),
      term("superseded", "Superseded", "record", "state",
           "Replaced by a later assertion that names it. Nothing is overwritten and " \
           "nothing is deleted, so a changed judgement leaves both readings in the " \
           "record and the change is itself visible.",
           see_also: [ "Standing" ]),
      term("derived", "Derived", "record", "principle",
           "Computed from standing assertions at read time, never stored. " \
           "`Claim#category`, `Transition#verdict`, `Mention#status` and " \
           "`Assertion#disposition` are all derived. A stored summary can disagree " \
           "with what it summarises; a derived one cannot.",
           see_also: [ "Standing" ]),
      term("evidence", "Evidence", "record", "record type",
           "Material attached to an assertion in support of it. Linked rather than " \
           "embedded, so the same evidence can support more than one claim and be " \
           "found from either end. `app/models/evidence.rb`"),

      # --- identity -----------------------------------------------------------
      term("referent", "Referent", "identity", "record type",
           "A subject in the graph: a person, a system, or a thing a document names. " \
           "Every judgement attributes to a Referent and never to an account, which " \
           "keeps authorisation and provenance separate questions. " \
           "`app/models/referent.rb`",
           see_also: [ "Cognitive Passport", "User" ]),
      term("user", "User", "identity", "record type",
           "An account: a credential and a role. It carries no authorship — its " \
           "Referent does. `app/models/user.rb`",
           distinct_from: "**Referent**, which is who the judgement is by. Conflating " \
                          "them would put credentials in the audit trail.",
           see_also: [ "Referent" ]),
      term("cognitive-passport", "Cognitive Passport", "identity", "concept",
           "`Name → Subject → Roles(standing, ≥ 1)`. What must be established before " \
           "anything may be predicated of a name. A partial passport is not a " \
           "resolution, and zero standing roles is a partial passport.",
           see_also: [ "Entity Noise", "Mention", "Role" ]),
      term("role", "Role", "identity", "concept",
           "A standing assertion about a referent — attributable, contestable, " \
           "plural by construction, retired by supersession and never deleted. Roles " \
           "coexist rather than compete: caregiver and engineer and exhausted are " \
           "not rival answers to one question, so there is no majority to take and " \
           "no contested state; what can be disputed is one role assertion. ADR 21.",
           distinct_from: "**Subject**, the ontological kind (Person, Family, " \
                          "Concept), which stays a stored field — and from a User's " \
                          "authorisation role, which is a credential, not a claim.",
           see_also: [ "Cognitive Passport", "Referent" ]),
      term("mention", "Mention", "identity", "record type",
           "One occurrence of a name in a document, before anyone has said what it " \
           "refers to. Extraction proposes; a person disposes. " \
           "`app/models/mention.rb`",
           see_also: [ "Cognitive Passport", "Identity STOP" ]),
      term("entity-noise", "Entity Noise", "identity", "concept",
           "A name arriving without established reference. Nothing may be predicated " \
           "of it until it resolves — and refusing to guess is the point, so the " \
           "resolver is deterministic rather than model-backed."),
      term("identity-stop", "Identity STOP", "identity", "concept",
           "The flag raised when a name cannot be resolved. It blocks **governance** " \
           "and not classification: the lock guards predication, not description. " \
           "ADR 11.",
           distinct_from: "**Stop (severity)**, which is the severity level a flag " \
                          "carries. An identity STOP is a particular use of it.",
           see_also: [ "Entity Noise", "Executable" ]),
      term("referent-alias", "Referent alias", "identity", "record type",
           "Another surface form for the same Referent — a misspelling, a surname " \
           "alone, a fuller name. What keeps object constancy over a transposed " \
           "letter. `app/models/referent_alias.rb`",
           see_also: [ "Referent" ]),
      term("executable", "Executable", "identity", "state",
           "A document with no open identity STOP. Governance may run; until then it " \
           "may not. `Document#executable?`",
           see_also: [ "Identity STOP" ]),

      # --- kinds of claim -----------------------------------------------------
      term("claim-record", "Claim", "claim", "record type",
           "One individually classifiable statement within a document, traced to the " \
           "span of source text it came from. `app/models/claim.rb`",
           see_also: [ "Structural", "Agreement" ]),
      term("structural", "Structural", "claim", "state",
           "Part of the document but not a claim about anything — a heading, a table " \
           "row, a lead-in. Marked rather than dropped: marking is not hiding. " \
           "ADR 16.",
           see_also: [ "Lead-in", "Claim" ]),
      term("lead-in", "Lead-in", "claim", "concept",
           "A short line ending in a colon, alone on its line. It announces what " \
           "follows rather than claiming anything itself, so the claim is the text " \
           "underneath. ADR 16, which also records what the rule costs.",
           see_also: [ "Structural" ]),
      term("agreement", "Agreement", "claim", "concept",
           "What repeated readings of a claim agreed on, and on how many readings. A " \
           "category needs a **strict majority** — a plurality does not decide, and " \
           "no majority means the system does not know. `Claim#agreement`",
           see_also: [ "Strict majority", "Blind reading" ]),
      term("strict-majority", "Strict majority", "claim", "rule",
           "More than half the readings naming the same category. Two of five is not " \
           "agreement.",
           see_also: [ "Agreement" ]),
      term("blind-reading", "Blind reading", "claim", "concept",
           "A reading taken without sight of any other reading of the same claim. " \
           "Recorded in full and counted in no tally: merging a second judge's " \
           "readings into the first judge's majority would be two instruments " \
           "reported as one measurement. `app/services/blind_reading.rb`",
           see_also: [ "Agreement", "Inter-judge agreement" ]),

      # --- steps --------------------------------------------------------------
      term("transition", "Transition", "step", "record type",
           "The step from one claim to the next. The unit of governance: claims are " \
           "typed, steps are judged. `app/models/transition.rb`",
           see_also: %w[Verdict Promotion]),
      term("promotion", "Promotion", "step", "concept",
           "A move to a kind of claim needing more warrant. What it costs is set per " \
           "**ordered pair** rather than by subtracting ranks, because " \
           "`interpretive → ontological` and `objective → interpretive` are not the " \
           "same move. `CategoryPromotion`",
           see_also: [ "Verdict", "Is/ought crossing" ]),
      term("is-ought", "Is/ought crossing", "step", "concept",
           "A move between `ontological` and `normative` in either direction. The " \
           "only pair weighted **symmetrically**: everywhere else the ascent costs " \
           "and the descent is free, and nothing about an ought is firmer ground for " \
           "an is. ADR 17.",
           see_also: [ "Promotion" ]),
      term("position", "Position", "step", "concept",
           "What one asserter currently says about a step under one framework — the " \
           "latest of however many times it ruled. A judge that ruled three times " \
           "holds one position, not three, so repetition cannot outvote a second " \
           "judge. `Transition#positions`",
           distinct_from: "**Ruling**, which is a single recorded assertion. A " \
                          "position is the standing one among an asserter's rulings.",
           see_also: %w[Verdict Contested Drift]),
      term("contested", "Contested", "step", "concept",
           "Two asserters reaching different conclusions about the same thing under " \
           "the **same** premises. On a step it is reported instead of a verdict, " \
           "never as one: it sits outside `VERDICTS`, so nothing can assert it and no " \
           "sentinel can record it. On a claim it means two people typed it " \
           "differently, which leaves it untyped rather than typed by whoever read " \
           "last. Either way, the system saying it does not know. " \
           "`Transition#contested?`, `Claim#contested?`",
           distinct_from: "**Drift**, which is one asserter changing its own answer, " \
                          "and from a **premise difference**, which is two frameworks " \
                          "priced differently and is not disagreement at all.",
           see_also: %w[Position Drift Premise Agreement]),
      term("drift", "Drift", "step", "concept",
           "One asserter giving different answers to the same question under the same " \
           "premises. A fact about the instrument rather than about the step; the " \
           "latest position stands and the change is reported rather than hidden. " \
           "`Transition#unstable?`",
           distinct_from: "**Contested**, which is two asserters disagreeing. Drift " \
                          "is a single judge that moved.",
           see_also: %w[Contested Position]),
      term("premise", "Premise", "step", "concept",
           "What a framework charges for a move, and therefore what it holds about " \
           "warrant. `alexicon-2.0` prices `ontological → normative` at 2 with a " \
           "rationale naming Hume; `lewisian-1.0` prices it at 0. Every ruling names " \
           "the premises it was made under, so two of them coexist rather than one " \
           "overwriting the other. `Assertion#framework`",
           distinct_from: "**Framework**, which is the whole versioned object — " \
                          "categories, stages, values. A premise is what its weights " \
                          "commit it to.",
           see_also: [ "Framework", "Promotion", "Is/ought crossing", "Contested" ]),
      term("case", "Case", "step", "record type",
           "A bounded episode of a document: the unit judgment waits for. An edge " \
           "from the first claim of an episode to its last, bounded by structure — " \
           "a heading restarts an argument, a signature ends a letter. The scope at " \
           "which an ending is allowed to reinterpret a step. `app/models/case.rb`",
           distinct_from: "**Transition**, which is one step; a case is the closed " \
                          "episode the step happened inside.",
           see_also: %w[Closure Transition Observer]),
      term("closure", "Closure", "step", "concept",
           "The establishment of an episode's right boundary — a structural claim, " \
           "or the end of a completed document. Deliberately a constructor rather " \
           "than a gate: a case that has not closed does not exist, so judgment " \
           "structurally cannot outrun it. In text still being written, the final " \
           "run of claims is not a case yet. ADR 20.",
           see_also: [ "Case", "Deferred evaluation" ]),
      term("deferred-evaluation", "Deferred evaluation", "step", "concept",
           "Judgment over completed causal structures rather than tokens: the jury " \
           "hears the whole case before it deliberates, because the ending is " \
           "allowed to reinterpret the beginning. The evaluation layer's form of " \
           "the requirement a transformer meets with attention geometry.",
           distinct_from: "**Future visibility**, which widens what a judge sees " \
                          "while representations form. Deferral changes when the " \
                          "question may be asked, not what is visible.",
           see_also: %w[Case Closure]),
      term("case-observer", "Observer", "step", "concept",
           "The judge whose subject is a closed case. Asks the pair-scoped tension " \
           "question — a conflict at this step, or none — with the whole episode " \
           "visible, so the two scopes are measurably comparable. Proposes, never " \
           "rules. `app/services/case_observer.rb`",
           see_also: [ "Case", "Step value reading" ]),
      term("retroactive-audit", "Retroactive audit", "step", "concept",
           "When a step is judged unearned, looking back at what it stood on. Four " \
           "unearned steps in a row are one failure with three consequences, and the " \
           "claim to look at is the first. It never re-judges and calls no model. " \
           "`app/services/retroactive_audit.rb`",
           see_also: [ "Verdict" ]),

      # --- values -------------------------------------------------------------
      term("step-value", "Step value reading", "value", "concept",
           "What an unearned step puts first, and what it sets aside. A claim about " \
           "the **move** — the assertion's subject is the Transition, so a claim " \
           "about a person is not a sentence the class can express. It does not " \
           "currently distinguish signal from noise; see BASELINE-v3. " \
           "`app/services/step_value_judge.rb`",
           see_also: [ "Vocabulary", "Observed Value Priority" ]),
      term("vocabulary", "Vocabulary", "value", "concept",
           "The list of values a reading may choose from, carried by the framework " \
           "rather than the code. A different framework carries a different account " \
           "of what people protect, and the reading records which one produced it.",
           see_also: [ "Provenance" ]),
      term("provenance-value", "Provenance", "value", "state",
           "Whether a value was already in the record as something a model had been " \
           "probed against (`probe`) or is intuition (`proposed`). A seeded list of " \
           "what people protect is a claim about people and should say which parts " \
           "are proposed.",
           see_also: [ "Vocabulary" ]),
      term("observed-value-priority", "Observed Value Priority", "value", "method",
           "Alexandra Krížová's method: do not ask what something values, put two " \
           "commitments in conflict and observe. Behaviour is evidence; priority is " \
           "a claim **about** the evidence and is never recorded as the first. " \
           "ADR 14.",
           see_also: [ "Step value reading", "Value probe" ]),
      term("value-probe", "Value probe", "value", "record type",
           "A scenario putting two commitments in conflict, put to a model, with the " \
           "response recorded verbatim. Infers nothing. `app/models/value_probe.rb`",
           see_also: [ "Observed Value Priority" ]),

      # --- actors -------------------------------------------------------------
      term("sentinel-principle", "Sentinel Principle", "actor", "principle",
           "The evaluator must not be the transformation it governs. Enforced rather " \
           "than intended: `GovernanceSentinel` raises `NotIndependent`, and the step " \
           "value judge refuses to read a step it ruled on.",
           see_also: [ "Sentinel" ]),
      term("sentinel", "Sentinel", "actor", "actor",
           "A system Referent whose job is to ask whether the conditions for a " \
           "judgement have been met, rather than to perform it.",
           see_also: [ "Sentinel Principle" ]),
      term("api-token", "API token", "actor", "record type",
           "A credential belonging to a **Referent**, not a user session. Whatever " \
           "holds it attributes its judgements to itself, so an agent can never " \
           "leave a record saying a person decided. `app/models/api_token.rb`",
           see_also: %w[Delegation Referent]),
      term("delegation", "Delegation", "actor", "record type",
           "A standing decision by a named person that a class of judgement may be " \
           "made with nobody present. Absence of a row is refusal. " \
           "`app/models/delegation.rb`",
           see_also: [ "TEI inversion", "Temporal drift" ]),
      term("tei-inversion", "TEI inversion", "actor", "principle",
           "Authority **tightens** the justification required of it rather than " \
           "loosening it. The wider the pattern and heavier the act, the more a " \
           "delegation must carry to exist: a rationale, then an expiry, then a " \
           "bounded one. Alexandra Krížová's rule.",
           see_also: [ "Delegation" ]),
      term("temporal-drift", "Temporal drift", "actor", "concept",
           "Whether an actor has quietly stopped deciding the way it used to, " \
           "measured against **its own** past rather than a population. TEI " \
           "inversion checks a delegation when granted; this watches what happens " \
           "afterwards. `app/services/temporal_drift_audit.rb`",
           see_also: [ "TEI inversion" ]),
      term("inferred", "Inferred", "actor", "state",
           "Decided by something whose Referent is a system rather than a person. " \
           "Shown wherever the decision is shown.",
           see_also: [ "Delegation" ]),

      # --- measurement --------------------------------------------------------
      term("baseline", "Baseline", "measure", "concept",
           "A set of measurements about the model the system runs on, each recorded " \
           "as an assertion with its sample, conditions, caveats and code revision. " \
           "A rate on its own cannot be compared to anything. " \
           "`app/services/baseline.rb`",
           see_also: %w[Condition Caveat]),
      term("condition", "Condition", "measure", "concept",
           "What a figure was taken under. `Baseline.compare` **refuses** to call two " \
           "figures comparable when their conditions differ, and names which one " \
           "diverged, rather than reporting a difference that may be the instrument.",
           see_also: [ "Baseline" ]),
      term("caveat", "Caveat", "measure", "concept",
           "What a figure cannot support, recorded beside it. Not decoration: a " \
           "baseline whose limits are not written down gets compared to things it " \
           "cannot be compared to.",
           see_also: [ "Baseline" ]),
      term("inter-judge", "Inter-judge agreement", "measure", "concept",
           "How often two independent judges type the same claim the same way. Not " \
           "correctness — two judges agreeing tells you they agree.",
           see_also: [ "Blind reading" ]),
      term("shuffle-control", "Shuffle control", "measure", "method",
           "Running a reader against inputs with no real relation, to see whether it " \
           "answers anyway. The check that separates reading something from " \
           "answering the question it was asked."),
      term("gap-invariance", "Gap invariance", "measure", "property",
           "Two records identical in what they establish score the same however " \
           "those things are spaced in time. The enforceable form of the " \
           "anti-discrimination policy — narrow, and unlike a general claim of " \
           "fairness, checkable. `app/services/gap_invariance.rb`",
           see_also: [ "Policy" ]),

      # --- the framework ------------------------------------------------------
      term("framework", "Framework", "frame", "record type",
           "A version of the whole structure — its domains, categories, promotion " \
           "weights, flow stages and values. Framework as data: adding a category is " \
           "an edit to a seed, not a migration.",
           see_also: %w[Domain Vocabulary]),
      term("policy", "Policy", "frame", "record type",
           "A cross-cutting constraint binding several domains without belonging to " \
           "any. A policy nothing has been checked against is a statement of intent " \
           "rather than a constraint. `app/models/policy.rb`",
           see_also: [ "Gap invariance" ]),
      term("justification-rank", "Justification rank", "frame", "property",
           "How much warrant a claim of a given kind needs on its own. Three values " \
           "over five categories, so it cannot express what a **move** costs — which " \
           "is why promotion is weighted per ordered pair.",
           distinct_from: "**Promotion**, which is what a move between two kinds " \
                          "costs. Rank is a property of a category; weight is a " \
                          "property of a pair.",
           see_also: [ "Promotion" ]),
      term("disputed", "Disputed", "frame", "state",
           "A term whose sources contradict each other, marked rather than quietly " \
           "resolved. The terminology register carries them.")
    ].freeze

    # Which cluster each generated kind belongs to.
    CLUSTER_FOR = {
    "claim category" => "claim", "flow stage" => "frame", "domain" => "frame",
    "value" => "value", "act" => "record", "severity" => "record",
    "verdict" => "step", "delegable act" => "actor", "role" => "actor",
    "mention status" => "identity", "model status" => "actor"
  }.freeze

    # A generated term whose source carries no definition of its own.
    GENERATED_GLOSS = {
    "flow stage:observation" => "The first stage: what was noticed.",
    "flow stage:experience" => "What the noticing was like.",
    "flow stage:interpretation" => "Meaning read into the experience.",
    "flow stage:meaning" => "The interpretation settling into something held.",
    "flow stage:belief" => "What is now taken to be so.",
    "flow stage:assertion" => "The belief stated to somebody.",
    "flow stage:action" => "The assertion acted upon. The ladder ends here.",
    "act:assert" => "State something, on the record, as oneself.",
    "act:amend" => "Restate an earlier assertion without erasing it.",
    "act:revoke" => "Withdraw an assertion, leaving the withdrawal visible.",
    "act:challenge" => "Dispute an assertion. The disputed assertion stands until disposed.",
    "act:delegate" => "Grant that a class of judgement may be made with nobody present.",
    "act:flag" => "Raise something for attention, at a severity.",
    "act:accept" => "Dispose of a flag by letting what it flagged stand.",
    "act:reject" => "Dispose of a flag by setting aside what it flagged.",
    "act:classify" => "Say what kind of claim something is.",
    "act:resolve" => "Say what a name refers to.",
    "severity:notice" => "Worth seeing. Blocks nothing.",
    "severity:concern" => "Worth answering. Blocks nothing.",
    "severity:stop" => "Blocks governance until a person disposes of it.",
    "verdict:earned" => "The step took no more warrant than the claim before it carried.",
    "verdict:unearned" => "The second claim asserts more than the first supports.",
    "verdict:undetermined" => "Not judged — an endpoint carries no category.",
    "role:viewer" => "Read documents, claims and flags.",
    "role:reviewer" => "Also submit texts, run analyses, answer flags, ground names.",
    "role:auditor" => "Read, plus the model registry and every invocation.",
    "role:admin" => "Everything, including certifying and revoking models.",
    "mention status:unresolved" => "Nobody has said what this name refers to.",
    "mention status:resolved" => "A passport has been assigned.",
    "mention status:ambiguous" => "Several candidates, or a surface form with non-entity senses.",
    "mention status:out_of_distribution" => "No match in memory.",
    "mention status:unanchored" => "A passport could not be assigned.",
    "delegable act:dispose_flag" =>
      "Answer a flag — accept what it flagged, or set it aside. Weighted 2: it " \
      "lifts a STOP.",
    "delegable act:ground_mention" =>
      "Say what a name refers to, by assigning a passport.",
    "delegable act:ignore_mention" =>
      "Record that a name is not a subject at all.",
    "delegable act:certify_model" =>
      "Say a model may influence judgements. Weighted 3, the heaviest: it decides " \
      "which model may judge anything at all.",
    "delegable act:revoke_model" =>
      "Withdraw a model's certification.",
    "delegable act:type_claim" =>
      "Say what kind of claim something is. Weighted 1, the lightest — an agent's " \
      "blind reading is excluded from the classifier's tally by construction, so a " \
      "wrong one can only put a bad second opinion in a comparison.",
    "model status:pending" => "Registered, and may not be assigned to anything.",
    "model status:certified" => "A person has said it may influence judgements.",
    "model status:revoked" => "Withdrawn. It may not be re-certified under the same identity."
  }.freeze

    # A generated term sharing a word with another must say what separates them.
    DISTINCTIONS = {
    "flow stage:observation" =>
      "**Observation (claim category)**, which is what a statement DOES. The flow " \
      "stage is a step a person moves through; the category is a kind of claim.",
    "claim category:observation" =>
      "**Observation (flow stage)**, the first step of the epistemic flow. This is " \
      "a kind of claim, not a stage of arriving at one.",
    "flow stage:assertion" =>
      "**Assertion (record type)**, the single kind of row this system stores. The " \
      "flow stage is the act of stating; the record type is what a statement " \
      "becomes once written down.",
    "flow stage:interpretation" =>
      "**Interpretive (claim category)**, which is a kind of claim. This is the " \
      "stage at which meaning is read into an experience.",
    "claim category:interpretive" =>
      "**Interpretation (flow stage)**. The category describes what a statement " \
      "does; the stage describes where a person is.",
    "flow stage:action" =>
      "**Agency (domain)**, which asks what choices remain. Action is the stage at " \
      "which one is taken.",
    "delegable act:certify_model" =>
      "**Certified (model status)**, which is the state certifying produces.",
    "delegable act:revoke_model" =>
      "**Revoke (act)**, which withdraws an assertion. This withdraws a model's " \
      "certification.",
    "value:autonomy" =>
      "**Agency (domain)**. The value is what a person decides for themselves; the " \
      "domain asks what choices remain open.",
    "value:agency" =>
      "**Agency (domain)**, which asks what choices remain open. The value is the " \
      "commitment to an outcome having been authored rather than suffered.",
    "value:purpose" =>
      "**Motivation (domain)**, which asks why something matters. Purpose is one " \
      "of the commitments a step can put first.",
    "domain:motivation" =>
      "**Purpose (value)**, which is a single commitment. The domain is where all " \
      "of them live.",
    "domain:agency" =>
      "**Autonomy (value)** and **Action (flow stage)**. The domain is a question " \
      "the framework asks; the others are an answer and a step.",
    "domain:reflection" => nil,
    "domain:identity" =>
      "**Referent**, which is the record type identity resolves to. The domain is " \
      "the question; the Referent is the answer."
  }.compact.freeze
  end
end
