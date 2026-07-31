require "rails_helper"

# A capital explained by position is not evidence that an unknown subject exists.
#
# The invariant under test is not that fewer names are proposed. It is that the
# extractor still proposes everything, and that what changes is whether the flag
# BLOCKS — because dropping a candidate in extraction is how a system silently
# reasons past a subject it has never met.
RSpec.describe "capitals explained by position" do
  before { seed_quietly }

  describe CasingEvidence do
    it "sees a word whose every capital sits at a sentence start" do
      evidence = described_class.new(
        "Distinct from Assertion, which is a row.\n**Distinct from Observation.**"
      )

      expect(evidence.only_ever_sentence_initial?("Distinct")).to be(true)
    end

    it "does not, once the word appears capitalised mid-sentence" do
      evidence = described_class.new("The Sentinel fires.\nSentinel is the name.")

      expect(evidence.only_ever_sentence_initial?("Sentinel")).to be(false)
    end

    it "reads through markdown decoration, which is not part of the word" do
      evidence = described_class.new("> **Judgment** operates over structures.\n- Judgment again.")

      expect(evidence.only_ever_sentence_initial?("Judgment")).to be(true)
    end

    # In "Michael Polanyi" the second capital is not explained by position at
    # all, so the evidence is still there and this rule has nothing to say.
    it "says nothing about a multi-word candidate" do
      evidence = described_class.new("Michael Polanyi wrote it. Michael Polanyi again.")

      expect(evidence.only_ever_sentence_initial?("Michael Polanyi")).to be(false)
    end

    it "says nothing about a word it never sees" do
      expect(described_class.new("nothing here").only_ever_sentence_initial?("Absent")).to be(false)
    end
  end

  describe IdentitySentinel do
    let(:document) { Document.create!(body: body) }
    let(:claim) { document.claims.create!(position: 1, text: document.body.lines.first.chomp) }

    def flag_for(text)
      mention = claim.mentions.create!(text: text, char_start: 0, char_end: text.length)
      described_class.verify!(mention)
      mention.flags.last
    end

    context "when position explains the capital" do
      let(:body) { "Distinct from Assertion, which is a row.\n**Distinct from Observation.**\n" }

      it "still proposes and still flags, so nothing is reasoned past silently" do
        flag = flag_for("Distinct")

        expect(flag).to be_present
        expect(flag.claim["noise"]).to be_present
      end

      it "raises a notice rather than a stop, so governance is not locked" do
        flag = flag_for("Distinct")

        expect(flag.severity).to eq("notice")
        expect(flag).not_to be_stop
        expect(document.reload).to be_executable
      end
    end

    context "when nothing explains the capital" do
      let(:body) { "The Sentinel fires here. A Sentinel is named.\n" }

      it "raises a stop and locks execution" do
        flag = flag_for("Sentinel")

        expect(flag.severity).to eq("stop")
        expect(document.reload).not_to be_executable
      end
    end
  end
end
