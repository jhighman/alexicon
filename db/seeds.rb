# Seeds the Alexicon framework as reference data.
#
# Idempotent -- safe to re-run. Renaming a domain or adding an eighth is a
# change here, not a migration.

fw = Framework.find_or_initialize_by(key: "alexicon-2.0")
fw.update!(
  name: "Alexicon",
  version: "2.0",
  current: true,
  notes: "Restates the G3/G7 stations as seven human-level domains. Relocates " \
         "the framework from transformer-internal layers to the epistemic level."
)

# --- The four categories -----------------------------------------------------
# Different in KIND, not in rank. Merging them is the error to be caught.
[
  [ "objective", "Objective", 1,
    "Publicly checkable fact or mechanism.",
    "External evidence, measurement" ],
  [ "observation", "Observation", 2,
    "First-person report of what was experienced.",
    "Subjective experience" ],
  [ "interpretive", "Interpretive", 3,
    "Meaning assigned to an observation.",
    "Personal inference, narrative" ],
  [ "ontological", "Ontological", 4,
    "Claim about what ultimately exists or is true of reality.",
    "Philosophical or existential commitment" ]
].each do |key, name, pos, definition, source|
  ClaimCategory.find_or_initialize_by(framework: fw, key: key).update!(
    name: name, position: pos, definition: definition, confidence_source: source
  )
end

# --- The epistemic flow ------------------------------------------------------
# The 2.0 sequence. Other framework rows may carry different ladders; at least
# four non-identical variants exist across sources.
%w[observation experience interpretation meaning belief assertion action]
  .each_with_index do |key, i|
  FlowStage.find_or_initialize_by(framework: fw, key: key).update!(
    name: key.capitalize, position: i + 1
  )
end

# --- The seven domains -------------------------------------------------------
domains = [
  { key: "identity", name: "Identity", position: 1,
    question: "Who or what exists?",
    components: [ "Stable Subject", "Self", "Persistent Context" ],
    protects: [ "Identity ambiguity", "Category confusion" ] },

  { key: "agency", name: "Agency", position: 2,
    question: "What choices remain?",
    components: [ "Freedom of Choice", "Available Actions", "Constraints" ],
    protects: [ "Determinism", "Context collapse" ] },

  { key: "motivation", name: "Motivation", position: 3,
    question: "Why does this matter?",
    components: [ "Purpose", "Values", "Intent" ],
    protects: [ "Local optimization", "False objectives" ] },

  { key: "reflection", name: "Reflection", position: 4,
    question: "Can this experience be viewed differently?",
    components: [ "Perspective Shift", "Self Observation", "Temporal Reasoning", "Translation" ],
    protects: [ "Emotional capture", "Narrative lock-in" ] },

  { key: "integration", name: "Integration", position: 5,
    question: "What larger pattern emerges?",
    components: [ "Pattern Formation", "Coherent Meaning", "Relationship Building" ],
    protects: [ "Fragmented reasoning", "Isolated facts" ] },

  { key: "governance", name: "Governance", position: 6,
    question: "Has this interpretation earned the right to guide action?",
    components: [ "Evidence", "Accountability", "Consequence", "Validation" ],
    protects: [ "Unsupported inference", "Confidence without justification" ] },

  { key: "orientation", name: "Orientation", position: 7,
    question: "What enduring way of being emerges?",
    components: [ "Hope", "Character", "Wisdom", "Long-term Direction" ],
    protects: [ "Opportunistic drift", "Cynicism" ] }
]

domains.each do |d|
  domain = Domain.find_or_initialize_by(framework: fw, key: d[:key])
  domain.update!(name: d[:name], position: d[:position], question: d[:question])

  d[:components].each_with_index do |name, i|
    DomainComponent.find_or_initialize_by(domain: domain, name: name).update!(position: i + 1)
  end
  d[:protects].each do |name|
    DomainFailureMode.find_or_create_by!(domain: domain, name: name)
  end
end

# --- Sentinels ---------------------------------------------------------------
# A sentinel is a System referent serving a domain. Flags are attributed to it:
# a governance signal with no accountable author would be the ungrounded claim
# the architecture refuses everywhere else.
Domain.where(framework: fw).find_each do |domain|
  referent = Referent.find_or_initialize_by(key: "#{domain.key}-sentinel")
  referent.update!(
    name: "#{domain.name} Sentinel",
    subject: "System",
    role: "Sentinel",
    primitive: "system",
    domain: domain,
    notes: "Governs: #{domain.question}"
  )
end

# --- Cross-cutting policies --------------------------------------------------
anti_discrimination = Policy.find_or_initialize_by(key: "anti-discrimination")
anti_discrimination.update!(
  name: "Anti-Discrimination Protocol",
  statement: "A gap in a record is an absence of evidence, not evidence of degradation. " \
             "Structural pauses -- caretaking, illness, parental leave, education -- are " \
             "valid, non-degradative life states and carry no penalty.",
  rationale: "Penalising a documented gap promotes a statistical inference about an absence " \
             "into an objective finding about a person. This is the framework's own axiom " \
             "applied to people rather than to sentences."
)
%w[identity reflection governance].each do |key|
  domain = Domain.find_by(framework: fw, key: key)
  DomainPolicy.find_or_create_by!(policy: anti_discrimination, domain: domain)
end

# --- Terminology register ----------------------------------------------------
# Stored, not merely documented, because these names have drifted repeatedly.
terms = [
  { key: "equitable-baseline-scoring", canonical_name: "Equitable Baseline Scoring",
    kind: "protocol", status: "disputed",
    notes: "Containment relation with the Average Ceiling Metric is stated in both " \
           "directions across sources. Resolve before either name becomes a class.",
    aliases: [ [ "Anti-Discrimination Normalizer", "manuscript, Column E" ],
               [ "Anti-Discrimination Protocol", "later material" ] ] },

  { key: "average-ceiling-metric", canonical_name: "Average Ceiling Metric",
    kind: "metric", status: "disputed",
    notes: "See equitable-baseline-scoring. Open sub-question: computed over which " \
           "reference population? A ceiling averaged over an advantaged population " \
           "reproduces the bias it exists to remove.",
    aliases: [ [ "metrika priemerneho stropu", "manuscript, section 5" ] ] },

  { key: "ideal-based-scoring", canonical_name: "Ideal-based Scoring",
    kind: "failure_mode", status: "active",
    notes: "The thing being replaced: treats deviation from a continuous linear path " \
           "as degradation or operational risk.", aliases: [] },

  { key: "jekyll-mask", canonical_name: "Jekyll Mask",
    kind: "failure_mode", status: "active",
    notes: "Compliant surface output concealing a misaligned internal state. Detection " \
           "requires attributing an internal state -- record as inference, not finding.",
    aliases: [ [ "latentna opacita", "manuscript, section 6" ],
               [ "deceptive alignment", "general usage" ] ] },

  { key: "hyde-effect", canonical_name: "Hyde effect",
    kind: "failure_mode", status: "active",
    notes: "Short-term biased optimization beneath the Jekyll Mask. Hyde is the " \
           "behaviour; Jekyll is the facade over it.",
    aliases: [ [ "cherry-picking", "manuscript, sections 3 and 9" ] ] },

  { key: "3d-scaffold-mapping", canonical_name: "3D Scaffold Mapping",
    kind: "mechanism", status: "active",
    notes: "Actor - Force - Target - Environment relational graph. Supplies two real " \
           "observables (unauthorised actor, destructive ripple effects) -- both detect " \
           "that output is unsafe, not that it is deceptive.",
    aliases: [ [ "3D relational graph", "manuscript, section 7" ],
               [ "Priestorovy Matrix", "manuscript, section 9" ] ] },

  { key: "alpha-function", canonical_name: "Alpha-function",
    kind: "mechanism", status: "active",
    notes: "Bion. Parses raw unstructured tokens (beta-elements) into stable, bindable " \
           "relations (alpha-elements) by replacing linear syntax with relational " \
           "geometry. Makes bias addressable; does not remove it -- a well-formed " \
           "graph encodes a biased relation perfectly well. Precondition for the " \
           "policy layer, not a substitute for it.",
    aliases: [ [ "detoxification", "later material" ] ] },

  { key: "double-vector-bypass", canonical_name: "Double Vector Bypass",
    kind: "mechanism", status: "active",
    notes: "Reconstructs a timeline from fixed historical anchors rather than trusting " \
           "the surface shape of a record.",
    aliases: [ [ "Timeline Normalization", "later material" ] ] },

  { key: "entity-noise", canonical_name: "Entity Noise",
    kind: "failure_mode", status: "active",
    notes: "Unresolved or overlapping identities that cannot be mapped to one grounded " \
           "entity. The input condition producing intent hallucination. Detected by " \
           "attention-map dispersion, out-of-distribution tokens, or failed passport " \
           "creation -- all observable pre-execution, without model internals.",
    aliases: [ [ "empty dead nodes", "manuscript, Column C" ],
               [ "ungrounded node", "later material" ] ] },

  { key: "cognitive-passport", canonical_name: "Cognitive Passport",
    kind: "mechanism", status: "active",
    notes: "Name -> Subject -> Role hierarchy attached to an identifier at the input " \
           "boundary (Wednesday -> Family -> Sister). Failure to assign one classifies " \
           "the node as Entity Noise. Lacan's point de capiton: binds a sliding " \
           "signifier to a structural position, sealing identity time-invariantly.",
    aliases: [ [ "kognitivny pas", "manuscript, section 3" ],
               [ "System ID", "manuscript, section 3" ] ] },

  { key: "identity-sentinel", canonical_name: "Identity Sentinel",
    kind: "mechanism", status: "active",
    notes: "Guards the input boundary. Trust assertion: does this subject exist as a " \
           "grounded entity? Locks execution and escalates rather than guessing.",
    aliases: [] },

  { key: "stop-moment", canonical_name: "STOP Moment",
    kind: "mechanism", status: "active",
    notes: "A healthy freeze. Dissonance signals that conditions for proceeding were " \
           "not met -- it is a correct outcome, not an error to smooth over.",
    aliases: [ [ "zdrave kognitivne zamrznutie", "manuscript, section 8" ] ] },

  { key: "attributable-intent-state", canonical_name: "Attributable Intent State",
    kind: "mechanism", status: "active",
    notes: "The emitted judgement: traceable, contestable, auditable.", aliases: [] }
]

terms.each do |t|
  term = Term.find_or_initialize_by(key: t[:key])
  term.update!(canonical_name: t[:canonical_name], kind: t[:kind],
               status: t[:status], notes: t[:notes])
  t[:aliases].each do |name, source|
    TermAlias.find_or_initialize_by(term: term, name: name).update!(source: source)
  end
end

puts "Seeded #{Framework.count} framework(s): " \
     "#{Domain.count} domains, #{ClaimCategory.count} categories, " \
     "#{FlowStage.count} flow stages, #{Policy.count} policies, #{Term.count} terms " \
     "(#{Term.disputed.count} disputed), " \
     "#{Referent.where.not(key: nil).count} sentinels."
