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
    "epistemic-structure" => %w[composition authority coverage steps premises commitments identity limits],
    "brief" => %w[composition steps limits],
    "governance" => %w[coverage steps premises identity limits]
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
    "premises" => :premises,
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

  def framework = @framework ||= Framework.current!

  # Frameworks other than the current one that have ruled on this document.
  def rival_frameworks
    @rival_frameworks ||= transitions.flat_map { it.frameworks_ruling }.uniq - [ framework ]
  end

  def ruled_count(of) = transitions.count { it.verdict(framework: of) != "undetermined" }

  # Contested and unstable are different failures and are never merged. Two
  # judges disagreeing is disagreement; one judge changing its own answer is
  # drift, which says something about the instrument rather than the step.
  def contested = @contested ||= transitions.select(&:contested?)
  def unstable = @unstable ||= transitions.select(&:unstable?)

  def disagreement_note
    parts = []
    if contested.any?
      parts << "**#{contested.size} #{contested.size == 1 ? 'step is' : 'steps are'} contested** — two " \
               "judges reached different conclusions under these same premises, and no verdict is " \
               "reported for #{contested.size == 1 ? 'it' : 'them'} because there is no ground here " \
               "for choosing between them"
    end
    if unstable.any?
      parts << "#{unstable.size} #{unstable.size == 1 ? 'was' : 'were'} ruled on more than once by the " \
               "same judge with different answers, which is drift rather than disagreement — the " \
               "latest stands and the earlier is still in the record"
    end
    return "" if parts.empty?

    "#{parts.to_sentence.upcase_first}."
  end

  def divergence_detail
    moves = rival_frameworks.flat_map do |rival|
      transitions.select { it.verdict(framework: rival) != it.verdict(framework: framework) }
                 .map { "#{it.source.category&.key} → #{it.target.category&.key}" }
    end
    return "The frameworks agreed on every step in this document." if moves.empty?

    tally = moves.tally.sort_by { -it.last }
    "The disagreement is confined to #{tally.size == 1 ? 'one kind of move' : 'these moves'}: " \
      "#{tally.map { |move, n| "**#{move}** (#{n})" }.to_sentence}. That localisation is itself " \
      "the finding — a change of premise moved the verdicts it should have moved and nothing else."
  end

  # A reading a person rejected is still standing — a disposal is recorded beside
  # a judgement, never over it — so nothing filters it out unless this does.
  # Rendering one as though it had survived review would be the report saying the
  # opposite of what the record says.
  def value_readings
    @value_readings ||= transitions.flat_map do |t|
      t.assertions.standing.select { it.claim["inference"] == "step value" }
    end
  end

  def reviewed = @reviewed ||= value_readings.select { it.disposition == "accepted" }
  def rejected = @rejected ||= value_readings.select { it.disposition == "rejected" }
  def unreviewed = @unreviewed ||= value_readings.select { it.disposition == "open" }

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
      | two readers disagreed | #{contested_claims.size} |
      | steps judged | #{transitions.count { it.verdict.to_s != 'undetermined' }} of #{transitions.size} |

      A claim the classifier declined every time is usually not a claim — a heading,
      a fragment, a line of a table. An unstably read one is a claim it typed
      differently on different readings, which is a fact about the difficulty of the
      sentence as much as about the reader.
      #{contested_claims_note}
    MD
  end

  def contested_claims = @contested_claims ||= claims.select(&:contested?)

  def contested_claims_note
    return "" if contested_claims.empty?

    "A **disagreed** one is different from both: two people read it and named " \
      "different categories, so it is left untyped rather than typed by whoever " \
      "read last. Nothing resolves that by showing either of them the other's " \
      "answer — what settles it is a further independent reading."
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

      **These verdicts are #{framework.name}'s**, not the record's — every figure in
      this section is what one set of premises concluded. #{disagreement_note}
    MD
  end

  # Renders only when more than one framework has actually ruled here, which is
  # the honest condition: a document judged under one set of premises has no
  # disagreement to report, and a section saying "none found" would imply a
  # comparison nobody ran.
  #
  # This is the section the architecture was rebuilt to make possible. Before a
  # ruling named its framework, a second premise's verdicts were
  # indistinguishable from the first premise's sentinel changing its mind, so
  # the Lewisian run was computed and thrown away — `persisted: false` in
  # baseline v3. Both now stand, and where they part is a fact about the
  # premises rather than about the text.
  def premises
    return nil if rival_frameworks.empty?

    rows = rival_frameworks.map do |rival|
      differing = transitions.select { it.verdict(framework: rival) != it.verdict(framework: framework) }
      "| #{rival.name} | #{ruled_count(rival)} | #{differing.size} |"
    end

    <<~MD.strip
      ## Where different premises reach different verdicts

      Every step here has been judged under more than one framework. The verdicts
      **coexist** — neither overwrites the other, and this section reports the
      disagreement rather than resolving it.

      | Framework | Steps ruled on | Verdicts differing from #{framework.name} |
      |---|---|---|
      | #{framework.name} *(current)* | #{ruled_count(framework)} | — |
      #{rows.join("\n")}

      #{divergence_detail}

      > A difference here is a fact about the **premises**, not about the text. Two
      > frameworks disagreeing does not mean one of them read the document wrong; it
      > means they charge different prices for the same move, which is what having a
      > moral premise consists of. Nothing in this system adjudicates between them,
      > and nothing here should be read as ranking them.
    MD
  end

  # The weakest section, and it says so with a number rather than a hedge.
  #
  # Ordered by what a person has done with each reading rather than by the
  # judge's confidence, because the confidence carries no information and a
  # person's disposal is the only filter measured to work. Rejected readings do
  # not appear at all: they stay in the record, and a report is not the record.
  def commitments
    candidates = reviewed + unreviewed
    return nil if candidates.empty?

    shown = candidates.first(SHOWN)
    rows = shown.map do |a|
      mark = reviewed.include?(a) ? "**let stand**" : "unreviewed"
      "| #{a.claim['move']} | #{a.claim['protects']} | #{a.claim['subordinates']} | #{mark} |"
    end
    truncation = if candidates.size > shown.size
                   "\n\nShowing #{shown.size} of #{candidates.size}, reviewed first. " \
                     "The rest are in the record."
    else
                   ""
    end

    <<~MD.strip
      ## What the unearned steps put first

      Read at #{value_readings.size} of the #{unearned.size} unearned steps.
      #{review_state} Each row is a claim about **that step**, not about whoever
      wrote it.

      | Move | Puts first | Sets aside | |
      |---|---|---|---|
      #{rows.join("\n")}#{truncation}

      > **A row that was let stand and a row nobody has looked at are not the same
      > kind of thing.** A person read the first against the two claims it was drawn
      > from and let it stand. Nothing has been established about the second beyond a
      > judge saying it, and that judge is described directly below.
      >
      > **This section does not distinguish signal from noise, and three attempts to
      > make it have failed.** Given claim pairs from unrelated parts of a document —
      > no argumentative relation at all — it treats them almost exactly as it treats
      > real steps. An open vocabulary discriminated at 3.08 standard errors while
      > inventing a commitment three times in five; closing the vocabulary to sixteen
      > values gave 0.29; requiring a conflict to be established first gave 0.54. The
      > only version that told real from random is the one that invented most.
      >
      > The reason appears to be that the question has no ground truth in a found
      > text, which is not something an architecture can supply. So treat an
      > unreviewed row as a **prompt for a person to look at the step themselves**,
      > never as a finding, and do not read anything into its confidence — it is 0.9
      > to 1.0 whatever is shown. Recorded in baseline v3.
    MD
  end

  # Stated in the section rather than left to the marks in the table, because a
  # reader who skims will take a count at face value.
  def review_state
    was = ->(n) { n == 1 ? "was" : "were" }
    parts = []
    parts << "#{reviewed.size} #{was.call(reviewed.size)} reviewed and let stand" if reviewed.any?
    parts << "#{rejected.size} #{was.call(rejected.size)} rejected by a reviewer and " \
             "#{rejected.size == 1 ? 'is' : 'are'} not shown" if rejected.any?
    parts << "#{unreviewed.size} #{unreviewed.size == 1 ? 'has' : 'have'} not been looked at" if
      unreviewed.any?
    return "" if parts.empty?

    "Of those, #{parts.to_sentence}."
  end

  def identity
    names = document.mentions.map(&:text).uniq
    return nil if names.empty?

    resolutions = document.mentions.flat_map { it.assertions.standing.select { |x| x.act == "resolve" } }
    # Three states, not two. Every resolution used to be asserted by the Sentinel
    # whoever actually decided it, so this line reported "N of N inferred" and
    # could report nothing else however many names a person grounded by hand.
    matched = resolutions.select { it.claim["grounded"] == false }
    grounded = resolutions.select { it.claim["grounded"] == true }
    unattributed = resolutions.reject { it.claim.key?("grounded") }

    <<~MD.strip
      ## Who and what it names

      #{names.size} distinct names, #{document.open_stops.count} still unanswered.
      #{identity_note(matched, grounded, unattributed)}

      Nothing may be predicated of a name until somebody has said what it refers to.
      That lock guards predication, not description: a claim can be typed while its
      names are unresolved, but no step through it can be judged.
    MD
  end

  # Who answered, rather than what the answer was. A name matched automatically
  # and a name somebody was asked about are different kinds of fact, and an agent
  # grounding under delegation is neither the Sentinel nor a person.
  def identity_note(matched, grounded, unattributed)
    total = matched.size + grounded.size + unattributed.size
    return "No name here has been answered yet." if total.zero?

    was = ->(n) { n == 1 ? "was" : "were" }
    parts = []
    parts << "#{matched.size} #{was.call(matched.size)} **matched by the resolver** without " \
             "anyone being asked" if matched.any?
    people, agents = grounded.partition { !it.inferred? }
    parts << "#{people.size} #{was.call(people.size)} **grounded by a person** answering a " \
             "STOP" if people.any?
    parts << "#{agents.size} #{was.call(agents.size)} **grounded by an agent** acting under " \
             "delegation" if agents.any?
    parts << "#{unattributed.size} #{was.call(unattributed.size)} recorded before resolutions " \
             "named their decider, so whether anyone was asked is not in the record" if
      unattributed.any?

    "Of #{total} answers, #{parts.to_sentence}. Nothing may be predicated of a name " \
      "until somebody has answered for it."
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
