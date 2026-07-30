require "rails_helper"

# A Transition is a Relationship between claims. Its verdict is not a column:
# a sentinel ASSERTS that a promotion was earned, and that assertion is
# attributable, evidenced, and open to challenge like any other.
RSpec.describe Transition do
  let(:framework) { Framework.create!(key: "test-fw", name: "Test", version: "0", current: false) }
  let(:document)  { Document.create!(body: "…") }
  let(:sentinel) do
    Referent.create!(name: "Governance Sentinel", subject: "System", role: "Sentinel",
                     primitive: "system")
  end

  def category(key, position)
    ClaimCategory.create!(framework: framework, key: key, name: key.capitalize,
                          position: position, definition: "…", confidence_source: "…")
  end

  def claim(position, text) = document.claims.create!(position: position, text: text)

  def transition(from, to) = described_class.create!(source: from, target: to)

  it "is a Relationship" do
    expect(described_class.superclass).to eq Relationship
    expect(transition(claim(1, "a"), claim(2, "b"))).to be_a Relationship
  end

  it "defaults its kind" do
    expect(transition(claim(1, "a"), claim(2, "b")).kind).to eq "epistemic_transition"
  end

  it "refuses a transition from a claim to itself" do
    a = claim(1, "one")

    expect(described_class.new(source: a, target: a)).not_to be_valid
  end

  # The verdict read "the latest assertion, whatever it was", so anything else
  # recorded about a step erased it. Nothing had exercised it, because until
  # StepValueJudge only the Sentinel ever wrote to a transition.
  describe "a verdict beside other assertions" do
    it "survives an assertion that is not a ruling" do
      a, b = claim(1, "one"), claim(2, "two")
      t = transition(a, b)
      t.record_verdict!("unearned", asserter: sentinel)

      Assertion.create!(asserter: sentinel, subject: t, act: "assert",
                        claim: { "inference" => "step value", "protects" => "something" })

      expect(t.reload.verdict).to eq "unearned"
      expect(t).to be_unearned
    end

    it "is still replaced by a later ruling" do
      a, b = claim(1, "one"), claim(2, "two")
      t = transition(a, b)
      t.record_verdict!("unearned", asserter: sentinel)
      Assertion.create!(asserter: sentinel, subject: t, act: "assert",
                        claim: { "note" => "not a ruling" })
      t.record_verdict!("earned", asserter: sentinel)

      expect(t.reload.verdict).to eq "earned"
    end
  end

  describe "#category_change?" do
    it "is true when the claims carry different categories" do
      observation = category("observation", 1)
      ontological = category("ontological", 2)
      a, b = claim(1, "I experienced peace."), claim(2, "Therefore God exists.")
      a.classify!(observation, asserter: sentinel)
      b.classify!(ontological, asserter: sentinel)

      expect(transition(a, b).category_change?).to be true
    end

    it "is false when both claims share a category" do
      observation = category("observation", 1)
      a, b = claim(1, "I saw a wall."), claim(2, "I saw it collapse.")
      [ a, b ].each { it.classify!(observation, asserter: sentinel) }

      expect(transition(a, b).category_change?).to be false
    end

    it "is false when either claim is unclassified, rather than guessing" do
      observation = category("observation", 1)
      a, b = claim(1, "I experienced peace."), claim(2, "Therefore God exists.")
      a.classify!(observation, asserter: sentinel)

      expect(transition(a, b).category_change?).to be false
    end
  end

  describe "verdict" do
    it "is undetermined until something has judged it" do
      t = transition(claim(1, "a"), claim(2, "b"))

      expect(t.verdict).to eq "undetermined"
      expect(t.score).to be_nil
      expect(t.status).to eq :proposed
    end

    it "is derived from an accountable assertion, not stored" do
      t = transition(claim(1, "a"), claim(2, "b"))

      t.record_verdict!("unearned", asserter: sentinel, score: 0.12,
                        rationale: "confidence exceeds the evidence class presented")

      expect(t.verdict).to eq "unearned"
      expect(t).to be_unearned
      expect(t.score).to eq 0.12
      expect(described_class.column_names).not_to include("verdict", "score")
    end

    it "attributes the judgement to whoever made it" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("earned", asserter: sentinel)

      expect(t.history.sole.asserter).to eq sentinel
    end

    it "rejects a verdict outside the permitted set" do
      t = transition(claim(1, "a"), claim(2, "b"))

      expect { t.record_verdict!("false", asserter: sentinel) }.to raise_error(ArgumentError)
    end

    # Reversal answers the earlier judgement rather than erasing it.
    it "lets a later judgement supersede an earlier one, keeping both" do
      t = transition(claim(1, "a"), claim(2, "b"))
      first = t.record_verdict!("unearned", asserter: sentinel)
      Assertion.create!(asserter: sentinel, subject: t, act: "amend",
                        claim: { "verdict" => "earned" }, supersedes: first)

      expect(t.verdict).to eq "earned"
      expect(t.history.count).to eq 2
      expect(first.reload.claim["verdict"]).to eq "unearned"
    end

    it "reports disputed while a challenge to the judgement stands" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("unearned", asserter: sentinel)
      Assertion.create!(asserter: sentinel, subject: t, act: "challenge",
                        claim: { "reason" => "the categories were misassigned" })

      expect(t.status).to eq :disputed
    end
  end

  # The architecture must preserve disagreement before it is asked to adjudicate
  # disagreement. `verdict` took the latest ruling of any origin, so a second set
  # of premises could not be recorded without impersonating the first changing
  # its mind — which is why the Lewisian run was computed and discarded rather
  # than stored.
  describe "judgements made under different premises" do
    let(:rival) { Framework.create!(key: "rival-fw", name: "Rival", version: "0", current: false) }
    let(:other_sentinel) do
      Referent.create!(name: "Second Sentinel", subject: "System", role: "Sentinel", primitive: "system")
    end

    it "keeps one framework's verdict out of another's" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("unearned", asserter: sentinel, framework: framework)
      t.record_verdict!("earned", asserter: sentinel, framework: rival)

      expect(t.verdict(framework: framework)).to eq "unearned"
      expect(t.verdict(framework: rival)).to eq "earned"
    end

    it "reports both premises standing, neither overwritten" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("unearned", asserter: sentinel, framework: framework)
      t.record_verdict!("earned", asserter: sentinel, framework: rival)

      expect(t.verdicts.transform_keys(&:key)).to eq("test-fw" => "unearned", "rival-fw" => "earned")
      expect(t.frameworks_ruling).to contain_exactly(framework, rival)
    end

    it "stamps the framework on the ruling rather than leaving it to be inferred" do
      t = transition(claim(1, "a"), claim(2, "b"))

      expect(t.record_verdict!("earned", asserter: sentinel, framework: rival).framework).to eq rival
    end

    it "does not let a ruling under one framework answer for a framework that never ruled" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("unearned", asserter: sentinel, framework: framework)

      expect(t.verdict(framework: rival)).to eq "undetermined"
    end

    # Two judges disagreeing is the thing the system must not resolve on its own.
    it "reports contested when two asserters disagree under the same premises" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("unearned", asserter: sentinel, framework: framework)
      t.record_verdict!("earned", asserter: other_sentinel, framework: framework)

      expect(t.verdict(framework: framework)).to eq described_class::CONTESTED
      expect(t).to be_contested(framework: framework)
    end

    it "will not let contested be asserted as though it were a verdict" do
      t = transition(claim(1, "a"), claim(2, "b"))

      expect { t.record_verdict!("contested", asserter: sentinel) }.to raise_error(ArgumentError)
      expect(described_class::VERDICTS).not_to include described_class::CONTESTED
    end

    # One judge changing its own answer is drift, not disagreement, and merging
    # the two would hide that the instrument moved.
    it "calls one asserter changing its own answer drift, not disagreement" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("earned", asserter: sentinel, framework: framework)
      t.record_verdict!("unearned", asserter: sentinel, framework: framework)

      expect(t).to be_unstable(framework: framework)
      expect(t).not_to be_contested(framework: framework)
      expect(t.verdict(framework: framework)).to eq "unearned"
    end

    it "counts a judge that ruled three times as one position, not three" do
      t = transition(claim(1, "a"), claim(2, "b"))
      3.times { t.record_verdict!("earned", asserter: sentinel, framework: framework) }

      expect(t.positions(framework: framework).size).to eq 1
      expect(t.rulings(framework: framework).size).to eq 3
      expect(t).not_to be_unstable(framework: framework)
    end

    it "does not treat drift under one framework as agreement with another" do
      t = transition(claim(1, "a"), claim(2, "b"))
      t.record_verdict!("earned", asserter: sentinel, framework: framework)
      t.record_verdict!("unearned", asserter: sentinel, framework: framework)
      t.record_verdict!("earned", asserter: sentinel, framework: rival)

      expect(t.verdict(framework: framework)).to eq "unearned"
      expect(t.verdict(framework: rival)).to eq "earned"
      expect(t).not_to be_unstable(framework: rival)
    end
  end

  it "belongs to the document of its endpoints" do
    a, b = claim(1, "a"), claim(2, "b")
    t = transition(a, b)

    expect(t.document).to eq document
    expect(document.transitions).to contain_exactly(t)
  end
end
