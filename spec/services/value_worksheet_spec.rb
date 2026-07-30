require "rails_helper"

# The control that was never run with a person in it. Three machine attempts at
# the value layer failed, and the recorded diagnosis — that the question has no
# ground truth in a found text — rests entirely on three models failing to answer
# it. That is a different claim, and nobody had been asked.
RSpec.describe ValueWorksheet do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:document) { Document.create!(body: "…") }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }
  let(:sentinel) { Referent.find_by!(key: "governance-sentinel") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def claim(text, kind)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    3.times { c.classify!(category(kind), asserter: classifier, confidence: 0.9) }
    c
  end

  # Far enough apart that a decoy can be drawn: the partner has to sit at least
  # SEPARATION positions away and carry the target's category.
  def populate(pairs: 3)
    steps = pairs.times.map do
      t = Transition.create!(source: claim("From #{_1}.", "interpretive"),
                             target: claim("To #{_1}.", "ontological"))
      t.record_verdict!("unearned", asserter: sentinel)
      t
    end
    described_class::SEPARATION.times { claim("Filler.", "ontological") }
    steps
  end

  describe "what the sheet is made of" do
    it "interleaves real steps with pairs the document never argued" do
      populate

      sheet = described_class.generate!(document, size: 6, seed: 1)

      expect(sheet.real_items).not_to be_empty
      expect(sheet.decoys).not_to be_empty
      expect(sheet.items.map(&:number)).to eq (1..sheet.items.size).to_a
    end

    it "draws a decoy from claims far apart, so it was never an argument" do
      populate

      sheet = described_class.generate!(document, size: 6, seed: 1)

      expect(sheet.decoys.map(&:transition_id)).to all(be_nil)
      expect(sheet.real_items.map(&:transition_id)).to all(be_present)
    end

    it "refuses to build a sheet from a document with nothing flagged" do
      claim("Nothing flagged here.", "observation")

      expect { described_class.generate!(document) }.to raise_error(described_class::NotEnoughSteps)
    end

    it "is reproducible from its seed, so a sheet can be rebuilt" do
      populate

      first = described_class.generate!(document, size: 6, seed: 7)
      second = described_class.generate!(document, size: 6, seed: 7)

      expect(first.items.map(&:real)).to eq second.items.map(&:real)
    end
  end

  # A key written afterwards would be worthless.
  describe "the key" do
    it "is recorded before anybody answers" do
      populate

      sheet = described_class.generate!(document, size: 6, seed: 1)

      expect(sheet.assertion.claim["worksheet"]).to eq described_class::KIND
      expect(sheet.assertion.claim["items"].size).to eq sheet.items.size
      expect(sheet.assertion).to be_readonly
    end

    it "refuses to score an assertion that is not a worksheet" do
      other = Assertion.create!(asserter: sentinel, subject: document, act: "assert", claim: {})

      expect { described_class.score(other, answers: {}) }
        .to raise_error(described_class::NotAWorksheet)
    end
  end

  describe "scoring" do
    let(:sheet) { populate and described_class.generate!(document, size: 6, seed: 1) }

    def answer(real:, decoy:)
      sheet.items.to_h { [ it.number, it.real? ? real : decoy ] }
    end

    it "reports a reader who tells them apart perfectly" do
      score = described_class.score(sheet.assertion, answers: answer(real: true, decoy: false))

      expect(score.real_rate).to eq 1.0
      expect(score.decoy_rate).to eq 0.0
      expect(score.standard_errors).to be > 2
    end

    # The failure being investigated: naming a commitment in everything.
    it "gives a reader who finds a conflict in everything a discrimination of zero" do
      score = described_class.score(sheet.assertion, answers: answer(real: true, decoy: true))

      expect(score.real_rate).to eq 1.0
      expect(score.decoy_rate).to eq 1.0
      expect(score.standard_errors).to eq 0.0
    end

    it "gives a reader who finds a conflict in nothing a discrimination of zero" do
      score = described_class.score(sheet.assertion, answers: answer(real: false, decoy: false))

      expect(score.standard_errors).to eq 0.0
    end

    # A blank is not a judgement. Counting one as "no conflict" would flatter
    # any reader who skipped the hard items.
    it "drops an unanswered item rather than reading it as no" do
      full = answer(real: true, decoy: false)
      partial = full.except(full.keys.first)

      score = described_class.score(sheet.assertion, answers: partial)

      expect(score.answered).to eq partial.size
      expect(score.real_total + score.decoy_total).to eq partial.size
    end

    it "ignores an answer to an item the sheet does not have" do
      score = described_class.score(sheet.assertion,
                                    answers: answer(real: true, decoy: false).merge(9999 => true))

      expect(score.answered).to eq sheet.items.size
    end
  end

  describe "the rendered sheet" do
    it "shows no machine reading of any pair" do
      populate
      sheet = described_class.generate!(document, size: 6, seed: 1)
      t = sheet.real_items.first.transition_id
      Assertion.create!(asserter: sentinel, subject: Transition.find(t), act: "assert",
                        claim: { "inference" => "step value", "protects" => "Fortitude",
                                 "subordinates" => "Insouciance", "confidence" => 0.97 })

      rendered = ValueWorksheetReport.render(sheet)

      expect(rendered).not_to include "Fortitude"
      expect(rendered).not_to include "Insouciance"
      expect(rendered).not_to include "0.97"
    end

    it "does not mark which items are decoys" do
      populate
      sheet = described_class.generate!(document, size: 6, seed: 1)

      rendered = ValueWorksheetReport.render(sheet)

      expect(rendered).to include "mixed in\n> deliberately and not marked"
      expect(rendered).not_to match(/decoy|shuffled|not an argument\b/i)
    end

    it "tells the reader that no is the expected answer" do
      populate
      sheet = described_class.generate!(document, size: 6, seed: 1)

      expect(ValueWorksheetReport.render(sheet))
        .to include "Most pairs have no conflict in them"
    end
  end
end
