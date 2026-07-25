require "rails_helper"

# Gravitational inversion: analysis flows forward until an anomaly appears, and
# then the pull reverses onto the claims underneath.
#
# A verdict on one step is local — it says the move was not earned, not where
# the argument left its ground. Four unearned steps in a row are one failure
# with three consequences.
RSpec.describe RetroactiveAudit do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(text, kind)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    c.classify!(category(kind), asserter: person, confidence: 1.0)
    c
  end

  def step(from, to, verdict)
    t = Transition.create!(source: from, target: to)
    t.record_verdict!(verdict, asserter: Referent.find_by!(key: "governance-sentinel"))
    t
  end

  describe "a step that costs more than an ordinary promotion" do
    # The transition the framework is named for. Under justification_rank this
    # measured as +1, the same as an ordinary promotion, and the audit could not
    # see it: 0 of 6 caught on the real document.
    it "flags interpretive becoming ontological" do
      a = claim("The wall represented fear.", "interpretive")
      b = claim("There is a God.", "ontological")
      step(a, b, "unearned")

      finding = described_class.findings_for(document.reload).sole

      expect(finding.kind).to eq :rank_skip
      expect(finding.claim).to eq b
      expect(finding.message).to include "weights at 2"
    end

    it "flags the claim it lands on" do
      a = claim("I saw a wall collapsing.", "observation")
      b = claim("There is a God.", "ontological")
      step(a, b, "unearned")

      finding = described_class.findings_for(document.reload).sole

      expect(finding.kind).to eq :rank_skip
      expect(finding.claim).to eq b
      expect(finding.message).to include "weights at 3"
    end

    # It must still not fire on an ordinary promotion, or it is not a signal.
    it "says nothing about an ordinary promotion" do
      a = claim("I saw it.", "observation")
      b = claim("It meant fear.", "interpretive")
      step(a, b, "unearned")

      expect(described_class.findings_for(document.reload)).to be_empty
    end

    it "says nothing about a lateral move between equally warranted kinds" do
      a = claim("Ketamine blocks NMDA receptors.", "objective")
      b = claim("I saw it work.", "observation")
      step(a, b, "unearned")

      expect(described_class.findings_for(document.reload)).to be_empty
    end

    # "No rule for this pair" is not "this pair is free".
    it "leaves an unweighted pair alone rather than treating it as free" do
      a = claim("The wall represented fear.", "interpretive")
      b = claim("There is a God.", "ontological")
      step(a, b, "unearned")
      CategoryPromotion.find_by!(from_category: category("interpretive"),
                                 to_category: category("ontological")).destroy!

      expect(described_class.findings_for(document.reload)).to be_empty
    end

    # The audit reads verdicts; it does not form its own.
    it "says nothing about a rank skip that was judged earned" do
      a = claim("I saw a wall collapsing.", "observation")
      b = claim("There is a God.", "ontological")
      step(a, b, "earned")

      expect(described_class.findings_for(document.reload)).to be_empty
    end
  end

  describe "a run of consecutive unearned steps" do
    # The point of inverting the pull: name where the argument left its ground,
    # not each consequence of having left it.
    it "flags where the run starts, not each step in it" do
      a = claim("We both had children.", "objective")
      b = claim("We were both holding on.", "interpretive")
      c = claim("That is what fatherhood is.", "ontological")
      step(a, b, "unearned")
      step(b, c, "unearned")

      findings = described_class.findings_for(document.reload).select { it.kind == :run }

      expect(findings.sole.claim).to eq a
      expect(findings.sole.message).to include "2 consecutive steps"
    end

    it "does not treat two separated unearned steps as a run" do
      a = claim("One.", "objective")
      b = claim("Two.", "interpretive")
      c = claim("Three.", "objective")
      d = claim("Four.", "interpretive")
      step(a, b, "unearned")
      step(b, c, "earned")
      step(c, d, "unearned")

      expect(described_class.findings_for(document.reload).select { it.kind == :run }).to be_empty
    end
  end

  describe "a claim carrying weight it did not earn" do
    it "flags a claim reached unearned and then used as ground" do
      a = claim("One.", "objective")
      b = claim("Two.", "interpretive")
      c = claim("Three.", "objective")
      step(a, b, "unearned")
      step(b, c, "earned")
      # b was reached unearned; make it the ground of another unearned step
      d = claim("Four.", "interpretive")
      step(b, d, "unearned")

      findings = described_class.findings_for(document.reload)

      expect(findings.map(&:kind)).to include :load_bearing
      expect(findings.find { it.kind == :load_bearing }.claim).to eq b
    end

    # The run finding already names a better place to look.
    it "stays quiet inside a run, where the run finding is the better answer" do
      a = claim("One.", "objective")
      b = claim("Two.", "interpretive")
      c = claim("Three.", "ontological")
      step(a, b, "unearned")
      step(b, c, "unearned")

      expect(described_class.findings_for(document.reload).map(&:kind)).not_to include :load_bearing
    end
  end

  describe "what it refuses to do" do
    let!(:setup) do
      a = claim("I saw a wall collapsing.", "observation")
      b = claim("There is a God.", "ontological")
      [ a, b, step(a, b, "unearned") ]
    end

    it "raises a concern, never a STOP" do
      described_class.review!(document.reload)

      expect(document.reload.open_stops).to be_empty
      expect(document).to be_executable
    end

    it "does not re-judge the step it read" do
      transition = setup.last

      expect { described_class.review!(document.reload) }
        .not_to change { transition.reload.verdict }
    end

    it "does not re-classify the claim it flagged" do
      landed = setup[1]

      expect { described_class.review!(document.reload) }
        .not_to change { landed.reload.category&.key }
    end

    # Chapter 6: an actor reviewing its own rulings is the conflation the
    # framework forbids.
    it "is a different actor from the Sentinel whose verdicts it read" do
      flag = described_class.review!(document.reload).first

      expect(flag.asserter.key).to eq "retroactive-audit"
      expect(flag.asserter.key).not_to eq "governance-sentinel"
    end

    it "raises one flag per claim per kind, however often it runs" do
      expect { 3.times { described_class.review!(document.reload) } }
        .to change { Assertion.flags.count }.by(1)
    end

    it "finds nothing when no step has been judged" do
      other = Document.create!(body: "…")
      x = other.claims.create!(position: 1, text: "One.")
      y = other.claims.create!(position: 2, text: "Two.")
      Transition.create!(source: x, target: y)

      expect(described_class.findings_for(other)).to be_empty
    end
  end

  # Every signal is computable from what is already recorded, so a finding can
  # be checked by hand and does not cost a call.
  it "calls no model" do
    a = claim("I saw a wall collapsing.", "observation")
    b = claim("There is a God.", "ontological")
    step(a, b, "unearned")

    expect { described_class.review!(document.reload) }
      .not_to change { LlmInvocation.count }
  end
end
