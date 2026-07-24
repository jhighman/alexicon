# Classifies every unclassified claim in a document.
#
# Identity precedes reasoning, so this refuses to run while the document is
# locked -- the same guard the Classification assertion enforces individually,
# checked once up front so the failure is legible instead of arriving 40 claims
# in.
#
# The run itself is recorded as an assertion by the classifier: "I looked at
# this document and classified n, abstained on m." That keeps run state derived
# rather than stored, and makes the attempt attributable like everything else.
# Abstentions are counted, never recorded as classifications -- an abstention is
# the absence of a judgement, and writing one down would invent the judgement
# it declined to make.
class DocumentClassification
  Result = Data.define(:document, :classified, :abstained, :skipped) do
    def attempted = classified + abstained
  end

  def self.call(document, **) = new(document, **).call

  def initialize(document, classifier: ClaimClassifier)
    @document = document
    @classifier = classifier
  end

  def call
    document.require_executable!

    classified = abstained = skipped = 0

    document.claims.each do |claim|
      # Never reclassify. A standing classification is answered by a person or
      # superseded deliberately, not overwritten by a second pass.
      if claim.category
        skipped += 1
        next
      end

      classifier.new(claim).classify! ? classified += 1 : abstained += 1
    end

    record_run(classified, abstained, skipped)
    Result.new(document: document, classified: classified, abstained: abstained, skipped: skipped)
  end

  private

  attr_reader :document, :classifier

  def record_run(classified, abstained, skipped)
    Assertion.create!(
      asserter: Referent.find_by!(key: "claim-classifier"),
      subject: document,
      act: "assert",
      claim: { "run" => "classification", "classified" => classified,
               "abstained" => abstained, "skipped" => skipped }
    )
  end
end
