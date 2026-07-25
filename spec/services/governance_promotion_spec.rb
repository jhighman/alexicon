require "rails_helper"

# What a move costs now has one source. Two encodings of the same idea drift,
# and the audit and the verdict disagreeing about what counts as a promotion
# would be the worst possible place for that to happen.
RSpec.describe "promotion has one source of truth" do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  let(:document) { Document.create!(body: "…") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

  def claim(text, kind)
    c = document.claims.create!(position: document.claims.count + 1, text: text)
    c.classify!(category(kind), asserter: person, confidence: 1.0)
    c
  end

  def judge(from_kind, to_kind)
    a = claim("From.", from_kind)
    b = claim("To.", to_kind)
    GovernanceSentinel.review!(Transition.create!(source: a, target: b))
  end

  it "calls a weighted move a promotion" do
    expect(judge("interpretive", "ontological").verdict).to eq "unearned"
  end

  it "does not call a lateral move a promotion" do
    expect(judge("objective", "observation").verdict).not_to eq "unearned"
  end

  it "does not call a retreat to firmer ground a promotion" do
    expect(judge("ontological", "observation").verdict).not_to eq "unearned"
  end

  # The migration's whole purpose: editing the seed reaches the verdict, not
  # just the audit.
  it "follows the seeded weight when it changes" do
    CategoryPromotion.find_by!(framework: framework,
                               from_category: category("interpretive"),
                               to_category: category("ontological")).update!(weight: 0)

    expect(judge("interpretive", "ontological").verdict).not_to eq "unearned"
  end

  # Governance and the audit must not disagree about what a promotion is.
  it "agrees with the audit on every ordered pair" do
    cats = ClaimCategory.where(framework: framework).to_a

    cats.permutation(2).each do |from, to|
      weight = CategoryPromotion.weight_for(from: from, to: to)
      heavy = weight.to_i > RetroactiveAudit::MAX_PROMOTION
      # Anything the audit calls heavy, governance must call a promotion.
      expect(weight.to_i.positive?).to be(true), "#{from.key}->#{to.key}" if heavy
    end
  end
end

# The migration's sharpest edge: an unweighted framework must not become a
# framework in which everything is earned.
RSpec.describe "an unweighted move" do
  before { seed_quietly }

  let(:framework) { Framework.create!(key: "unweighted", name: "Unweighted", version: "0") }
  let!(:sentinel) { Referent.find_by!(key: "governance-sentinel") }
  let(:document) { Document.create!(body: "…") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

  def category(key, rank)
    ClaimCategory.create!(framework: framework, key: key, name: key.capitalize, position: rank,
                          justification_rank: rank, definition: "…", confidence_source: "…")
  end

  it "is refused rather than judged earned" do
    low = category("low", 1)
    high = category("high", 3)
    a = document.claims.create!(position: 1, text: "One.")
    b = document.claims.create!(position: 2, text: "Two.")
    a.classify!(low, asserter: person)
    b.classify!(high, asserter: person)

    result = GovernanceSentinel.review!(Transition.create!(source: a, target: b))

    expect(result.verdict).to be_nil
    expect(result.reason).to match(/does not say what .* costs/)
  end
end
