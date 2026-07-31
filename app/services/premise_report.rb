# Renders what a corpus was judged under, from the declared premises.
#
# Route 1 of [ADR 24](../../docs/decisions/0024-values-attach-through-premises.md).
# Nothing here calls a model and nothing is stored: every figure derives from
# `CategoryPromotion`, the standing classifications, and the framework stamped
# on each ruling. Re-render and the document cannot lag what it reports on,
# which is the same reason `BaselineReport` and the lexicon are derived.
#
# The conditions are the point. A figure without them cannot be told apart from
# a changed instrument, so the header names the code revision, the frameworks in
# play, and — because it is a condition and the easiest one to forget — WHO read
# the claims and how many times each.
#
# What this reports is the commitment a step was judged UNDER. It is not, and
# cannot be made into, the commitment its author held: see `StepPremises::CAVEAT`
# and §11 of the value layer's four failures.
class PremiseReport
  def self.render(documents, framework: Framework.current!, comparators: nil)
    new(documents, framework: framework, comparators: comparators).render
  end

  def initialize(documents, framework:, comparators: nil)
    @documents = Array(documents)
    @framework = framework
    @comparators = comparators || Framework.where.not(id: framework.id).order(:key).to_a
  end

  def render
    [ heading, conditions, coverage, categories, crossings, divergence, identity, closing ]
      .compact.join("\n")
  end

  private

  attr_reader :documents, :framework, :comparators

  def claims = @claims ||= Claim.where(document: documents).where(structural: false).to_a
  def steps  = @steps ||= documents.flat_map { it.transitions.to_a }

  def readings
    @readings ||= Assertion.acting("classify").standing
                           .where(subject_type: "Claim", subject_id: claims.map(&:id))
                           .includes(:asserter).to_a
  end

  def heading
    <<~MD
      # Premises — what this corpus was judged under

      *Generated. Re-render with `rake "alexicon:premises_report[kind:file]"`, or
      with a title fragment in place of the selector. Do not edit by hand.*

    MD
  end

  # Everything a later reading needs to tell a changed figure from a changed
  # instrument.
  def conditions
    by_reader = readings.group_by { it.asserter }.transform_values(&:size)
    per_claim = claims.empty? ? 0 : (readings.size.to_f / claims.size).round(2)

    rows = [
      [ "generated", Time.current.utc.iso8601 ],
      [ "code revision at render", revision ],
      [ "ingested", ingest_window ],
      [ "framework", "#{framework.key} (#{framework.version})" ],
      [ "compared against", comparators.map(&:key).presence&.join(", ") || "nothing" ],
      [ "documents", documents.size ],
      [ "substantive claims", claims.size ],
      [ "readings per claim", per_claim ],
      [ "read by", by_reader.map { |r, n| "#{r&.key || 'unattributed'} (#{n})" }.join(", ") ]
    ]

    <<~MD
      ## Conditions

      #{table(%w[condition value], rows)}
      > **The reader is a condition.** Two runs whose classifiers differ are two
      > instruments, and their figures are reported side by side, never merged —
      > the same rule the record already applies to two judges of one claim.
      #{single_reading_caveat}
    MD
  end

  # The revision above is the one this REPORT was rendered under. The claims,
  # mentions and identity flags were written at ingest, under whatever the code
  # was then — so a rule added since does not appear in figures taken before it.
  # Reporting one revision for both would be a changed instrument wearing a
  # single label, which is the confusion the conditions exist to prevent.
  def ingest_window
    stamps = documents.map(&:created_at).compact.minmax
    return "unknown" if stamps.compact.empty?

    first, last = stamps
    window = first.to_date == last.to_date ? first.utc.to_date.to_s : "#{first.utc.to_date}..#{last.utc.to_date}"
    "#{window} (claims and identity flags date from here, not from the revision above)"
  end

  def single_reading_caveat
    per_claim = claims.empty? ? 0 : readings.size.to_f / claims.size
    return "" if per_claim >= 2

    "\n> **One reading per claim is a sample, not a finding.** A category here is\n" \
      "> what a single reading said, and the framework holds a claim to a strict\n" \
      "> majority of repeated readings before it calls it typed.\n"
  end

  def coverage
    typed = claims.count { it.category.present? }
    <<~MD
      ## Coverage

      #{claims.size} substantive claims · #{typed} typed · #{claims.size - typed} untyped.

      A claim is untyped when its readings reached no majority, or when every
      reading abstained. An abstention is a reading and not a judgement, so the
      difference between "not asked" and "asked and could not tell" survives here.
    MD
  end

  def categories
    tally = claims.filter_map { it.category&.key }.tally
    untyped = claims.count { it.category.blank? }
    rows = tally.sort_by { -it.last }.map { |k, n| [ k, n, pct(n) ] }
    rows << [ "*(untyped)*", untyped, pct(untyped) ]

    <<~MD
      ## What the corpus is made of

      #{table(%w[category claims share], rows)}
    MD
  end

  # Every step that has a crossing, grouped by what this framework charges for
  # it. A step whose endpoints are unclassified has no crossing and is absent.
  def crossings
    rows = steps.filter_map do |step|
      reading = StepPremises.for(step, framework: framework)
      reading.crossing && [ reading.crossing, reading.weight ]
    end
    return nil if rows.empty?

    grouped = rows.group_by(&:first)
                  .map { |crossing, group| [ crossing, group.first[1], group.size ] }
                  .sort_by { |_, weight, count| [ -weight, -count ] }
    charged = rows.count { it[1].positive? }

    <<~MD
      ## Steps, by the premise their crossing declares

      #{table([ "crossing", "charge", "steps" ],
              grouped.map { |c, w, n| [ c, w.positive? ? "**#{w}**" : "free", n ] })}
      #{rows.size} steps with a crossing · #{charged} cross a charged boundary · #{rows.size - charged} free.

      A charge is what the framework says the move COSTS, declared in advance and
      independent of whether anything has ruled. #{unjudged_note}
    MD
  end

  def unjudged_note
    ruled = steps.count { StepPremises.for(it, framework: framework).judged? }
    return "Every step with a crossing has been ruled on." if ruled == steps.size

    "Of these, #{ruled} have been ruled on; the rest are undetermined, which is " \
      "the absence of a ruling said out loud rather than filled in."
  end

  # The whole point of a parameterised framework: where two traditions part
  # company, and nowhere else.
  def divergence
    return nil if comparators.empty?

    found = steps.filter_map do |step|
      spread = StepPremises.spread(step, frameworks: [ framework ] + comparators)
      next unless spread.crossing && spread.differ?

      [ step, spread ]
    end

    body =
      if found.empty?
        "No step in this corpus crosses a pair the traditions price differently."
      else
        found.map { |step, spread| divergent_step(step, spread) }.join("\n")
      end

    <<~MD
      ## Where the traditions part company

      #{body}
    MD
  end

  def divergent_step(step, spread)
    prices = spread.weights.map { |f, w| "#{f.key} #{w.nil? ? 'silent' : w}" }.join(" · ")
    <<~MD
      **#{step.document.title} #{step.from_claim.position}→#{step.to_claim.position}** — #{spread.crossing} — #{prices}

      > #{step.from_claim.text}
      >
      > #{step.to_claim.text}
    MD
  end

  # A premise can be read without a ruling, but nothing can be RULED while an
  # identity STOP stands. Reporting the charge without the lock would read as
  # though the corpus had been governed.
  def identity
    locked = documents.count { !it.executable? }
    stops = documents.sum { it.open_stops.count }
    notices = documents.sum { |d| d.flags.acting("flag").count { it.severity == "notice" } }

    <<~MD
      ## Identity, and what it blocks

      #{locked} of #{documents.size} documents are execution-locked · #{stops} open STOPs · #{notices} notices.

      A STOP blocks governance: nothing may be predicated of a name until somebody
      has said what it refers to. A notice does not — it marks a capital the
      document itself explains by position, which is proposed and visible but is
      not evidence that an unknown subject exists.
      #{stale_flags_note(notices)}
    MD
  end

  # A corpus ingested before the positional rule existed carries no notices at
  # all, and its STOP count is a figure about the older rule. Saying so is
  # cheaper than letting a reader compare it against a later one.
  def stale_flags_note(notices)
    return "" unless notices.zero?

    "\nNo notices appear here. Either every capital in this corpus is unexplained by\n" \
      "position, or these documents were ingested before that evidence was weighed —\n" \
      "re-ingest to tell the two apart."
  end

  def closing
    <<~MD
      ---

      **#{StepPremises::CAVEAT.capitalize}.** The charge above is what the
      framework declares for a move between two kinds of claim. What an author was
      protecting is a different question, and four designs across two scopes could
      not answer it from a found text — see ADR 24.
    MD
  end

  def pct(n) = claims.empty? ? "—" : "#{(100.0 * n / claims.size).round(1)}%"

  def table(headers, rows)
    [ "| #{headers.join(' | ')} |",
      "|#{headers.map { '---' }.join('|')}|",
      *rows.map { "| #{it.join(' | ')} |" } ].join("\n")
  end

  def revision
    out = `git rev-parse --short HEAD 2>/dev/null`.strip
    return "unknown" if out.empty?

    `git status --porcelain 2>/dev/null`.strip.empty? ? out : "#{out}-dirty"
  end
end
