require "rails_helper"

# Route 1 rendered, with the conditions that make a figure comparable to a later
# one. The invariant under test is that the report never states a figure without
# what it was taken under, and never states the premise a step was judged under
# as the commitment its author held.
RSpec.describe PremiseReport do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:reader) { Referent.create!(key: "a-reader", name: "A Reader", primitive: "system") }
  let(:document) { Document.create!(body: "One. Two.", title: "probe", source_kind: "file") }

  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  def step(from_key, to_key)
    base = document.claims.count
    a = document.claims.create!(position: base + 1, text: "one")
    b = document.claims.create!(position: base + 2, text: "two")
    a.classify!(category(from_key), asserter: reader)
    b.classify!(category(to_key), asserter: reader)
    Transition.create!(source: a, target: b)
  end

  subject(:report) { described_class.render([ document.reload ], framework: framework) }

  describe "the conditions" do
    before { step("ontological", "normative") }

    it "names who read the claims, because the reader is a condition" do
      expect(report).to include("a-reader")
      expect(report).to include("The reader is a condition")
    end

    it "says how many readings a claim got" do
      expect(report).to match(/readings per claim \| 1\.0/)
    end

    # A category from one reading is a sample. The framework holds a claim to a
    # strict majority before it calls it typed, and a report that omitted this
    # would present a sample as a finding.
    it "warns when a single reading is standing in for a majority" do
      expect(report).to include("One reading per claim is a sample")
    end

    it "separates the revision it was rendered under from when the claims were written" do
      expect(report).to include("code revision at render")
      expect(report).to include("claims and identity flags date from here")
    end
  end

  describe "what it reports" do
    it "groups steps by what the framework charges for their crossing" do
      step("ontological", "normative")

      expect(report).to include("ontological → normative")
      expect(report).to include("Steps, by the premise their crossing declares")
    end

    it "says a step is undetermined rather than filling the absence in" do
      step("ontological", "normative")

      expect(report).to include("undetermined")
    end

    it "shows where two traditions price the same move differently" do
      lewisian = Framework.create!(key: "lewisian-1.0", name: "Lewisian", version: "1.0",
                                   current: false)
      framework.claim_categories.each do |c|
        ClaimCategory.create!(framework: lewisian, key: c.key, name: c.name, position: c.position,
                              justification_rank: c.justification_rank, definition: c.definition,
                              confidence_source: c.confidence_source)
      end
      mine = ClaimCategory.where(framework: lewisian).index_by(&:key)
      CategoryPromotion.where(framework: framework).includes(:from_category, :to_category).each do |p|
        pair = [ p.from_category.key, p.to_category.key ]
        CategoryPromotion.create!(framework: lewisian, from_category: mine[pair.first],
                                  to_category: mine[pair.last],
                                  weight: pair.sort == %w[normative ontological] ? 0 : p.weight)
      end
      step("ontological", "normative")

      rendered = described_class.render([ document.reload ], framework: framework,
                                                             comparators: [ lewisian ])

      expect(rendered).to include("Where the traditions part company")
      expect(rendered).to include("alexicon-2.0 2 · lewisian-1.0 0")
    end

    it "reports the identity lock, because a premise can be read but not ruled on" do
      step("ontological", "normative")

      expect(report).to include("Identity, and what it blocks")
      expect(report).to include("A STOP blocks governance")
    end
  end

  # The one thing the report must never let a reader conclude.
  it "carries the caveat, so the premise is never read as the author's commitment" do
    step("ontological", "normative")

    expect(report).to include("not the one its author held")
  end
end
