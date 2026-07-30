require "rails_helper"

# The counterpart to blind typing, and the specs that matter are the ones about
# what it refuses to serve.
RSpec.describe Review do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }
  let(:sentinel) { Referent.find_by!(key: "governance-sentinel") }
  let(:value_judge) { Referent.find_by!(key: StepValueJudge::JUDGE) }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:review) { described_class.new(document, reviewer: person) }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(text, kind, readings: 3)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    readings.times { c.classify!(category(kind), asserter: classifier, confidence: 0.9) }
    c
  end

  def unearned_step
    t = Transition.create!(source: claim("From.", "interpretive"), target: claim("To.", "ontological"))
    t.record_verdict!("unearned", asserter: sentinel)
    t
  end

  def value_reading(step)
    Assertion.create!(asserter: value_judge, subject: step, act: "assert",
                      claim: { "inference" => "step value", "protects" => "Generality",
                               "against" => "Coherence", "confidence" => 0.9,
                               "rationale" => "the scope widens" })
  end

  # THE boundary. If this queue served claims, a reviewer would see the
  # machine's category for the same claims the blind surface needs them naive
  # for, and the one measurement that is not the system checking itself would
  # stop being worth taking.
  describe "what it will not serve" do
    it "never queues a claim classification, however unsettled" do
      claim("Barely typed.", "interpretive", readings: 1)
      claim("Not typed at all.", "observation", readings: 0)

      expect(review.queue.map(&:kind)).not_to include "claim"
      expect(review.queue.map { it.assertion.act }).not_to include "classify"
    end

    it "queues nothing at all for a document with only claims in it" do
      3.times { claim("A claim.", "observation") }

      expect(review.queue).to be_empty
    end

    it "refuses to dispose of something outside its own queue" do
      other = Assertion.create!(asserter: classifier, subject: claim("x", "observation"),
                                act: "flag", claim: { "severity" => "notice" })

      expect { review.dispose!(other, verdict: "accept") }
        .to raise_error(described_class::NotReviewable, /not in this queue/)
    end
  end

  # A contested step is neither earned nor unearned, so it falls out of
  # `unearned?` and out of every list built from it — including this queue,
  # which is where a disagreement most needs a person. Nothing else in the
  # system would have noticed it had gone.
  describe "a step two judges disagree about" do
    let(:second_sentinel) do
      Referent.create!(name: "Second Sentinel", subject: "System", role: "Sentinel", primitive: "system")
    end

    def contested_step
      t = Transition.create!(source: claim("From.", "interpretive"), target: claim("To.", "ontological"))
      t.record_verdict!("unearned", asserter: sentinel)
      t.record_verdict!("earned", asserter: second_sentinel)
      t
    end

    it "queues it, though it is neither earned nor unearned" do
      step = contested_step

      expect(step).to be_contested
      expect(step).not_to be_unearned
      expect(review.queue.map(&:kind)).to include "contested step"
    end

    it "puts it before everything else — the system reporting it does not know" do
      value_reading(unearned_step)
      contested_step

      expect(review.queue.first.kind).to eq "contested step"
    end

    it "shows both rulings, with who said what" do
      contested_step

      item = review.queue.find { it.kind == "contested step" }

      expect(item.detail).to include "Governance Sentinel: unearned"
      expect(item.detail).to include "Second Sentinel: earned"
      expect(item.caveat).to match(/Disposing of one does not delete the other/)
    end

    it "lets a reviewer dispose of either position, not only the later one" do
      step = contested_step
      earlier = step.positions.values.first

      expect { review.dispose!(earlier, verdict: "accept") }.not_to raise_error
      expect(earlier.reload.disposition).to eq "accepted"
    end

    it "drops out of the queue once every position has been answered" do
      step = contested_step
      step.positions.values.each { review.dispose!(it, verdict: "accept") }

      expect(described_class.new(document, reviewer: person).queue.map(&:kind))
        .not_to include "contested step"
    end
  end

  describe "the order of the queue" do
    # Weakest first: three controls say the value layer cannot tell a real step
    # from an unrelated pair, so a person's attention is worth most there.
    it "puts value readings before step verdicts" do
      value_reading(unearned_step)
      unearned_step

      kinds = review.queue.map(&:kind)

      expect(kinds.first).to eq "value reading"
      expect(kinds.index("value reading")).to be < kinds.index("unearned step")
    end

    it "offers the next thing waiting, and nothing once all are disposed" do
      step = unearned_step
      reading = value_reading(step)
      review.dispose!(reading, verdict: "reject")
      review.dispose!(step.ruling, verdict: "accept")

      expect(review.next_item).to be_nil
      expect(review.reviewed_count).to eq 2
    end
  end

  describe "what a reviewer is shown" do
    it "warns, on a value reading, that the layer cannot tell signal from noise" do
      value_reading(unearned_step)

      expect(review.next_item.caveat).to match(/cannot distinguish a real step/)
      expect(review.next_item.caveat).to match(/Reject freely/)
    end

    # Accepting an unearned step is taking responsibility for it, not overruling
    # the Sentinel — which is the shape costly obedience has here.
    it "says that accepting a step does not overrule the Sentinel" do
      unearned_step

      item = review.queue.find { it.kind == "unearned step" }

      expect(item.caveat).to match(/does not overrule the Sentinel/)
      expect(item.caveat).to match(/may stand anyway, not that it was earned/)
    end

    it "shows both claims of the step, so the judgement can be checked against them" do
      value_reading(unearned_step)

      expect(review.next_item.context).to eq [ "From.", "To." ]
    end
  end

  describe "disposing" do
    it "records the disposal beside what it disposes of, never over it" do
      reading = value_reading(unearned_step)

      review.dispose!(reading, verdict: "reject", rationale: "nothing like that here")

      expect(reading.reload.disposition).to eq "rejected"
      expect(reading.assertions.last.claim["rationale"]).to eq "nothing like that here"
      expect(reading.superseded_by).to be_empty
    end

    it "leaves an accepted verdict standing and undisturbed" do
      step = unearned_step

      review.dispose!(step.ruling, verdict: "accept", rationale: "it may stand")

      expect(step.reload.verdict).to eq "unearned"
      expect(step.ruling.disposition).to eq "accepted"
    end

    it "attributes the disposal to the reviewer" do
      reading = value_reading(unearned_step)

      expect(review.dispose!(reading, verdict: "accept").asserter).to eq person
    end

    it "takes accept or reject, and nothing else" do
      reading = value_reading(unearned_step)

      expect { review.dispose!(reading, verdict: "maybe") }
        .to raise_error(described_class::UnknownVerdict, /accept or reject/)
    end

    it "drops a disposed item out of the queue" do
      reading = value_reading(unearned_step)
      expect { review.dispose!(reading, verdict: "reject") }
        .to change { described_class.new(document, reviewer: person).queue.size }.by(-1)
    end
  end
end
