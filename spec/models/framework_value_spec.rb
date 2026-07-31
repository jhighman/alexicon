require "rails_helper"

# The Motivation domain has listed Values among its components since the
# framework was first seeded, and nothing instantiated one. This is where they
# live now.
RSpec.describe FrameworkValue do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:motivation) { Domain.find_by!(framework: framework, key: "motivation") }

  it "lives under the domain that always named it" do
    expect(motivation.components).to include "Values"
    expect(motivation.values).to be_present
    expect(described_class.vocabulary).to all(have_attributes(domain: motivation))
  end

  # The vocabulary was free text on the probes, so what a MODEL prioritised
  # under conflict and what a TEXT's step put first were incomparable by
  # construction. One list makes them the same currency.
  it "contains every value the probes already test against" do
    probed = ValueProbe.pluck(:value_a, :value_b).flatten.uniq

    expect(described_class.pluck(:name)).to include(*probed)
  end

  it "marks the values a model has actually been probed against as established" do
    expect(described_class.established.pluck(:name)).to match_array(
      [ "Autonomy", "Safety", "Truth", "Kindness", "Curiosity", "Privacy",
        "Expression", "Harm reduction" ]
    )
  end

  # This read `established == every value some probe names`, which held only
  # while the probe set happened to be exactly those eight. Fourteen probes were
  # later added to connect the vocabulary into a graph an ordering could be
  # derived from, and they name all sixteen.
  #
  # SEEDING A PROBE IS NOT RUNNING ONE. Provenance records where a value came
  # from — observed under conflict, or intuited — and writing a scenario for a
  # value does not observe anything. The two were conflated because they
  # coincided; adding the probes is what pulled them apart.
  it "does not promote a value to established merely because a probe names it" do
    named = ValueProbe.pluck(:value_a, :value_b).flatten.uniq
    unobserved = described_class.proposed.pluck(:name)

    expect(named).to include(*unobserved)
    expect(described_class.established.pluck(:name)).not_to include(*unobserved)
  end

  # A seeded list of what people protect is a claim about people. Marking which
  # entries are intuited is the same discipline the terminology register applies
  # to disputed terms.
  describe "provenance" do
    it "is carried in the data rather than in a comment" do
      expect(described_class.proposed).to be_present
      expect(described_class.established).to be_present
      expect(described_class.count).to eq described_class.proposed.count + described_class.established.count
    end

    it "refuses a provenance the record cannot account for" do
      value = described_class.new(framework: framework, domain: motivation, key: "x", name: "X",
                                  definition: "…", subordinates: "…", provenance: "derived")

      expect(value).not_to be_valid
      expect(value.errors[:provenance]).to be_present
    end

    it "says which entries are established" do
      expect(described_class.find_by!(key: "autonomy")).to be_established
      expect(described_class.find_by!(key: "generality")).not_to be_established
    end
  end

  # A value with nothing it sets aside is a preference, not a commitment. The
  # pair is what makes a reading arguable: "put X first over Y" can be
  # contested, "values X" cannot.
  it "requires something each value is put before" do
    value = described_class.new(framework: framework, domain: motivation, key: "x", name: "X",
                                definition: "…")

    expect(value).not_to be_valid
    expect(value.errors[:subordinates]).to be_present
  end

  it "gives every value something to subordinate" do
    expect(described_class.vocabulary.map(&:subordinates)).to all(be_present)
  end

  it "keeps a key unique within a framework" do
    duplicate = described_class.new(framework: framework, domain: motivation, key: "autonomy",
                                    name: "Autonomy again", definition: "…", subordinates: "…")

    expect(duplicate).not_to be_valid
  end

  it "presents itself in the form a judge would be shown" do
    expect(described_class.find_by!(key: "autonomy").to_s)
      .to eq "Autonomy — What a person decides for themselves."
  end

  it "offers its keys as a closed vocabulary" do
    keys = described_class.keys

    expect(keys).to include "autonomy", "generality", "coherence"
    expect(keys.uniq.size).to eq keys.size
  end
end
