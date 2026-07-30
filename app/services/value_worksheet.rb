# A blind worksheet that measures whether a PERSON can do what the value layer
# could not.
#
# Three architectural repairs failed. Open vocabulary discriminated real steps
# from unrelated pairs at 3.08 standard errors while inventing a commitment three
# times in five; closing the vocabulary to sixteen values gave 0.29; requiring a
# conflict to be established first gave 0.54. The recorded diagnosis was that the
# question has no ground truth in a found text — Alexandra Krížová's probe
# CONSTRUCTS a conflict, so her judge rules on a dilemma known to exist, and a
# step found in a letter has no such construction.
#
# That diagnosis has never been tested. It says the QUESTION is ungrounded, and
# the only evidence for it is that three models failed to answer it. Those are
# different claims: a question a model cannot answer may still be one a person
# can. Nobody has been asked.
#
# So this is the control that was never run, with the machine taken out of it.
# Real unearned steps are interleaved with SHUFFLED pairs — two claims from the
# same document with no argumentative relation, matched on category pair and at
# least twenty positions apart, which is exactly the decoy condition the three
# machine runs were scored against. The reader is not told which is which.
#
# The statistic is therefore directly comparable to 3.08, 0.29 and 0.54, and it
# decides something an architecture cannot:
#
#   * A person who discriminates well says the question has ground truth in the
#     text and the machine is what failed. The layer is a model problem.
#   * A person who cannot discriminate either says the question is ungrounded, as
#     recorded. The layer should be retired, and that would be the first evidence
#     for retiring it that is not itself a model's failure.
#
# It shows no machine reading of any pair. A worksheet that displayed what the
# judge concluded would measure agreement with the judge, which is not the
# question and is the same trap `BlindReading` exists to avoid.
class ValueWorksheet
  # Matching the recorded control conditions, so the figure is comparable.
  SEPARATION = 20
  KIND = "value-discrimination".freeze

  class NotEnoughSteps < StandardError; end
  class NotAWorksheet < StandardError; end

  Item = Data.define(:number, :first, :second, :move, :real, :transition_id) do
    def real? = real
  end

  Sheet = Data.define(:document, :items, :assertion, :seed) do
    def real_items = items.select(&:real?)
    def decoys = items.reject(&:real?)
  end

  Score = Data.define(:real_found, :real_total, :decoy_found, :decoy_total, :answered) do
    def real_rate = real_total.zero? ? 0.0 : real_found.fdiv(real_total)
    def decoy_rate = decoy_total.zero? ? 0.0 : decoy_found.fdiv(decoy_total)
    def difference = real_rate - decoy_rate

    # Pooled two-proportion z, the same statistic the three machine runs were
    # scored with. Zero when nothing varies, rather than dividing by zero.
    def standard_errors
      pooled = (real_found + decoy_found).fdiv(real_total + decoy_total)
      spread = pooled * (1 - pooled) * (1.0 / real_total + 1.0 / decoy_total)
      return 0.0 if spread <= 0

      (difference / Math.sqrt(spread)).round(2)
    end
  end

  def self.generate!(document, size: 24, seed: 1)
    new(document, size: size, seed: seed).generate!
  end

  def initialize(document, size: 24, seed: 1)
    @document = document
    @size = size
    @random = Random.new(seed)
    @seed = seed
  end

  # Half real, half decoy, interleaved by the seeded shuffle. The assignment is
  # recorded as an assertion so the sheet can be scored later by somebody who
  # never saw which was which — including the person who filled it in.
  def generate!
    unearned = document.transitions.select(&:unearned?)
    wanted = [ size / 2, unearned.size ].min
    raise NotEnoughSteps, "no unearned steps in document #{document.id}" if wanted.zero?

    real = unearned.sample(wanted, random: random)
    items = numbered(real.map { real_item(it) } + real.filter_map { decoy_item(it) })

    Sheet.new(document: document, items: items, seed: seed, assertion: record!(items))
  end

  # Scored from the recorded key, so a sheet is worth nothing without one and
  # cannot be scored against a key invented afterwards.
  #
  # `answers` maps an item number to whether the reader found a conflict. An
  # unanswered item is dropped from both arms rather than counted as "no": a
  # blank is not a judgement, and treating it as one would flatter any reader who
  # skipped the hard ones.
  def self.score(assertion, answers:)
    raise NotAWorksheet, "assertion #{assertion.id} is not a worksheet" unless
      assertion.claim["worksheet"] == KIND

    key = assertion.claim.fetch("items").to_h { [ it["number"], it["real"] ] }
    given = answers.slice(*key.keys)
    real, decoy = given.partition { |number, _| key[number] }

    Score.new(real_found: real.count { it.last }, real_total: real.size,
              decoy_found: decoy.count { it.last }, decoy_total: decoy.size,
              answered: given.size)
  end

  private

  attr_reader :document, :size, :random, :seed

  def numbered(items)
    items.shuffle(random: random).each_with_index.map do |item, index|
      Item.new(**item.to_h, number: index + 1)
    end
  end

  def real_item(transition)
    Item.new(number: 0, first: transition.from_claim.text, second: transition.to_claim.text,
             move: move_of(transition), real: true, transition_id: transition.id)
  end

  # A pair the document never argued: same categories, far apart, no relation.
  # nil when the document has no such pair, which is a fact about a short
  # document rather than an error — the arms simply come out uneven and the
  # figure accounts for it.
  def decoy_item(transition)
    from, to = [ transition.from_claim, transition.to_claim ]
    partner = document.claims.substantive.to_a.select do |c|
      c.category == to.category && (c.position - from.position).abs >= SEPARATION
    end.sample(random: random)
    return nil if partner.nil?

    Item.new(number: 0, first: from.text, second: partner.text,
             move: move_of(transition), real: false, transition_id: nil)
  end

  def move_of(transition)
    "#{transition.from_claim.category&.key} → #{transition.to_claim.category&.key}"
  end

  # The key, recorded before anybody answers. Attributed to the sentinel that
  # flagged the steps, because the sheet is built entirely from its verdicts.
  def record!(items)
    Assertion.create!(
      asserter: Referent.sentinel_for("governance"),
      subject: document,
      act: "assert",
      claim: {
        "worksheet" => KIND, "seed" => seed,
        "items" => items.map { { "number" => it.number, "real" => it.real,
                                 "transition" => it.transition_id } }
      }
    )
  end
end
