# The premise that produced a step's verdict, read back rather than inferred.
#
# Four designs across two scopes could not tell a real argumentative step from a
# pair that was never an argument, so asking a model what a step protects is
# retired pending the person-scoped control. This asks a different question that
# the record can already answer:
#
#   Under what commitment was this step judged, and what would another
#   tradition have charged for the same move?
#
# The answer is exact. `CategoryPromotion` declares the weight and the reason,
# the framework is stamped on the ruling by ADR 18, and nothing here calls a
# model or writes anything. See ADR 24.
#
# THE CAVEAT IS PART OF THE OUTPUT. This gives the commitment a step was judged
# UNDER, never the commitment its author was protecting. Those are different
# claims, and a report that prints the first as the second has smuggled the
# failed inference back in with better provenance.
class StepPremises
  CAVEAT = "the commitment this step was judged under, not the one its author held".freeze

  Reading = Data.define(:transition, :framework, :charge, :verdict, :decisive) do
    def crossing = charge&.crossing
    def weight = charge&.weight
    def rationale = charge&.rationale
    def caveat = CAVEAT

    # A verdict was actually reached. `undetermined` is not one: it is the
    # absence of a ruling, said out loud rather than filled in, and a reading
    # that counted it as judged would report a premise as having settled
    # something nobody has looked at. `contested` is not one either — there,
    # two asserters disagreed UNDER the same premise, so the premise is
    # precisely what did not settle it.
    def judged? = %w[earned unearned].include?(verdict)

    # Whether the weight is what settled it. A verdict of `unearned` on a
    # positive weight rests on the charge; `earned` on a zero weight rests on
    # its absence; anything else was settled by something other than the premise
    # — an unclassified endpoint, a framework that never spoke about the pair.
    def premised? = judged? && !charge.nil?
  end

  # What every tradition says about the same move, whether or not it has ruled.
  #
  # A framework that has not ruled still has a position, because the weight is
  # declared in advance. That is the whole point: the counterfactual is readable
  # without buying a second reading.
  Spread = Data.define(:transition, :from_key, :to_key, :positions) do
    def crossing = from_key && to_key ? "#{from_key} → #{to_key}" : nil
    def caveat = CAVEAT

    def weights = positions.transform_values { it.weight }
    def differ? = weights.values.compact.uniq.size > 1

    # Frameworks that would charge nothing for a move another charges for.
    def permissive = positions.select { |_, p| p.weight&.zero? }.keys
  end

  Position = Data.define(:framework, :weight, :rationale, :ruled, :verdict) do
    def silent? = weight.nil?
  end

  def self.for(transition, framework: Framework.current_or_none)
    new(transition).reading(framework)
  end

  def self.spread(transition, frameworks: Framework.all.to_a)
    new(transition).spread(frameworks)
  end

  def initialize(transition)
    @transition = transition
  end

  def reading(framework)
    from_key, to_key = crossing_keys
    charge = from_key && framework ? FrameworkPremises.for(framework).charge(from_key, to_key) : nil
    # Kept as recorded, including `contested`, which is deliberately outside
    # `VERDICTS` so no sentinel can assert it. Nulling it would hide the one
    # state that says the premise did not settle the question.
    verdict = transition.verdict(framework: framework)

    Reading.new(transition: transition, framework: framework, charge: charge,
                verdict: verdict, decisive: decisive?(charge, verdict))
  end

  def spread(frameworks)
    from_key, to_key = crossing_keys

    positions = frameworks.index_with do |framework|
      charge = from_key ? FrameworkPremises.for(framework).charge(from_key, to_key) : nil
      Position.new(framework: framework, weight: charge&.weight, rationale: charge&.rationale,
                   ruled: transition.rulings(framework: framework).any?,
                   verdict: transition.verdict(framework: framework))
    end

    Spread.new(transition: transition, from_key: from_key, to_key: to_key, positions: positions)
  end

  private

  attr_reader :transition

  # Read from the claims' standing categories rather than from the ruling, so a
  # step nobody has judged still has a crossing and a declared cost. The premise
  # exists before the verdict does.
  def crossing_keys
    from = transition.from_claim&.category
    to = transition.to_claim&.category
    return [ nil, nil ] if from.blank? || to.blank?

    [ from.key, to.key ]
  end

  def decisive?(charge, verdict)
    return false if charge.nil? || verdict.nil?

    (verdict == "unearned" && charge.weight.positive?) ||
      (verdict == "earned" && charge.weight.zero?)
  end
end
