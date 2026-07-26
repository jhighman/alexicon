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
      "What does asking three times instead of once buy, and what does it cost?",
    "finding-set churn (three-reading passes)" =>
      "Does asking three times make the finding set reproduce? Two independent " \
      "three-reading passes, compared set against set.",
    "inter-judge agreement (second model, blind)" =>
      "A different model reads the same claims without seeing the first one's " \
      "answers. Do two judges applying the same four definitions reach the same " \
      "categories?",
    "inter-judge agreement (argumentative prose)" =>
      "The narrative measurement recorded a caveat: that prose which argues rather " \
      "than narrates might not behave the same way. Does it?",
    "finding-set churn (coverage-corrected)" =>
      "When two passes flag different steps, is it because they disagree about the " \
      "step, or because one of them could not judge it at all?",
    "v2/repeated reading — agreement and coverage" =>
      "Thirteen lead-ins and headings are no longer queued as claims. What did that " \
      "buy, and what did it leave?"
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
      "can be judged at all — more of the document analysed, not more failures found.",
    "finding-set churn (three-reading passes)" =>
      "**Not by much**: 0.51 to 0.60, for three times the cost, with 40% of flagged steps " \
      "still not reproducing. Agreement-gating helps at the margin and does not make the " \
      "finding set stable — which settles a question §7 and §8 could each only leave open.",
    "inter-judge agreement (second model, blind)" =>
      "**The gap that matters most in this file.** The classifier reproduces itself 87.9% of " \
      "the time and agrees with a second judge 48.6% of the time. Consistency and agreement " \
      "are not the same property, and every other figure here measures the first one.\n\n" \
      "The disagreements are not scattered. Fifteen of eighteen are the classifier typing " \
      "something other than *observation* where the second judge typed observation — is " \
      "\"That is when Alec replied\" a publicly checkable fact or a first-person report? Both " \
      "readings follow the definitions as written. That points at the **category boundaries** " \
      "before it points at either judge, and it is the same species of finding as §6: the " \
      "framework's distinctions are where its instability lives.",
    "inter-judge agreement (argumentative prose)" =>
      "**It does not, and the caveat was right.** 48.6% on narrative against 75.8% here, which " \
      "puts most of the earlier disagreement on first-person narrative rather than on the " \
      "categories at large.\n\n" \
      "The reversal is the more interesting half. On narrative the second judge pushed claims " \
      "*toward* observation; on argument it pushed them *toward* interpretive. Neither judge is " \
      "simply the more literal one — they disagree about where a **different boundary** sits in " \
      "each genre. A single definition of observation is being asked to do two jobs.",
    "finding-set churn (coverage-corrected)" =>
      "**Mostly coverage, and not entirely.** Of 20 steps flagged only in the first pass, the " \
      "second could not judge 11 — it had abstained on an endpoint — but judged 9 of them " \
      "*earned*, which is a real disagreement. Remove the coverage effect and the lopsided " \
      "20-against-6 becomes 9-against-6.\n\n" \
      "So §9's number was answering two questions at once. **0.70** is how often two passes " \
      "flag the same step when both can judge it; **0.574** mixes that with how often both " \
      "could judge it at all.\n\n" \
      "The unlooked-for finding is the second one. Coverage is itself unstable — the same " \
      "classifier on the same document left 30 claims unread on one pass and 51 on the next, " \
      "10% against 17%. Everything measured so far assumed the abstention rate held.",
    "v2/finding-set churn (coverage-corrected)" =>
      "**The asymmetry v1 could not explain is gone.** It was 20 steps flagged in one pass " \
      "against 6 in the other; here it is 11 against 11, and the unearned counts are identical " \
      "at 50 and 50 where v1 moved 55 to 41.\n\n" \
      "Everything moved the same way once 13 lead-ins stopped being queued as claims — raw " \
      "0.574 to 0.639, corrected 0.70 to 0.75, count movement 25% to nothing. That is " \
      "**consistent with** the lead-ins having been the unstable population, and it is one pair " \
      "of passes at each segmentation. Four indicators from one pair are not four confirmations.",
    "v2/repeated reading — agreement and coverage" =>
      "What the segmentation change bought, and what it did not. Claims given an unstable 1 or " \
      "2 readings of 3 fell from **41 to 26**, and what remains is mostly prose rather than " \
      "fragments.\n\n" \
      "The never-read population did not move at all: 30 either way. Those are the cells of a " \
      "table flattened to one line per cell before the text was ever pasted, plus the title " \
      "block. The segmenter refuses to guess about runs of short unterminated lines — the rule " \
      "that did once swallowed 49 claims including the framework's own category definitions — " \
      "so this was expected rather than a shortfall."
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
      "%{in_both} of %{run1} steps flagged again",
    "inter-judge agreement (second model, blind)" =>
      "%{agreed} of %{compared} claims typed alike",
    "inter-judge agreement (argumentative prose)" =>
      "%{rate} here against %{narrative_rate} on narrative",
    "finding-set churn (coverage-corrected)" =>
      "%{jaccard_where_both_could_judge} judging the same steps, %{jaccard_raw} overall",
    "v2/repeated reading — agreement and coverage" =>
      "%{unstably_read} unstably read, was 41",
    "finding-set churn (three-reading passes)" =>
      "%{in_both} of %{pass1} steps flagged again"
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
      #{mixed_revisions_warning(shas)}#{other_versions}
    MD
  end

  # A later baseline is not a correction of an earlier one. Saying so where a
  # reader will see it is cheaper than letting them assume the numbers line up,
  # and the generator knows which versions exist so the note cannot go stale.
  def other_versions
    others = Baseline.versions - [ version ]
    return "" if others.empty?

    links = others.sort.map { "`#{it}` (#{link_for(it)})" }
    "\n\nAlso recorded: #{links.to_sentence}. These are **not revisions of each " \
      "other** — each was taken under its own conditions, and `Baseline.compare` " \
      "refuses a pair whose conditions diverged rather than reporting a difference " \
      "that may be the instrument."
  end

  def link_for(other)
    other == "v1" ? "[BASELINE.md](BASELINE.md)" : "[BASELINE-#{other}.md](BASELINE-#{other}.md)"
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
    question = editorial(QUESTIONS, measurement)
    parts << "*#{question}*" if question
    parts << table(measurement.measured)
    # Recorded by whoever took the measurement, so it precedes the editorial note.
    parts << detail(measurement)
    parts << editorial(NOTES, measurement)
    parts << context_line(measurement)
    parts << caveats(measurement) if measurement.caveats.present?
    parts.compact.join("\n\n")
  end

  # Recorded as prose by some runs and as a hash of named fields by others.
  # Rendering the hash through `table` rather than interpolating it keeps a
  # recorded field visible without printing Ruby at the reader.
  def detail(measurement)
    value = measurement.detail
    return nil if value.blank?
    return table(value) if value.is_a?(Hash)

    value.to_s
  end

  # Editorial text is looked up version-first, then by criterion alone.
  #
  # Two baselines can measure the same criterion under different conditions, and
  # the note explaining one figure is usually wrong about the other — it names
  # counts and directions specific to the run. Without the version key, v1's
  # commentary would print under v2's number and read as though it described it.
  def editorial(table, measurement)
    table["#{version}/#{measurement.criterion}"] || table[measurement.criterion]
  end

  def headline(measurement)
    template = editorial(HEADLINES, measurement)
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

  # This paragraph asserted that every figure was the system checking itself,
  # and stayed asserting it after a figure arrived that was not. So it counts
  # rather than claims: a measurement naming a second judge in its conditions is
  # one, and the sentence changes when the record does.
  def not_measured(measurements)
    second_judge = measurements.count { it.conditions.key?("judge_b") }
    alone = measurements.size - second_judge

    <<~MD.strip
      ## What is not measured

      - **Correctness.** #{measurements.size} figures. #{correctness_line(alone, second_judge)}
        Nothing here compares the system's output to a *person's* judgement of the
        same text — which would be the most valuable next measurement, and is not a
        software task.
      - **Any model but this one.** The OpenAI adapter has never been called.
    MD
  end

  def correctness_line(alone, second_judge)
    return "All of them are the system agreeing or disagreeing with itself." if second_judge.zero?

    "#{alone} of them are the system agreeing or disagreeing with itself; " \
      "#{second_judge} #{second_judge == 1 ? 'compares' : 'compare'} it against a second " \
      "judge, which is agreement between two readers and not evidence that either is right."
  end

  def empty_report
    "# Baseline #{version}\n\nNo measurements recorded.\n"
  end
end
