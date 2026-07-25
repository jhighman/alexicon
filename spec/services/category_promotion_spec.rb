require "rails_helper"

# justification_rank gave three values to four categories, so the framework's
# central transition and an ordinary one both measured as +1. Weighting the
# ordered pair is what lets the audit see one without firing on the other.
RSpec.describe CategoryPromotion do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  describe "the seeded weights" do
    it "costs an ordinary promotion less than the one the framework polices" do
      ordinary = described_class.weight_for(from: category("objective"), to: category("interpretive"))
      central  = described_class.weight_for(from: category("interpretive"), to: category("ontological"))

      expect(central).to be > ordinary
    end

    # The two share justification_rank 1 — different in kind, equal in warrant.
    it "charges nothing for a move between objective and observation" do
      expect(described_class.weight_for(from: category("objective"), to: category("observation"))).to eq 0
      expect(described_class.weight_for(from: category("observation"), to: category("objective"))).to eq 0
    end

    it "charges nothing for a retreat to firmer ground" do
      expect(described_class.weight_for(from: category("ontological"), to: category("observation"))).to eq 0
      expect(described_class.weight_for(from: category("interpretive"), to: category("objective"))).to eq 0
    end

    # The asymmetry is the reason for weighting ordered pairs at all.
    it "is not symmetric" do
      up = described_class.weight_for(from: category("interpretive"), to: category("ontological"))
      down = described_class.weight_for(from: category("ontological"), to: category("interpretive"))

      expect(up).to eq 2
      expect(down).to eq 0
    end

    it "charges most for skipping the middle entirely" do
      expect(described_class.weight_for(from: category("observation"), to: category("ontological"))).to eq 3
    end

    it "weights every ordered pair of distinct categories" do
      keys = ClaimCategory.where(framework: framework).pluck(:key)
      pairs = keys.permutation(2).size

      expect(described_class.where(framework: framework).count).to eq pairs
    end
  end

  # "No rule for this pair" and "this pair costs nothing" are different, and
  # collapsing them would silently licence unweighted moves.
  it "answers nil for a pair the framework says nothing about" do
    other = Framework.create!(key: "other", name: "Other", version: "0")
    stray = ClaimCategory.create!(framework: other, key: "stray", name: "Stray", position: 1,
                                  justification_rank: 1, definition: "…", confidence_source: "…")

    expect(described_class.weight_for(from: stray, to: category("ontological"), framework: other))
      .to be_nil
  end

  it "answers nil rather than raising when a category is absent" do
    expect(described_class.weight_for(from: nil, to: category("ontological"))).to be_nil
  end

  it "refuses two weights for the same ordered pair" do
    duplicate = described_class.new(framework: framework, from_category: category("objective"),
                                    to_category: category("interpretive"), weight: 9)

    expect(duplicate).not_to be_valid
  end

  # Recalibrating is a seed change, not a migration.
  it "is data, so a weight can be changed without touching code" do
    promotion = described_class.find_by!(framework: framework,
                                         from_category: category("interpretive"),
                                         to_category: category("ontological"))
    promotion.update!(weight: 3)

    expect(described_class.weight_for(from: category("interpretive"),
                                      to: category("ontological"))).to eq 3
  end
end
