# A profile of a document's epistemic structure, from the record.
#
# The product need is real: a person should be able to run this end to end and
# get something readable out, rather than reading assertion rows. This is that.
#
# --- Two rules that shape everything below ------------------------------------
#
# **The subject is the DOCUMENT.** Not its author. Every section here describes
# how a text is built — what kinds of claim it makes, where its steps were not
# earned, what those steps put first. "This author values X", "the subject
# demonstrates a coherent value system", "external correctability: low" are
# claims about a person, and this system holds no evidence for any of them.
# `StepValueJudge` was written so that the subject of a value reading is
# structurally a `Transition`; a report that attributed the same readings to a
# person would route around that guard at the presentation layer, which is
# where guards usually get lost.
#
# **Every section cites what it rests on, or does not render.** A template may
# only name sections that have a source in `SECTIONS`. Ask for one that does
# not and the render fails loudly rather than filling the gap with prose. That
# is the difference between a report and a plausible document: this one can be
# checked against the assertions behind it, line by line.
#
# Adding a section means building the measurement first. That is the intended
# cost, and it is why "symbolic density" and "narrative architecture" are not
# here — nothing in this system measures them, so nothing here can report them.
class ProfileReport
  # Named profiles. Data rather than code paths: a new profile is a list of
  # section keys, and every key is checked against SECTIONS before rendering.
  TEMPLATES = {
    "epistemic-structure" => %w[composition authority coverage steps commitments identity limits],
    "brief" => %w[composition steps limits],
    "governance" => %w[coverage steps identity limits]
  }.freeze

  # A table nobody can scroll is not more honest than a shorter one, but a table
  # that silently stops at ten reads as though ten were all there were.
  SHOWN = 10

  class UnknownTemplate < StandardError; end
  class UnsourcedSection < StandardError; end

  def self.render(document, template: "epistemic-structure")
    new(document, template: template).render
  end

  def self.templates = TEMPLATES.keys

  def initialize(document, template: "epistemic-structure")
    @document = document
    @template = template.to_s
    raise UnknownTemplate, "no template #{@template.inspect}" unless TEMPLATES.key?(@template)

    unsourced = TEMPLATES.fetch(@template) - SECTIONS.keys
    raise UnsourcedSection, "no source for #{unsourced.join(', ')}" if unsourced.any?
  end

  # Reflowed once, at the end, when every interpolated value is known. Wrapping
  # the source prose cannot get this right: a `#{}` expands to a different length
  # than the text around it suggested, and the line breaks land wherever the
  # figures happened to fall.
  def render
    sections = TEMPLATES.fetch(template).filter_map { send(SECTIONS.fetch(it)) }

    MarkdownReflow.call([ header, *sections ].join("\n\n"))
  end

  SECTIONS = {
    "composition" => :composition,
    "authority" => :authority,
    "coverage" => :coverage,
    "steps" => :steps,
    "commitments" => :commitments,
    "identity" => :identity,
    "limits" => :limits
  }.freeze

  private

  attr_reader :document, :template

  def claims = @claims ||= document.claims.substantive.to_a
  def typed = @typed ||= claims.select { it.category.present? }
  def transitions = @transitions ||= document.transitions.to_a
  def unearned = @unearned ||= transitions.select(&:unearned?)

  def value_readings
    @value_readings ||= transitions.flat_map do |t|
      t.assertions.standing.select { it.claim["inference"] == "step value" }
    end
  end

  def header
    <<~MD.strip
      # #{document.title.presence || "Document #{document.id}"}

      **Epistemic structure of a text · document #{document.id} · #{Time.current.to_date.to_fs(:long)}**

      *Generated from the recorded assertions — every figure below is a count over
      what is stored, and can be checked against it.*

      > **What this is about.** This describes a **document**: the kinds of claim it
      > makes, where its steps were not earned, and what those steps put first. It
      > is not about its author. Nothing here is a finding about a person, a
      > diagnosis, or an assessment of anyone's reasoning in general — the system
      > holds no evidence for those and this report will not imply them.
    MD
  end

  def composition
    return nil if typed.empty?

    counts = typed.filter_map { it.category&.name }.tally.sort_by { -it.last }
    rows = counts.map { |name, n| "| #{name} | #{n} | #{(n * 100.0 / typed.size).round(1)}% |" }

    <<~MD.strip
      ## What kinds of claim it makes

      | Category | Claims | Share |
      |---|---|---|
      #{rows.join("\n")}

      #{typed.size} of #{claims.size} substantive claims are typed. Each was typed by
      repeated reading, and a claim's category is what a strict majority of those
      readings agreed on — a claim with no majority is left untyped rather than
      assigned whichever reading came last.
    MD
  end

  # The measurable form of "where does this text rest its claims". Observation
  # against objective is a real signal: across three documents in this record it
  # ran 39.4% in a personal letter, 22.8% in an essay, 1.9% in a chapter of
  # theory. It says nothing about whether the claims are true.
  def authority
    return nil if typed.empty?

    share = ->(key) { (typed.count { it.category&.key == key } * 100.0 / typed.size).round(1) }
    first_person = share.call("observation")
    checkable = share.call("objective")

    <<~MD.strip
      ## Where its claims rest

      | | |
      |---|---|
      | first-person report (*observation*) | #{first_person}% |
      | publicly checkable (*objective*) | #{checkable}% |
      | meaning assigned (*interpretive*) | #{share.call('interpretive')}% |
      | about what exists (*ontological*) | #{share.call('ontological')}% |
      | about what ought to be (*normative*) | #{share.call('normative')}% |

      #{authority_note(first_person, checkable)}
    MD
  end

  def authority_note(first_person, checkable)
    if first_person > checkable * 1.5
      "This text rests more on what was experienced than on what is externally " \
        "checkable. That is ordinary in a letter or a memoir and says nothing about " \
        "whether the claims hold — only about what kind of warrant they offer."
    elsif checkable > first_person * 1.5
      "This text rests more on externally checkable claims than on first-person " \
        "report."
    else
      "First-person report and externally checkable claim are present in similar " \
        "measure."
    end
  end

  def coverage
    unread = claims.count { it.machine_agreement.readings.zero? }
    unstable = claims.count { (1..2).cover?(it.machine_agreement.readings) }
    return nil if claims.empty?

    <<~MD.strip
      ## What the reading could not settle

      | | |
      |---|---|
      | claims typed | #{typed.size} of #{claims.size} |
      | no reading at all | #{unread} |
      | read unstably (1 or 2 of 3) | #{unstable} |
      | steps judged | #{transitions.count { it.verdict.to_s != 'undetermined' }} of #{transitions.size} |

      A claim the classifier declined every time is usually not a claim — a heading,
      a fragment, a line of a table. An unstably read one is a claim it typed
      differently on different readings, which is a fact about the difficulty of the
      sentence as much as about the reader.
    MD
  end

  def steps
    return nil if transitions.empty?

    by_move = unearned.group_by { "#{it.source.category&.key} → #{it.target.category&.key}" }
                      .sort_by { -it.last.size }
    rows = by_move.map { |move, list| "| #{move} | #{list.size} |" }

    <<~MD.strip
      ## Where a step claimed more than the one before it supported

      #{unearned.size} of #{transitions.size} steps were judged **unearned** — the
      second claim asserts something the first does not carry. A verdict is about the
      move between two claims and not about either claim on its own.

      | Move | Steps |
      |---|---|
      #{rows.join("\n")}

      What a move costs is set by the framework, not by this report: a lateral move
      between two kinds of equal warrant costs nothing, and a retreat to firmer
      ground costs nothing. Only a promotion does.
    MD
  end

  # The weakest section, and it says so with a number rather than a hedge.
  def commitments
    return nil if value_readings.empty?

    shown = value_readings.sort_by { -it.claim["confidence"].to_f }.first(SHOWN)
    rows = shown.map { "| #{it.claim['move']} | #{it.claim['protects']} | #{it.claim['subordinates']} |" }
    truncation = if value_readings.size > shown.size
                   "\n\nShowing #{shown.size} of #{value_readings.size}, highest confidence first. " \
                     "The rest are in the record."
    else
                   ""
    end

    <<~MD.strip
      ## What the unearned steps put first

      Read at #{value_readings.size} of the #{unearned.size} unearned steps. Each row
      is a claim about **that step**, not about whoever wrote it.

      | Move | Puts first | Sets aside |
      |---|---|---|
      #{rows.join("\n")}#{truncation}

      > **This section does not currently distinguish signal from noise, and here
      > are the numbers.** Presented with claim pairs from unrelated parts of a
      > document — no argumentative relation at all — the judge produced a confident
      > reading **67.9%** of the time, against **71.4%** on real steps. That gap is
      > 0.29 standard errors: indistinguishable from none. An earlier version with an
      > open vocabulary did discriminate (92.9% against 60.7%, 3.08 standard errors)
      > while inventing three times in five; closing the vocabulary bought abstention
      > on real steps and lost the discrimination.
      >
      > So treat these rows as prompts for a person to look at the step themselves,
      > not as findings. Their confidence carries no information — it is 0.9 to 1.0
      > in both arms. Recorded in baseline v3.
    MD
  end

  def identity
    names = document.mentions.map(&:text).uniq
    return nil if names.empty?

    resolutions = document.mentions.flat_map { it.assertions.standing.select { |x| x.act == "resolve" } }
    inferred = resolutions.count(&:inferred?)

    <<~MD.strip
      ## Who and what it names

      #{names.size} distinct names, #{document.open_stops.count} still unanswered.
      #{inferred} of #{resolutions.size} answers were **inferred by an agent** rather
      than decided by a person, and are marked as such in the record.

      Nothing may be predicated of a name until somebody has said what it refers to.
      That lock guards predication, not description: a claim can be typed while its
      names are unresolved, but no step through it can be judged.
    MD
  end

  # Generated rather than written, so it cannot drift from what is actually true
  # of this document.
  def limits
    <<~MD.strip
      ## What this report cannot tell you

      - **Whether any of it is true.** Every figure here is the system's reading of a
        text. Nothing has compared those readings to a person's, so this describes
        how the document is built, never whether it is right.
      - **Anything about the author.** The subject throughout is the document. No
        section attributes a belief, a value, a trait or a tendency to a person, and
        the record contains no assertion that would support one.
      - **How stable these figures are.** Read the same document again and some
        would move: the classifier reproduces itself about 88% of the time, and
        roughly #{unstable_share}% of this document's claims were read differently on
        different passes.
      - **What it did not look for.** This reports what the framework measures.
        Anything it does not measure is absent rather than absent-of-evidence.
    MD
  end

  def unstable_share
    return 0 if claims.empty?

    (claims.count { (1..2).cover?(it.machine_agreement.readings) } * 100.0 / claims.size).round
  end
end
