require "rails_helper"

# The unit judgment waits for. The invariant under test is not a gate a judge
# remembers to check — it is that a case which has not closed cannot be
# constructed, so nothing can be asked about it.
RSpec.describe Case do
  let(:document) { Document.create!(body: "…") }

  def claim(text, structural: false)
    document.claims.create!(position: document.claims.count + 1, text: text,
                            structural: structural)
  end

  def build_document(*rows)
    rows.each { |text| text.start_with?("#") ? claim(text, structural: true) : claim(text) }
  end

  describe "deriving the episodes" do
    it "splits at structural claims, which is where an argument restarts" do
      build_document("a", "b", "# heading", "c", "d")

      cases = described_class.derive!(document)

      expect(cases.size).to eq 2
      expect(cases.map { [ it.opening.text, it.closing.text ] }).to eq [ %w[a b], %w[c d] ]
    end

    it "keeps the structural claim itself outside every case" do
      build_document("a", "b", "# heading", "c", "d")

      described_class.derive!(document).each do |kase|
        expect(kase.claims.map(&:text)).not_to include "# heading"
      end
    end

    it "is idempotent — re-deriving finds the same cases rather than minting more" do
      build_document("a", "b", "# heading", "c", "d")

      described_class.derive!(document)

      expect { described_class.derive!(document) }.not_to change(described_class, :count)
    end

    # A run of one claim has no step inside it for an ending to reinterpret.
    it "does not make a case of a single claim" do
      build_document("a", "# heading", "b", "c")

      expect(described_class.derive!(document).size).to eq 1
    end

    it "closes the final run of a complete document at the document's end" do
      build_document("a", "b", "c")

      kase = described_class.derive!(document).sole

      expect(kase.closing.text).to eq "c"
    end
  end

  # THE invariant. In a document still being written, the final run has no
  # established right boundary — it is not an episode yet, and judgment must
  # not outrun closure. That is enforced by construction: the case does not
  # come into existence, so there is nothing to ask about.
  describe "closure as the constructor" do
    it "withholds the final run of a growing document" do
      build_document("a", "b", "# heading", "c", "d")

      cases = described_class.derive!(document, complete: false)

      expect(cases.size).to eq 1
      expect(cases.sole.closing.text).to eq "b"
    end

    it "still closes a growing document's run whose boundary is structural" do
      build_document("a", "b", "# heading")

      expect(described_class.derive!(document, complete: false).size).to eq 1
    end
  end

  describe "what a case contains" do
    before { build_document("a", "b", "c", "# end") }

    let(:kase) { described_class.derive!(document).sole }

    it "spans its claims in order" do
      expect(kase.claims.map(&:text)).to eq %w[a b c]
    end

    it "holds the steps whose both feet are inside it" do
      inside = Transition.create!(source: document.claims.first, target: document.claims.second)
      other = Document.create!(body: "…")
      elsewhere = Transition.create!(source: other.claims.create!(position: 1, text: "x"),
                                     target: other.claims.create!(position: 2, text: "y"))

      expect(kase.steps).to include inside
      expect(kase.include?(inside)).to be true
      expect(kase.include?(elsewhere)).to be false
    end
  end

  it "is a Relationship, so it can be asserted about like any other edge" do
    build_document("a", "b")
    kase = described_class.derive!(document).sole

    expect(kase).to be_a Relationship
    expect(kase.kind).to eq "case_closure"
    expect { Assertion.create!(asserter: Referent.create!(name: "Ana", subject: "Person",
                                                          role: "Reviewer", primitive: "person"),
                               subject: kase, act: "assert", claim: {}) }.not_to raise_error
  end
end
