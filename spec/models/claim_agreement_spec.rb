require "rails_helper"

# One machine reading was measured at 88% reproducible, and re-running a whole
# document changed half the steps it flagged. So a single reading is a sample,
# and what distinguishes it from a finding is how many readings agree.
RSpec.describe "agreement across readings" do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:claim) { document.claims.create!(position: 1, text: "The wall represented fear.") }
  let(:machine) { Referent.find_by!(key: "claim-classifier") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)
  def read(key, by: machine) = claim.classify!(category(key), asserter: by, confidence: 0.9)

  describe "a majority" do
    it "types the claim when the readings agree" do
      3.times { read("interpretive") }

      expect(claim.category.key).to eq "interpretive"
      expect(claim.agreement.to_s).to eq "3 of 3"
      expect(claim.agreement).to be_unanimous
    end

    it "types it on a strict majority" do
      2.times { read("interpretive") }
      read("ontological")

      expect(claim.category.key).to eq "interpretive"
      expect(claim.agreement.to_s).to eq "2 of 3"
      expect(claim.agreement).not_to be_unanimous
    end

    # The point of the change: no majority means the system does not know, which
    # is what abstention already means everywhere else here.
    it "leaves it unclassified when three readings disagree three ways" do
      read("interpretive")
      read("ontological")
      read("observation")

      expect(claim.category).to be_nil
      expect(claim.agreement).not_to be_decided
      expect(claim.agreement.to_s).to eq "3 readings, no majority"
    end

    it "leaves it unclassified on an even split" do
      2.times { read("interpretive") }
      2.times { read("ontological") }

      expect(claim.category).to be_nil
    end

    # A plurality is not agreement: 2 of 5 should not decide.
    it "refuses a plurality that is not a majority" do
      2.times { read("interpretive") }
      read("ontological")
      read("observation")
      read("objective")

      expect(claim.category).to be_nil
      expect(claim.agreement.agreeing).to eq 2
    end
  end

  describe "a single reading" do
    it "still types the claim, and says it rests on one reading" do
      read("interpretive")

      expect(claim.category.key).to eq "interpretive"
      expect(claim.agreement).to be_single
      expect(claim.agreement.to_s).to eq "1 of 1"
    end

    it "reports nothing when there are no readings at all" do
      expect(claim.agreement.readings).to eq 0
      expect(claim.agreement.to_s).to eq "no reading"
      expect(claim.category).to be_nil
    end
  end

  describe "a person's judgement" do
    # Not a vote among others. It settles the question.
    it "wins outright against a machine majority" do
      3.times { read("ontological") }
      read("interpretive", by: person)

      expect(claim.category.key).to eq "interpretive"
      expect(claim.agreement.readings).to eq 1
    end

    it "settles a claim the machine readings could not" do
      read("interpretive")
      read("ontological")
      expect(claim.category).to be_nil

      read("observation", by: person)

      expect(claim.reload.category.key).to eq "observation"
      expect(claim.agreement).to be_decided
    end
  end

  # A person's reading is not a vote among the MACHINE's. It was also treated as
  # exempt from being disagreed with by another person: the last human reading
  # won and reported itself as `1 of 1`, so a second reader's answer vanished and
  # the sample size denied they had read it at all.
  #
  # The strict majority the machine is held to now applies to people too. That is
  # not a new rule — it is the existing one, finally applied on both sides.
  describe "two people who disagree" do
    let(:other) { Referent.create!(name: "Bo", subject: "Person", role: "Reviewer", primitive: "person") }

    it "leaves the claim untyped rather than taking whoever read last" do
      read("interpretive", by: person)
      read("ontological", by: other)

      expect(claim.category).to be_nil
      expect(claim).to be_contested
    end

    it "reports both readings in the sample rather than claiming one" do
      read("interpretive", by: person)
      read("ontological", by: other)

      expect(claim.agreement.readings).to eq 2
      expect(claim.agreement.to_s).to eq "2 readings, no majority"
    end

    it "does not fall back to the machine's answer when people are split" do
      3.times { read("observation") }
      read("interpretive", by: person)
      read("ontological", by: other)

      expect(claim.category).to be_nil
    end

    it "types it once a third reader breaks the tie" do
      third = Referent.create!(name: "Cy", subject: "Person", role: "Reviewer", primitive: "person")
      read("interpretive", by: person)
      read("ontological", by: other)
      read("interpretive", by: third)

      expect(claim.reload.category.key).to eq "interpretive"
      expect(claim.agreement.to_s).to eq "2 of 3"
      expect(claim).not_to be_contested
    end

    it "counts one person who read twice as one position, not two" do
      read("interpretive", by: person)
      read("ontological", by: person)

      expect(claim.reload.category.key).to eq "ontological"
      expect(claim.agreement.readings).to eq 1
      expect(claim).not_to be_contested
    end

    it "does not call a lone reader contested" do
      read("interpretive", by: person)

      expect(claim).not_to be_contested
      expect(claim.category.key).to eq "interpretive"
    end

    # An abstention records that somebody could not tell. It is a reading and
    # not a judgement, so it neither types the claim nor contests it.
    it "does not treat an abstention as a competing answer" do
      read("interpretive", by: person)
      claim.classifications.create!(asserter: other, act: "classify", claim: { "abstained" => true })

      expect(claim.reload.category.key).to eq "interpretive"
      expect(claim).not_to be_contested
    end
  end

  # Nothing is overwritten; a second opinion is added beside the first.
  it "keeps every reading, so disagreement survives in the record" do
    read("interpretive")
    read("ontological")

    expect(claim.classifications.count).to eq 2
    expect(claim.classifications.map { it.object.key }).to eq %w[interpretive ontological]
  end

  describe "asking for more readings" do
    let(:classifier) do
      cat = category("interpretive")
      referent = machine
      Class.new do
        define_method(:initialize) { |claims, **| @claims = Array(claims) }
        define_method(:classify!) do
          @claims.each_with_object({}) do |c, out|
            out[c] = c.classify!(cat, asserter: referent, confidence: 0.9)
          end
        end
      end
    end

    it "adds readings rather than starting over" do
      document.claims.create!(position: 2, text: "Another.")
      DocumentClassification.call(document, classifier: classifier, readings: 1)
      expect(document.claims.map { it.agreement.readings }.uniq).to eq [ 1 ]

      DocumentClassification.call(document, classifier: classifier, readings: 3)

      expect(document.reload.claims.map { it.agreement.readings }.uniq).to eq [ 3 ]
    end

    it "does not add machine readings to a claim a person has settled" do
      read("observation", by: person)

      DocumentClassification.call(document, classifier: classifier, readings: 3)

      expect(claim.reload.classifications.reject(&:human?)).to be_empty
      expect(claim.category.key).to eq "observation"
    end

    it "skips a claim that already has enough readings" do
      3.times { read("interpretive") }

      result = DocumentClassification.call(document, classifier: classifier, readings: 3)

      expect(result.skipped).to eq 1
      expect(claim.reload.agreement.readings).to eq 3
    end
  end

  describe "a finding's agreement" do
    it "is bounded by the least settled endpoint of the step" do
      a = claim
      b = document.claims.create!(position: 2, text: "There is a God.")
      3.times { a.classify!(category("interpretive"), asserter: machine, confidence: 0.9) }
      2.times { b.classify!(category("ontological"), asserter: machine, confidence: 0.9) }
      b.classify!(category("interpretive"), asserter: machine, confidence: 0.9)

      step = Transition.create!(source: a, target: b)
      step.record_verdict!("unearned", asserter: Referent.find_by!(key: "governance-sentinel"))

      finding = DocumentReading.for(document.reload).findings_for(b).find(&:unearned?)

      expect(finding.agreement.to_s).to eq "2 of 3"
    end
  end
end
