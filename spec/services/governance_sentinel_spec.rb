require "rails_helper"

RSpec.describe GovernanceSentinel do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: true) }
  let!(:governance_sentinel) do
    Referent.create!(key: "governance-sentinel", name: "Governance Sentinel", subject: "System",
                     role: "Sentinel", primitive: "system")
  end
  let(:classifier) do
    Referent.create!(name: "Claim Classifier", subject: "System", role: "Classifier",
                     primitive: "system")
  end
  let(:document) { Document.create!(body: "…") }

  def category(key, position, rank)
    ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                          position: position, justification_rank: rank,
                          definition: "…", confidence_source: "…")
  end

  let(:objective)    { category("objective", 1, 1) }
  let(:observation)  { category("observation", 2, 1) }
  let(:interpretive) { category("interpretive", 3, 2) }
  let(:ontological)  { category("ontological", 4, 3) }

  # What a move costs is framework data. Without it the Sentinel refuses to rule
  # rather than judging every step earned — so a spec that builds its own
  # framework has to weight it, exactly as the seeds do.
  def weigh(from, to, weight)
    CategoryPromotion.find_or_initialize_by(framework: framework, from_category: from,
                                            to_category: to).update!(weight: weight)
  end

  before do
    weigh(objective, observation, 0)
    weigh(observation, objective, 0)
    weigh(objective, interpretive, 1)
    weigh(observation, interpretive, 1)
    weigh(interpretive, ontological, 2)
    weigh(objective, ontological, 3)
    weigh(observation, ontological, 3)
    [ [ interpretive, objective ], [ interpretive, observation ],
      [ ontological, objective ], [ ontological, observation ],
      [ ontological, interpretive ] ].each { weigh(it.first, it.last, 0) }
  end

  def claim(text) = document.claims.create!(position: document.claims.count + 1, text: text)

  def transition_between(from_category, to_category, asserter: classifier)
    a = claim("first")
    b = claim("second")
    a.classify!(from_category, asserter: asserter)
    b.classify!(to_category, asserter: asserter)
    Transition.create!(source: a, target: b)
  end

  describe "unearned promotion" do
    # The framework's canonical case.
    it "flags observation → ontological" do
      t = transition_between(observation, ontological)

      result = described_class.review!(t)

      expect(result).to be_unearned
      expect(t.verdict).to eq "unearned"
      expect(result.reason).to include "exceeds the evidence class presented"
    end

    it "flags observation → interpretive" do
      expect(described_class.review!(transition_between(observation, interpretive))).to be_unearned
    end

    it "raises a concern, not a stop — agency is preserved" do
      result = described_class.review!(transition_between(observation, ontological))

      expect(result.flag.severity).to eq "concern"
      expect(result.flag).not_to be_stop
      expect(document.executable?).to be true
    end

    it "never says the claim is false" do
      result = described_class.review!(transition_between(observation, ontological))

      expect(result.flag.message).to include "not a judgement that the claim is false"
      expect(result.flag.message).to include "changed category without a corresponding increase"
    end

    it "attributes the verdict and the flag to the Governance Sentinel" do
      result = described_class.review!(transition_between(observation, ontological))

      expect(result.flag.asserter).to eq governance_sentinel
      expect(result.transition.history.map(&:asserter).uniq).to eq [ governance_sentinel ]
    end
  end

  describe "earned transitions" do
    it "does not flag when the category is unchanged" do
      result = described_class.review!(transition_between(observation, observation))

      expect(result.verdict).to eq "earned"
      expect(result.flag).to be_nil
    end

    # Objective and Observation are different in kind, not in burden.
    it "does not treat a lateral change as a promotion" do
      result = described_class.review!(transition_between(objective, observation))

      expect(result.verdict).to eq "earned"
      expect(result.reason).to include "without increasing the justification burden"
    end

    it "does not flag a descent to a lower burden" do
      expect(described_class.review!(transition_between(ontological, observation)).verdict).to eq "earned"
    end

    # "Additional justification" has to be something the record can show.
    it "accepts a promotion accompanied by evidence" do
      t = transition_between(observation, ontological)
      testimony = Evidence.create!(kind: "document", reference: "corroborating-account")
      EvidenceLink.create!(assertion: t.to_claim.classification, evidence: testimony)

      result = described_class.review!(t)

      expect(result.verdict).to eq "earned"
      expect(result.reason).to include "supported by evidence"
    end
  end

  describe "refusing to judge" do
    it "records no verdict when either claim is unclassified" do
      a = claim("first")
      b = claim("second")
      a.classify!(observation, asserter: classifier)
      t = Transition.create!(source: a, target: b)

      result = described_class.review!(t)

      expect(result).not_to be_judged
      expect(t.verdict).to eq "undetermined"
      expect(t.assertions).to be_empty
    end

    # Independence is epistemic, not organisational.
    it "refuses to rule on a classification it made itself" do
      t = transition_between(observation, ontological, asserter: governance_sentinel)

      expect { described_class.review!(t) }
        .to raise_error(described_class::NotIndependent, /cannot also rule/)
    end

    # Identity precedes reasoning.
    it "refuses to judge while the document is locked" do
      Referent.create!(key: "identity-sentinel", name: "Identity Sentinel", subject: "System",
                       role: "Sentinel", primitive: "system")
      t = transition_between(observation, ontological)
      IdentitySentinel.verify!(t.from_claim.mentions.create!(text: "Pugsley"))

      expect { described_class.review!(t) }.to raise_error(Document::ExecutionLocked)
    end
  end

  describe "reviewing a whole document" do
    it "returns a result per transition" do
      a, b, c = claim("one"), claim("two"), claim("three")
      a.classify!(observation, asserter: classifier)
      b.classify!(observation, asserter: classifier)
      c.classify!(ontological, asserter: classifier)
      Transition.create!(source: a, target: b)
      Transition.create!(source: b, target: c)

      results = described_class.review_document!(document)

      expect(results.map(&:verdict)).to contain_exactly("earned", "unearned")
    end
  end

  # The same step, judged under different premises, is a different question.
  # `alexicon-2.0` charges 2 for `ontological → normative`, with a rationale
  # naming Hume; `lewisian-1.0` charges 0, holding that a claim about what ought
  # to be is a claim about what is. Both may rule, and both rulings stand.
  describe "judging under a named framework" do
    let(:rival) { Framework.create!(key: "rival-fw", name: "Rival", version: "0", current: false) }

    # The rival speaks the same vocabulary and prices one move differently —
    # matched by key, which is what makes a claim classified under one framework
    # judgeable under another.
    before do
      %w[objective observation interpretive ontological].each_with_index do |key, i|
        ClaimCategory.create!(framework: rival, key: key, name: key.capitalize, position: i + 1,
                              justification_rank: 1, definition: "…", confidence_source: "…")
      end
      rivals = ClaimCategory.where(framework: rival).index_by(&:key)
      ClaimCategory.where(framework: framework).find_each do |mine|
        ClaimCategory.where(framework: framework).find_each do |theirs|
          next if mine == theirs

          CategoryPromotion.create!(framework: rival, from_category: rivals[mine.key],
                                    to_category: rivals[theirs.key], weight: 0)
        end
      end
    end

    it "reaches a different verdict from the same step when the premises differ" do
      t = transition_between(observation, ontological)

      described_class.review!(t, framework: framework)
      described_class.review!(t, framework: rival)

      expect(t.verdict(framework: framework)).to eq "unearned"
      expect(t.verdict(framework: rival)).to eq "earned"
    end

    it "leaves both premises standing rather than the later overwriting the earlier" do
      t = transition_between(observation, ontological)

      described_class.review!(t, framework: framework)
      described_class.review!(t, framework: rival)

      expect(t.verdicts.transform_keys(&:key)).to eq("test-fw" => "unearned", "rival-fw" => "earned")
    end

    it "does not report a disagreement between premises as a contested step" do
      t = transition_between(observation, ontological)

      described_class.review!(t, framework: framework)
      described_class.review!(t, framework: rival)

      expect(t).not_to be_contested(framework: framework)
      expect(t).not_to be_contested(framework: rival)
    end

    # A framework that has not priced the move has not said it is free.
    it "declines to rule under a framework that does not speak the vocabulary" do
      silent = Framework.create!(key: "silent-fw", name: "Silent", version: "0", current: false)
      t = transition_between(observation, ontological)

      result = described_class.review!(t, framework: silent)

      expect(result).not_to be_judged
      expect(t.verdict(framework: silent)).to eq "undetermined"
    end
  end
end
