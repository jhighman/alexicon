# One individually classifiable statement within a document.
class Claim < ApplicationRecord
  belongs_to :document

  # Part of the document, but not a claim about anything: a heading, a section
  # marker. Kept in the record and still rendered — marking is not hiding.
  scope :substantive, -> { where(structural: false) }
  has_many :mentions, dependent: :destroy

  # Classifications are assertions about this claim. NOT dependent: :destroy --
  # a judgement is immutable historical record.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  has_many :outgoing_transitions, class_name: "Transition", as: :source,
           dependent: :restrict_with_error
  has_many :incoming_transitions, class_name: "Transition", as: :target,
           dependent: :restrict_with_error

  validates :text, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }

  def classifications = assertions.acting("classify").standing.chronological

  # What repeated readings of this claim agreed on.
  #
  # A single reading was measured at 88% reproducible overall and 84.5% on the
  # interpretive/ontological pair, and re-running a whole document changed half
  # the steps it flagged. So one machine reading is a sample, not a finding, and
  # `agreement` is what says which of the two you are looking at.
  #
  # No majority means no category. If three readings disagree three ways, the
  # honest state is that the system does not know -- which is what abstention
  # already means everywhere else here, and is better than reporting whichever
  # reading happened to be last.
  Agreement = Data.define(:category, :agreeing, :readings) do
    def decided? = category.present?
    def rate = readings.zero? ? nil : (agreeing.to_f / readings).round(3)
    def single? = readings == 1
    def unanimous? = decided? && agreeing == readings

    # "2 of 3" says more than "67%", and "1 of 1" says what a rate would hide.
    def to_s
      return "no reading" if readings.zero?
      return "#{readings} readings, no majority" unless decided?

      "#{agreeing} of #{readings}"
    end
  end

  # The live classification. A person's judgement wins over a system's, but the
  # system's is retained rather than overwritten -- the framework's own axiom
  # applied to its own output.
  def classification
    candidates = classifications.includes(:asserter).to_a
    people = human_agreement(candidates)
    # Once a person has read it the machine no longer speaks — including when the
    # people are split. Falling back there would type the claim by machine
    # majority while `agreement` reported no majority at all, so `category` and
    # the figure explaining it would disagree.
    if people.readings.positive?
      return people.category && candidates.reverse.find { it.human? && it.object == people.category }
    end

    # Among machine readings, the one that agrees with the majority. Any of them
    # will do as the representative: they name the same category.
    decided = machine_agreement(candidates).category
    decided && candidates.reverse.find { it.object == decided }
  end

  def category = classification&.object

  # How firmly this claim is typed, and on how many readings.
  def agreement
    candidates = classifications.includes(:asserter).to_a
    people = human_agreement(candidates)
    # A person's judgement is not a vote among the machine's; it settles the
    # question. It is not exempt from being disagreed with by another person.
    return people if people.readings.positive?

    machine_agreement(candidates)
  end

  # What the PEOPLE who read this claim concluded — one position each, latest,
  # and the same strict majority the machine's readings are held to.
  #
  # This took the last human reading and reported it as `1 of 1`. Two people
  # reading the same claim and disagreeing produced whichever went second, with
  # a sample size that said only one person had read it at all: the disagreement
  # discarded and the fact that it happened erased along with it.
  #
  # No majority now leaves the claim untyped, exactly as it does for the
  # machine. That is not a new rule, it is the existing one finally applied to
  # people — a claim two readers cannot agree on is not typed by picking one.
  #
  # An abstention is a reading but not a judgement: somebody recording that they
  # could not tell leaves whatever the machine agreed on standing rather than
  # blanking it, so readings with no object are not counted here.
  def human_agreement(candidates = classifications.includes(:asserter).to_a)
    positions = candidates.select { it.human? && it.object }
                          .group_by(&:asserter_id).transform_values(&:last)

    agreement_among(positions.values)
  end

  # Two people read this claim and named different categories. Not resolvable by
  # showing either of them the other's answer — see `Review`, which never serves
  # a claim classification. What settles it is a further independent reading.
  def contested?
    people = human_agreement
    people.readings > 1 && people.category.nil?
  end

  # What the classification pass concluded, ignoring every third-party reading.
  #
  # `agreement` prefers a person's reading, which is right everywhere except one
  # place: when that person's reading is the thing being compared AGAINST. There,
  # asking `agreement` returns their own answer and the comparison agrees with
  # itself 100% of the time.
  #
  # Blind readings are excluded. A second judge polled for comparison is not a
  # further vote in the first judge's tally — see `agreement_by`.
  def machine_agreement(candidates = classifications.includes(:asserter).to_a)
    agreement_among(candidates.reject { it.human? || it.blind? })
  end

  # What ONE reader's repeated readings agreed on.
  #
  # Readings by different judges are never tallied together. "2 of 3" means the
  # same judge asked three times; merging a second model's readings into the
  # first model's majority would be two instruments reported as one measurement,
  # which is the error this framework exists to catch, committed against itself.
  # So a third party polled through the API is recorded and does not move
  # `category`.
  def agreement_by(referent, candidates = classifications.includes(:asserter).to_a)
    agreement_among(candidates.select { it.asserter_id == referent&.id })
  end

  private

  # Strict majority: more than half the readings must name the same category.
  # A plurality would let 2 of 5 decide, which is not agreement.
  def agreement_among(readings)
    objects = readings.filter_map(&:object)
    return Agreement.new(category: nil, agreeing: 0, readings: 0) if objects.empty?

    winner, count = objects.tally.max_by { it.last }
    decided = count * 2 > objects.size

    Agreement.new(category: decided ? winner : nil, agreeing: count, readings: objects.size)
  end

  public

  # Records a classification as an accountable assertion.
  # `invocation` links the judgement to the call that produced it. One call can
  # now carry a batch, so the link lives here rather than on the invocation.
  # `blind` marks a reading taken WITHOUT sight of any other — the independent
  # second opinion the comparison is made of. It is recorded in full and does
  # not join the classification tally.
  def classify!(category, asserter:, confidence: nil, rationale: nil, supersedes: nil,
                invocation: nil, blind: false)
    payload = {}
    payload["confidence"] = confidence if confidence
    payload["rationale"] = rationale if rationale
    payload["blind"] = true if blind

    assertions.create!(asserter: asserter, act: "classify", object: category,
                       claim: payload, supersedes: supersedes, llm_invocation: invocation)
  end

  # A reading that reached no category. The model records nothing when it
  # declines, which leaves "not asked" and "asked and could not tell" looking
  # identical; when a person declines, the difference is the whole point, so it
  # is written down. It counts as a reading and not as a judgement.
  def abstain!(asserter:, rationale: nil, blind: false)
    payload = { "abstained" => true }
    payload["rationale"] = rationale if rationale
    payload["blind"] = true if blind

    assertions.create!(asserter: asserter, act: "classify", object: nil, claim: payload)
  end
end
