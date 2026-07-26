require "rails_helper"

# The measurement this exists for only works if the reader could not have seen
# the answer. That is a property of the code, not of anyone's discipline, so it
# is the thing most of these specs are about.
RSpec.describe BlindReading do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:machine) { Referent.find_by!(key: "claim-classifier") }
  let(:reader) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:reading) { described_class.new(document, reader: reader) }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(position, text = "Claim #{position}.", structural: false)
    document.claims.create!(position: position, text: text, structural: structural)
  end

  def machine_reads(claim, key, times: 1)
    times.times { claim.classify!(category(key), asserter: machine, confidence: 0.9) }
  end

  describe "the queue" do
    it "asks about every substantive claim in document order" do
      third = claim(3)
      first = claim(1)
      claim(2, "A heading", structural: true)

      expect(reading.queue.to_a).to eq [ first, third ]
      expect(reading.total).to eq 2
    end

    # Queueing only claims the machine typed would tell the reader, before they
    # answered, that it had an opinion.
    it "includes claims the machine never typed" do
      untouched = claim(1)
      machine_reads(claim(2), "interpretive")

      expect(reading.queue).to include untouched
    end

    it "hands out the first claim the reader has not answered" do
      first = claim(1)
      second = claim(2)

      expect(reading.next_claim).to eq first
      reading.record!(first, category: category("interpretive"))

      expect(reading.next_claim).to eq second
      expect(reading.answered_count).to eq 1
    end

    it "runs out when everything has been answered" do
      reading.record!(claim(1), category: category("interpretive"))

      expect(reading.next_claim).to be_nil
      expect(reading).to be_complete
    end

    it "does not count another reader's answers as this reader's" do
      someone_else = Referent.create!(name: "Bo", subject: "Person", role: "Reviewer",
                                      primitive: "person")
      only = claim(1)
      described_class.new(document, reader: someone_else)
                     .record!(only, category: category("interpretive"))

      expect(reading.next_claim).to eq only
      expect(reading.answered_count).to eq 0
    end
  end

  # The invariant.
  describe "blindness" do
    let(:target) { claim(1) }

    it "refuses to say what the machine read before the person has answered" do
      machine_reads(target, "ontological")

      expect { reading.machine_reading_for(target) }
        .to raise_error(described_class::Blinded, /measure anchoring/)
    end

    it "answers once the person has committed" do
      machine_reads(target, "ontological")
      reading.record!(target, category: category("interpretive"))

      expect(reading.machine_reading_for(target).category.key).to eq "ontological"
    end

    it "refuses just the same when the machine has read nothing" do
      expect { reading.machine_reading_for(target) }.to raise_error described_class::Blinded
    end

    it "keeps an unanswered claim out of the comparison entirely" do
      machine_reads(target, "ontological")
      answered = claim(2)
      reading.record!(answered, category: category("interpretive"))

      expect(reading.comparison.pairs.map(&:claim)).to eq [ answered ]
    end
  end

  describe "context" do
    # Context changes the answer — 65% alone against 87.9% in context — so a
    # person reading with a different amount of it is answering a different
    # question from the one the machine answered.
    it "shows the same window of preceding claims the classifier was given" do
      6.times { claim(it + 1) }
      sixth = document.claims.find_by!(position: 6)

      expect(reading.context_for(sixth).map(&:position)).to eq [ 2, 3, 4, 5 ]
    end

    it "gives the first claim no context rather than failing" do
      first = claim(1)

      expect(reading.context_for(first)).to be_empty
    end
  end

  describe "an abstention" do
    let(:target) { claim(1) }

    it "is a reading, so the queue moves on" do
      reading.abstain!(target)

      expect(reading.next_claim).to be_nil
      expect(reading.answered_count).to eq 1
    end

    # The bug this would otherwise introduce: a person saying "I cannot tell"
    # blanking a category three machine readings agreed on.
    it "leaves the machine's judgement standing" do
      machine_reads(target, "ontological", times: 3)

      reading.abstain!(target)

      expect(target.reload.category.key).to eq "ontological"
      expect(target.agreement.to_s).to eq "3 of 3"
    end

    it "is distinguishable from a claim nobody reached" do
      reached = claim(1)
      claim(2)
      reading.abstain!(reached)

      expect(reading.answered?(reached)).to be true
      expect(reading.answered?(document.claims.find_by!(position: 2))).to be false
    end
  end

  describe "the comparison" do
    it "rates agreement over claims both typed, and nothing else" do
      agreeing = claim(1)
      disagreeing = claim(2)
      machine_silent = claim(3)
      machine_reads(agreeing, "interpretive")
      machine_reads(disagreeing, "ontological")

      reading.record!(agreeing, category: category("interpretive"))
      reading.record!(disagreeing, category: category("interpretive"))
      reading.record!(machine_silent, category: category("objective"))

      c = reading.comparison

      expect(c.rate).to eq 0.5
      expect(c.agreed).to eq 1
      expect(c.human_only).to eq 1
      expect(c.both_typed.size).to eq 2
    end

    it "counts a claim only the machine typed separately from a disagreement" do
      only_machine = claim(1)
      machine_reads(only_machine, "ontological")
      reading.abstain!(only_machine)

      c = reading.comparison

      expect(c.machine_only).to eq 1
      expect(c.disagreed).to be_empty
      expect(c.rate).to be_nil
    end

    it "counts a claim neither could type" do
      reading.abstain!(claim(1))

      expect(reading.comparison.both_abstained).to eq 1
    end

    # A disagreement the reader was unsure about says something about the
    # category boundary; one they were sure about says something about the
    # classifier.
    it "separates the disagreements the reader was sure about" do
      sure = claim(1)
      unsure = claim(2)
      machine_reads(sure, "ontological")
      machine_reads(unsure, "ontological")

      reading.record!(sure, category: category("interpretive"))
      reading.record!(unsure, category: category("interpretive"), unsure: true)

      c = reading.comparison

      expect(c.disagreed.size).to eq 2
      expect(c.confident_disagreements.map(&:claim)).to eq [ sure ]
    end

    it "says which way the disagreements run" do
      2.times { |i| machine_reads(claim(i + 1), "ontological") }
      document.claims.each { reading.record!(it, category: category("interpretive")) }

      expect(reading.comparison.moves).to eq({ "ontological->interpretive" => 2 })
    end

    it "reports how firmly the machine held the reading it is being compared to" do
      target = claim(1)
      machine_reads(target, "ontological", times: 2)
      machine_reads(target, "interpretive")
      reading.record!(target, category: category("objective"))

      expect(reading.comparison.disagreed.first.machine_agreement.to_s).to eq "2 of 3"
    end
  end

  # A person's judgement outranks the machine's everywhere else in the system,
  # and typing a claim here is the same act.
  it "records the reading as the claim's classification" do
    target = claim(1)
    machine_reads(target, "ontological", times: 3)

    reading.record!(target, category: category("interpretive"), rationale: "it is a reading of the fact")

    expect(target.reload.category.key).to eq "interpretive"
    expect(target.classification.claim["rationale"]).to eq "it is a reading of the fact"
    expect(target.classifications.count).to eq 4
  end
end
