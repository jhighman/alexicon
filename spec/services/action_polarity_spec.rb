require "rails_helper"

# Column D of the G3/G7 Matrix: verbs as forces, not decoration. The Freud
# mapping is the whole difficulty — a surface negation can carry the intent it
# appears to deny, so reading polarity off the grammar is exactly what must not
# be done silently.
RSpec.describe "action polarity" do
  before { seed_quietly }

  describe ClaimPolarity do
    def read(text) = described_class.for(text)

    it "reads a plain assertion and a plain denial" do
      expect(read("The wall represented fear.")).to be_asserted
      expect(read("The wall did not represent fear.")).to be_denied
    end

    it "reads contractions as negation" do
      expect(read("It wasn't the wall.")).to be_denied
      expect(read("He can't remember.")).to be_denied
    end

    it "never claims to know what was meant" do
      expect(read("The wall fell.")).to be_surface_only
    end

    # The case the manuscript names: "Nechceš kávu?" is an offer, and an
    # English-shaped frame reads it as refusal.
    it "refuses to trust a negative question" do
      reading = read("Don't you want coffee?")

      expect(reading).to be_questioned
      expect(reading).not_to be_reliable
      expect(reading.reason).to include "negative question"
    end

    it "refuses to trust a double negative" do
      expect(read("I never said nothing.")).not_to be_reliable
    end

    it "refuses to trust a negated modal" do
      expect(read("You should not proceed.")).not_to be_reliable
      expect(read("She cannot have known.")).not_to be_reliable
    end

    it "trusts a plain question with no negation in it" do
      expect(read("Did the wall fall?")).to be_reliable
    end

    # Prefix negation is not syntactic negation.
    it "does not read a negative prefix as a denial" do
      expect(read("He was unhappy.")).to be_asserted
    end

    # KNOWN LIMITATION, pinned so it stays visible rather than being forgotten.
    # Detecting this needs a lexicon of negative-prefixed words, and no
    # structural rule separates "uncommon" from "understood" or "universe".
    it "does not catch litotes, and this is a recorded miss" do
      reading = read("It is not uncommon.")

      expect(reading).to be_denied
      expect(reading).to be_reliable, "if this now fails, litotes detection was added — update the note"
    end
  end

  describe SituationalSentinel do
    let(:document) { Document.create!(body: "…") }
    def claim(text) = document.claims.create!(position: document.claims.count + 1, text: text)

    it "says nothing when the grammar can be trusted" do
      expect(described_class.review!(claim("The wall fell."))).to be_nil
    end

    it "raises a concern where grammar and intent are known to come apart" do
      flag = described_class.review!(claim("Don't you want coffee?"))

      expect(flag.severity).to eq "concern"
      expect(flag.message).to include "may carry the intent it appears to deny"
      expect(flag.asserter.key).to eq "situational-sentinel"
    end

    # An unreadable direction does not make a document ungroundable the way an
    # unresolved name does: nothing is predicating a direction of anything yet.
    it "never raises a STOP" do
      c = claim("Don't you want coffee?")
      described_class.review!(c)

      expect(document.reload.open_stops).to be_empty
      expect(document).to be_executable
    end

    it "records what it read and why it distrusted it" do
      flag = described_class.review!(claim("You should not proceed."))

      expect(flag.claim["surface_polarity"]).to eq "denied"
      expect(flag.claim["unreliable"]).to include "negated_modal"
    end

    it "raises one flag per claim however often it is reviewed" do
      c = claim("Don't you want coffee?")

      expect { 3.times { described_class.review!(c) } }
        .to change { c.assertions.flags.count }.by(1)
    end

    it "leaves headings alone" do
      document.claims.create!(position: 99, text: "Part One", structural: true)

      expect(described_class.review_document!(document.reload)).to be_empty
    end
  end

  # The enforceable form of Column D's claim about categories. Unlike "is the
  # classifier correct", this one can be checked.
  describe PolarityInvariance do
    # A classifier that reads what a claim DOES: category by form, not content.
    def by_form
      ->(text) { text.match?(/represent|mean|symbol/i) ? "interpretive" : "observation" }
    end

    # A classifier that reads what a claim SAYS, and so moves under negation.
    def by_content
      ->(text) { ClaimPolarity.for(text).denied? ? "objective" : "interpretive" }
    end

    it "holds for a classifier that types by what the claim does" do
      result = described_class.check(by_form, text: "The wall is representing fear.")

      expect(result).to be_holds
      expect(result.negated).to eq "The wall is not representing fear."
      expect(result.violation).to be_nil
    end

    it "fails, with the categories named, for one that types by content" do
      result = described_class.check(by_content, text: "The wall is representing fear.")

      expect(result).not_to be_holds
      expect(result.violation).to eq "category moved from interpretive to objective under negation"
    end

    describe "when no negation can be constructed" do
      it "abstains rather than paraphrasing" do
        result = described_class.check(by_form, text: "Collapsing walls everywhere.")

        expect(result).not_to be_checked
        expect(result.skipped).to match(/no structural negation/)
        expect(result).to be_holds
      end

      it "will not negate an already-negated claim into a double negative" do
        expect(described_class.check(by_form, text: "The wall is not fear.")).not_to be_checked
      end

      it "will not negate a question" do
        expect(described_class.check(by_form, text: "Is the wall fear?")).not_to be_checked
      end
    end

    it "negates after an auxiliary when there is no copula" do
      result = described_class.check(by_form, text: "The wall has represented fear.")

      expect(result.negated).to eq "The wall has not represented fear."
    end

    it "costs exactly two classifications" do
      calls = 0
      counting = ->(_t) { calls += 1; "observation" }

      described_class.check(counting, text: "The wall is fear.")

      expect(calls).to eq 2
    end
  end
end
