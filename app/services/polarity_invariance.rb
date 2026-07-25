# The enforceable form of Column D's claim about categories.
#
#   Negating a claim does not change what KIND of claim it is.
#
# "The wall represented fear" is interpretive. "The wall did not represent fear"
# is interpretive too. The categories differ in kind, not in content, so a
# classifier that moves a claim to a different category when it is negated is
# reading what the claim says rather than what it does.
#
# Stated as a property a classifier either has or does not — in the manner of
# GapInvariance, and for the same reason. "Is the classifier correct" is not
# checkable. This is.
#
# The check works by construction: negate a claim structurally, classify both,
# compare the categories. It costs two classifications and no opinion.
class PolarityInvariance
  CRITERION = "polarity invariance".freeze

  Result = Data.define(:holds, :original, :negated, :categories, :criterion) do
    def holds? = holds
    def checked? = !negated.nil?

    def violation
      return nil if holds? || !checked?

      "category moved from #{categories.first} to #{categories.last} under negation"
    end

    def skipped = checked? ? nil : "no structural negation could be constructed"
  end

  # `classifier` is any callable taking a string and returning a category key,
  # so this can be run against a stub as readily as against a governed model.
  def self.holds_for?(classifier, text:) = check(classifier, text: text).holds?

  def self.check(classifier, text:)
    negated = Negator.new(text).call

    # Abstention, not failure. A claim this cannot negate structurally is one
    # the property says nothing about, and inventing a negation would put the
    # checker's own paraphrase underneath the result.
    return Result.new(holds: true, original: text, negated: nil, categories: [],
                      criterion: CRITERION) if negated.nil?

    before = classifier.call(text)
    after = classifier.call(negated)

    Result.new(holds: before == after, original: text, negated: negated,
               categories: [ before, after ], criterion: CRITERION)
  end

  # Structural negation only.
  #
  # Deliberately narrow and deliberately incapable of paraphrase. A model asked
  # to negate a sentence would rewrite it, and then a failure could not be
  # attributed to the negation rather than to the rewrite. This inserts "not"
  # where English grammar allows it to be inserted mechanically, and gives up
  # otherwise.
  class Negator
    COPULA = /\b(is|are|was|were|am)\b/i
    AUXILIARY = /\b(has|have|had|will|would|can|could|should|must|may|might|does|do|did)\b/i
    ALREADY_NEGATED = /\b(not|never|no|none|nothing|nobody|neither|nor|cannot)\b|\w+n[''’]t\b/i

    def initialize(text)
      @text = text.to_s.strip
    end

    def call
      return nil if @text.empty?
      # Negating an already-negated claim yields a double negative, which is
      # exactly the construction the Situational Sentinel calls unreadable.
      return nil if @text.match?(ALREADY_NEGATED)
      return nil if @text.end_with?("?")

      insert_after(COPULA) || insert_after(AUXILIARY)
    end

    private

    def insert_after(pattern)
      match = pattern.match(@text)
      return nil if match.nil?

      "#{@text[0...match.end(0)]} not#{@text[match.end(0)..]}"
    end
  end
end
