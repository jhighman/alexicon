# Renders a baseline as markdown, from the recorded measurements.
#
# BASELINE.md was hand-written and had drifted within a day: the file described
# seven measurements while the system held eight. That is the failure this
# project is built around — a stored summary disagreeing with what it
# summarises — occurring in its own documentation.
#
# So the document is derived, like `Claim#category` and `Transition#verdict`
# are derived. Re-render after any measurement and the published record cannot
# lag. Nothing here interprets: every figure, condition and caveat comes from
# the assertion it was recorded in.
class BaselineReport
  # Editorial framing, not measurement. A criterion with no question here still
  # renders — this only adds a sentence saying what was being asked, and its
  # absence costs nothing but brevity.
  QUESTIONS = {
    "polarity invariance" =>
      "Does negating a claim change what KIND of claim it is? It should not.",
    "classification reproducibility (batched)" =>
      "Ask the same question twice under identical conditions. Does the same answer come back?",
    "context effect on classification" =>
      "Does a claim read alone get typed the same as one read in its document?",
    "order stability (value priority)" =>
      "Put two commitments in conflict and observe what the model does. Does it do the same thing twice?",
    "context relevance (shuffled batch order)" =>
      "Does batching help because the context is relevant, or merely because it is present?",
    "reproducibility by category pair" =>
      "Is the framework's central distinction as reproducible as its periphery?",
    "finding-set churn (unearned steps)" =>
      "Run the same document twice. Are the same steps flagged?",
    "repeated reading — agreement and coverage" =>
      "What does asking three times instead of once buy, and what does it cost?"
  }.freeze

  # What each figure means, where the number alone would mislead. Editorial, and
  # optional: a criterion with no note renders without one.
  NOTES = {
    "polarity invariance" =>
      "The categories differ in kind, not in content, so a classifier whose category moves " \
      "under negation is reading what a claim *says* rather than what it *does*. Both of the " \
      "changes seen were arguable rather than obviously wrong.",
    "classification reproducibility (batched)" =>
      "**Interpretive is the unstable one** — 16 of the 28 disagreements start there, and the " \
      "largest single group promotes *interpretation into ontology*. That is precisely the " \
      "transition the Sentinel exists to police, and it is a question about the definitions as " \
      "much as about the model.",
    "context effect on classification" =>
      "Giving the model the argument a sentence sits in materially changes how it types that " \
      "sentence. It justifies analysing a document as a document rather than as a bag of " \
      "sentences.",
    "order stability (value priority)" =>
      "Alexandra Krížová's method: do not ask a model what it values, put two commitments in " \
      "conflict and observe. **Two of the four contradict the predictions in the source " \
      "table** — this model speculated about the neighbour and wrote the cruel insult. That " \
      "gap is the point of the method; asking it what it values could not have produced it.",
    "context relevance (shuffled batch order)" =>
      "The benefit comes from relevant context, not from company. That is a **cost** as well " \
      "as a gain: a claim's category depends partly on what precedes it, so the principle that " \
      "a claim is judged by what it does rather than by its neighbours is partially traded " \
      "away for stability.",
    "reproducibility by category pair" =>
      "The framework's periphery reproduces well; the distinction the Sentinel exists to " \
      "police does not. Whether that is a model limitation or two categories that are " \
      "genuinely hard to tell apart is **not settled by anything measured here**.",
    "finding-set churn (unearned steps)" =>
      "The count moved 21% while membership moved 49%. **A stable count is not a stable set**, " \
      "and almost nothing consumes the count. Worth knowing where the instability is not: " \
      "segmentation, extraction, identity resolution, governance-given-categories and the " \
      "retroactive audit are all deterministic. Classification is the sole source.",
    "repeated reading — agreement and coverage" =>
      "The unexpected benefit is larger than the intended one. Asking three times was built " \
      "for reliability and bought **coverage**: a claim that abstains on one reading is often " \
      "typed on another. Unearned steps rose because more steps have both endpoints typed and " \
      "can be judged at all — more of the document analysed, not more failures found."
  }.freeze

  # Where a measurement records several figures and no single `rate`, this says
  # which one leads the heading. The wording is editorial; every number is
  # substituted from the measurement itself, so a heading cannot go stale the way
  # a hand-written one did. A criterion absent here, or naming a figure that was
  # not recorded, simply gets no headline.
  HEADLINES = {
    "context effect on classification" =>
      "%{single_claim_agreement} alone → %{batched_agreement} in context",
    "order stability (value priority)" =>
      "%{readings} readings across %{probes} probes",
    "reproducibility by category pair" =>
      "%{interpretive_ontological.rate} on the central distinction, " \
      "%{objective_observation.rate} elsewhere",
    "repeated reading — agreement and coverage" =>
      "%{typed_at_one_reading} → %{typed} claims typed",
    # A Jaccard rendered as a percentage reads as an agreement rate, which it is
    # not. The counts say the same thing without the unit inviting the mistake.
    "finding-set churn (unearned steps)" =>
      "%{in_both} of %{run1} steps flagged again"
  }.freeze

  PREAMBLE = <<~MD.freeze
    > **How to read a number here.** None of these say the model is right. They
    > say whether it is *consistent*, which is a different and smaller claim. A
    > model can be perfectly consistent and consistently wrong. Consistency is
    > worth measuring because inconsistency makes every other question
    > unanswerable.

    Each figure is stored in the system as an assertion *about the model* —
    attributable, challengeable, and superseded by a better measurement rather
    than overwritten. If you re-measure, the earlier reading is still there.
  MD

  def self.render(version:, model: nil) = new(version: version, model: model).render

  def initialize(version:, model: nil)
    @version = version
    @model = model
  end

  def render
    measurements = Baseline.for(version: version, model: model)
    return empty_report if measurements.empty?

    sections = measurements.each_with_index.map { |measurement, i| section(measurement, i + 1) }

    [ header(measurements), PREAMBLE, "---", *sections,
      comparing, not_measured(measurements) ].join("\n\n")
  end

  private

  attr_reader :version, :model

  def header(measurements)
    subject = model || measurements.first.model
    shas = measurements.filter_map(&:code_sha).uniq

    <<~MD.strip
      # Baseline #{version}

      **#{subject&.display_name} · #{measurements.map(&:recorded_at).max&.to_date&.to_fs(:long)}**

      *Generated from the recorded measurements — do not edit by hand. Re-render
      with `rake "alexicon:baseline[#{version}]"`.*

      What this system has measured about the model it runs on, written down so a
      later reading has something to be compared against, and so the comparison is
      honest rather than reassuring.
      #{mixed_revisions_warning(shas)}
    MD
  end

  # Measurements taken at different revisions are not straightforwardly a single
  # baseline. Saying so is better than a header that implies one code state, and
  # `-dirty` means the tree carried uncommitted changes when the figure was taken.
  def mixed_revisions_warning(shas)
    return "\nTaken at code `#{shas.first}`." if shas.size <= 1

    "\n> **Taken across #{shas.size} code revisions** — `#{shas.join('`, `')}`. Figures within " \
      "this baseline were not all measured against the same instrument, so a difference " \
      "between two of them may be a difference in the code. Each section states its own " \
      "revision."
  end

  def section(measurement, number)
    parts = [ "## #{number}. #{measurement.criterion.humanize.sub(/\A\w/, &:upcase)}#{headline(measurement)}" ]
    question = QUESTIONS[measurement.criterion]
    parts << "*#{question}*" if question
    parts << table(measurement.measured)
    parts << NOTES[measurement.criterion]
    parts << context_line(measurement)
    parts << caveats(measurement) if measurement.caveats.present?
    parts.compact.join("\n\n")
  end

  def headline(measurement)
    template = HEADLINES[measurement.criterion]
    filled = substitute(template, measurement.measured) if template.present?
    return " — #{filled}" if filled
    return " — #{(measurement.rate * 100).round(1)}%" if measurement.rate

    ""
  end

  # Returns nil rather than a half-filled heading if any figure named is absent:
  # a heading with a gap in it is worse than no heading.
  def substitute(template, measured)
    missing = false
    filled = template.gsub(/%\{([\w.]+)\}/) do
      value = ::Regexp.last_match(1).split(".").reduce(measured) { |acc, key| acc.is_a?(Hash) ? acc[key] : nil }
      missing ||= value.nil?
      format_value(value)
    end
    missing ? nil : filled
  end

  # Nested measured hashes are flattened rather than dropped: a figure recorded
  # is a figure shown.
  def table(measured, prefix = nil)
    rows = flatten(measured, prefix)
    return nil if rows.empty?

    [ "| | |", "|---|---|", *rows.map { |k, v| "| #{k} | #{v} |" } ].join("\n")
  end

  def flatten(value, prefix = nil, rows = [])
    value.each do |key, val|
      label = [ prefix, key.to_s.humanize.downcase ].compact.join(" — ")
      if val.is_a?(Hash)
        flatten(val, label, rows)
      else
        rows << [ label, format_value(val) ]
      end
    end
    rows
  end

  def format_value(value)
    case value
    when true then "yes"
    when false then "no"
    when Float then value.between?(0, 1) ? "#{(value * 100).round(1)}%" : value.round(4).to_s
    when Array then value.join(", ")
    else value.to_s
    end
  end

  def context_line(measurement)
    bits = []
    bits << "**Sample:** #{describe(measurement.sample)}" if measurement.sample.present?
    bits << "**Conditions:** #{describe(measurement.conditions)}" if measurement.conditions.present?
    bits << "**Code:** `#{measurement.code_sha}`" if measurement.code_sha
    bits.presence&.join("  \n")
  end

  def describe(hash)
    hash.map { |k, v| "#{k.to_s.humanize.downcase} #{format_value(v)}" }.join(", ")
  end

  def caveats(measurement)
    [ "**What this cannot tell you.**", *measurement.caveats.map { "- #{it}" } ].join("\n")
  end

  def comparing
    <<~MD.strip
      ---

      ## Comparing a later reading

      `Baseline.compare(from: "#{version}", to: "…")` **refuses** to call two figures
      comparable when their conditions differ, and names which condition diverged. A
      criterion measured once but not twice is reported as unmeasured rather than
      dropped — a measurement that was not repeated is not a measurement that agreed.

      The conditions stored with each figure include batch size, context window,
      confidence floor, sample, and the code revision. Without those, a changed
      number cannot be told apart from a changed instrument.
    MD
  end

  def not_measured(measurements)
    <<~MD.strip
      ## What is not measured

      - **Correctness.** #{measurements.size} figures, every one of them the system
        agreeing or disagreeing with itself. Nothing here compares its output to a
        human judgement of the same text — which would be the most valuable next
        measurement, and is not a software task.
      - **Any model but this one.** The OpenAI adapter has never been called.
    MD
  end

  def empty_report
    "# Baseline #{version}\n\nNo measurements recorded.\n"
  end
end
