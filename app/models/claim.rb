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
    human = candidates.select { it.human? && it.object }.last
    return human if human

    # Among machine readings, the one that agrees with the majority. Any of them
    # will do as the representative: they name the same category.
    decided = machine_agreement(candidates).category
    decided && candidates.reverse.find { it.object == decided }
  end

  def category = classification&.object

  # How firmly this claim is typed, and on how many readings.
  def agreement
    candidates = classifications.includes(:asserter).to_a
    # An abstention is a reading, but it is not a judgement: a person saying
    # "I cannot tell" records that they could not, and leaves whatever the
    # machine agreed on standing rather than blanking it.
    human = candidates.select { it.human? && it.object }.last
    # A person's judgement is not a vote among others; it settles the question.
    return Agreement.new(category: human.object, agreeing: 1, readings: 1) if human

    machine_agreement(candidates)
  end

  # What the MACHINE readings alone agreed on, ignoring any human judgement.
  #
  # `agreement` prefers a person's reading, which is right everywhere except one
  # place: when the person's reading is the thing being compared AGAINST. There,
  # asking `agreement` returns the human's own answer and the comparison agrees
  # with itself 100% of the time.
  #
  # Strict majority: more than half the readings must name the same category.
  # A plurality would let 2 of 5 decide, which is not agreement.
  def machine_agreement(candidates = classifications.includes(:asserter).to_a)
    objects = candidates.reject(&:human?).filter_map(&:object)
    return Agreement.new(category: nil, agreeing: 0, readings: 0) if objects.empty?

    winner, count = objects.tally.max_by { it.last }
    decided = count * 2 > objects.size

    Agreement.new(category: decided ? winner : nil, agreeing: count, readings: objects.size)
  end

  # Records a classification as an accountable assertion.
  # `invocation` links the judgement to the call that produced it. One call can
  # now carry a batch, so the link lives here rather than on the invocation.
  def classify!(category, asserter:, confidence: nil, rationale: nil, supersedes: nil,
                invocation: nil)
    payload = {}
    payload["confidence"] = confidence if confidence
    payload["rationale"] = rationale if rationale

    assertions.create!(asserter: asserter, act: "classify", object: category,
                       claim: payload, supersedes: supersedes, llm_invocation: invocation)
  end

  # A reading that reached no category. The model records nothing when it
  # declines, which leaves "not asked" and "asked and could not tell" looking
  # identical; when a person declines, the difference is the whole point, so it
  # is written down. It counts as a reading and not as a judgement.
  def abstain!(asserter:, rationale: nil)
    payload = { "abstained" => true }
    payload["rationale"] = rationale if rationale

    assertions.create!(asserter: asserter, act: "classify", object: nil, claim: payload)
  end
end
