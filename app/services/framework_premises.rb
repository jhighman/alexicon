# What a framework charges for a crossing, and what that commits it to.
#
# The value content of a judgement is not inferred from the text it judged. It
# is already declared: `ontological -> normative = 2` with the rationale "Hume's
# crossing: what exists does not settle what should be done" IS a value
# commitment, versioned as framework data and stamped onto every ruling by
# ADR 18. This reads it back ([ADR 24](../../docs/decisions/0024-values-attach-through-premises.md)).
#
# Nothing here calls a model, and nothing is stored. Every figure is derived
# from `CategoryPromotion`, which is a seed.
#
# What this DOES NOT give: the value a particular author was protecting. It
# gives the commitment under which their step was judged. Those are different
# claims, and `Reading#caveat` exists so no report can quietly print one as the
# other.
class FrameworkPremises
  # A single declared commitment: this framework charges this much for this
  # crossing, for this stated reason.
  Charge = Data.define(:from_key, :to_key, :weight, :rationale) do
    def crossing = "#{from_key} → #{to_key}"
    def free? = weight.zero?
    def to_s = "#{crossing} = #{weight}"
  end

  # Where two frameworks differ on one crossing.
  Divergence = Data.define(:from_key, :to_key, :left, :right) do
    def crossing = "#{from_key} → #{to_key}"
    def difference = left.weight - right.weight
  end

  # Frameworks form a PARTIAL order, not a ranking.
  #
  # One framework is stricter than another when it charges at least as much
  # everywhere and more somewhere. Where neither holds, they are INCOMPARABLE --
  # each charges more than the other on some crossing -- and that is reported
  # rather than resolved into a number. Collapsing a vector of charges into one
  # "strictness" score would assert a single dimension the framework never
  # declared, which is the error ADR 24 refuses for values and refuses here for
  # the same reason.
  Comparison = Data.define(:left, :right, :divergences, :relation, :shared, :unshared) do
    def differ? = divergences.any?
    def comparable? = %i[equivalent left_stricter right_stricter].include?(relation)

    def to_s
      case relation
      when :disjoint
        "#{left.key} and #{right.key} share no crossing — there is nothing to compare"
      when :equivalent then "#{left.key} and #{right.key} charge identically"
      when :left_stricter then "#{left.key} is stricter than #{right.key}"
      when :right_stricter then "#{right.key} is stricter than #{left.key}"
      else "#{left.key} and #{right.key} are incomparable — each charges more somewhere"
      end
    end
  end

  def self.for(framework) = new(framework)

  # Every crossing where two frameworks disagree, and how they stand to each
  # other. Reproduces the framework-substitution measurement as a routine rather
  # than a one-off (BASELINE-v3 §7).
  def self.compare(left, right)
    a = new(left)
    b = new(right)
    shared = a.crossings & b.crossings
    unshared = (a.crossings | b.crossings) - shared

    divergences = shared.filter_map do |(from_key, to_key)|
      l = a.charge(from_key, to_key)
      r = b.charge(from_key, to_key)
      next if l.weight == r.weight

      Divergence.new(from_key: from_key, to_key: to_key, left: l, right: r)
    end

    Comparison.new(left: left, right: right, divergences: divergences,
                   relation: relation_for(divergences, shared), shared: shared, unshared: unshared)
  end

  # DISJOINT is not EQUIVALENT, and the distinction is the same one
  # `CategoryPromotion.weight_for` draws between "no rule for this pair" and
  # "this pair costs nothing". Two frameworks with no crossing in common have
  # not been found to agree; nothing about them has been compared at all, and
  # reporting that as agreement is the error this class exists to avoid — found
  # by running it against a framework that carries a value vocabulary and no
  # promotion weights.
  def self.relation_for(divergences, shared)
    return :disjoint if shared.empty?
    return :equivalent if divergences.empty?

    left_higher = divergences.any? { it.difference.positive? }
    right_higher = divergences.any? { it.difference.negative? }

    return :incomparable if left_higher && right_higher
    left_higher ? :left_stricter : :right_stricter
  end
  private_class_method :relation_for

  def initialize(framework)
    @framework = framework
  end

  attr_reader :framework

  def charges
    @charges ||= CategoryPromotion.includes(:from_category, :to_category)
                                  .where(framework: framework)
                                  .map do |promotion|
      Charge.new(from_key: promotion.from_category.key, to_key: promotion.to_category.key,
                 weight: promotion.weight, rationale: promotion.rationale)
    end.sort_by { [ -it.weight, it.from_key, it.to_key ] }
  end

  def crossings = charges.map { [ it.from_key, it.to_key ] }

  def charge(from_key, to_key)
    charges.find { it.from_key == from_key && it.to_key == to_key }
  end

  # What the framework will not let pass for free. The commitments it holds,
  # heaviest first — which is the closest thing to a "ranking" the declared data
  # supports, and it is a ranking of CROSSINGS rather than of values.
  def costly = charges.reject(&:free?)

  # Crossings this framework was never asked about. Not zero: "no rule for this
  # pair" and "this pair costs nothing" are different, and a report that showed
  # them alike would licence the confusion `CategoryPromotion.weight_for`
  # already refuses.
  def silent
    keys = framework.claim_categories.map(&:key)
    all = keys.product(keys).reject { |from, to| from == to }
    all - crossings
  end
end
