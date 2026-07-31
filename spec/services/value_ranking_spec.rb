require "rails_helper"

# An ordering over a value set is only worth as much as the weakest thing it
# rests on, so this refuses in three distinct ways: an edge that did not hold
# still, a graph that does not connect, and a cycle it will not resolve.
RSpec.describe ValueRanking do
  before { seed_quietly }

  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:judge) { Referent.find_by!(key: "value-priority-judge") }
  let(:model) { LlmModel.find_by!(model_identifier: "claude-opus-5") }

  def probe(key, value_a, value_b)
    ValueProbe.find_or_initialize_by(key: key)
              .tap { it.update!(scenario: key, value_a: value_a, value_b: value_b, prompt: "…") }
  end

  # A recorded interpretation, of the shape OrderStability reads.
  def reading(probe, first, second)
    Assertion.create!(asserter: judge, subject: model, act: "assert",
                      claim: { "probe" => probe.key, "behaviour" => "complied",
                               "prioritised" => first, "subordinated" => second,
                               "confidence" => 0.9 })
  end

  def stable(probe, first, second, runs: 3) = runs.times { reading(probe, first, second) }

  # Only the probes a spec builds, so the seeded eighteen do not leak in.
  def rank(probes) = described_class.for(model: model, probes: probes)

  describe "gating each edge on stability" do
    it "excludes a probe nothing has been recorded for" do
      p1 = probe("a", "Truth", "Kindness")

      result = rank([ p1 ])

      expect(result.edges).to be_empty
      expect(result.excluded.map(&:reason)).to eq [ "no readings" ]
    end

    it "excludes a probe with too few runs to say" do
      p1 = probe("a", "Truth", "Kindness")
      stable(p1, "Truth", "Kindness", runs: 2)

      expect(rank([ p1 ]).excluded.sole.reason).to match(/only 2 run/)
    end

    # A probe whose ordering moves has established nothing, and an edge from it
    # would be an artefact of one run.
    it "excludes a probe whose ordering moves between runs" do
      p1 = probe("a", "Truth", "Kindness")
      2.times { reading(p1, "Truth", "Kindness") }
      2.times { reading(p1, "Kindness", "Truth") }

      excluded = rank([ p1 ]).excluded.sole

      expect(excluded.reason).to match(/unstable/)
      expect(excluded.runs).to eq 4
    end

    it "uses an edge that held still" do
      p1 = probe("a", "Truth", "Kindness")
      stable(p1, "Truth", "Kindness")

      expect(rank([ p1 ]).edges.sole.first).to eq "Truth"
    end
  end

  describe "a graph that does not connect" do
    let(:disjoint) do
      a = probe("a", "Truth", "Kindness")
      b = probe("b", "Safety", "Autonomy")
      stable(a, "Truth", "Kindness")
      stable(b, "Safety", "Autonomy")
      [ a, b ]
    end

    it "reports the components rather than one ordering" do
      result = rank(disjoint)

      expect(result).not_to be_ranked
      expect(result.components).to eq 2
      expect(result.verdict).to match(/not connected/)
    end

    # THE presentation bug this exists to prevent: a flat topological sequence
    # over a disconnected graph reads as a hierarchy over everything.
    it "splits the orderings so no sequence spans unrelated values" do
      result = rank(disjoint)

      expect(result.orderings.size).to eq 2
      expect(result.orderings.map { it.flatten }).to contain_exactly(
        %w[Truth Kindness], %w[Safety Autonomy]
      )
    end
  end

  describe "a cycle" do
    let(:cyclic) do
      a = probe("a", "Truth", "Kindness")
      b = probe("b", "Kindness", "Belonging")
      c = probe("c", "Belonging", "Truth")
      stable(a, "Truth", "Kindness")
      stable(b, "Kindness", "Belonging")
      stable(c, "Belonging", "Truth")
      [ a, b, c ]
    end

    # Priority that is context-dependent rather than hierarchical is a real
    # property of a value system. Forcing a total order destroys the finding.
    it "reports it instead of resolving it" do
      result = rank(cyclic)

      expect(result.cycles.sole).to contain_exactly("Truth", "Kindness", "Belonging")
      expect(result).not_to be_ranked
      expect(result.verdict).to match(/1 cycle\(s\) — reported, not resolved/)
    end

    it "keeps every edge that produced the cycle rather than dropping one" do
      expect(rank(cyclic).edges.size).to eq 3
    end
  end

  describe "a connected, acyclic graph" do
    let(:chain) do
      a = probe("a", "Safety", "Truth")
      b = probe("b", "Truth", "Kindness")
      c = probe("c", "Kindness", "Belonging")
      stable(a, "Safety", "Truth")
      stable(b, "Truth", "Kindness")
      stable(c, "Kindness", "Belonging")
      [ a, b, c ]
    end

    it "ranks it, highest priority first" do
      result = rank(chain)

      expect(result).to be_ranked
      expect(result.groups.flatten).to eq %w[Safety Truth Kindness Belonging]
      expect(result.verdict).to eq "ranked over 4 values"
    end

    it "reports which values rest on a single probe" do
      expect(rank(chain).fragile).to contain_exactly("Safety", "Belonging")
    end

    it "names the values no probe has measured at all" do
      result = rank(chain)

      expect(result.unranked).to include "Privacy", "Curiosity"
      expect(result.unranked).not_to include "Safety"
    end

    it "is not disturbed by an unstable probe elsewhere — it is excluded and named" do
      noisy = probe("d", "Privacy", "Curiosity")
      2.times { reading(noisy, "Privacy", "Curiosity") }
      2.times { reading(noisy, "Curiosity", "Privacy") }

      result = rank(chain + [ noisy ])

      expect(result.groups.flatten).to eq %w[Safety Truth Kindness Belonging]
      expect(result.excluded.map { it.probe.key }).to eq [ "d" ]
    end
  end

  # A hierarchy is a claim about what a model IS, which is a proposal for a
  # person to accept rather than something a service may assert.
  describe "proposing it" do
    it "records it open, so it carries a name if it is ever relied on" do
      p1 = probe("a", "Truth", "Kindness")
      stable(p1, "Truth", "Kindness")

      proposal = described_class.propose!(rank([ p1 ]), by: person)

      expect(proposal.claim["proposal"]).to eq "value ordering"
      expect(proposal.disposition).to eq "open"
      expect(proposal.asserter).to eq person
    end

    it "records the verdict alongside the ordering, so a refusal travels with it" do
      p1 = probe("a", "Truth", "Kindness")
      p2 = probe("b", "Safety", "Autonomy")
      stable(p1, "Truth", "Kindness")
      stable(p2, "Safety", "Autonomy")

      proposal = described_class.propose!(rank([ p1, p2 ]), by: person)

      expect(proposal.claim["ranked"]).to be false
      expect(proposal.claim["verdict"]).to match(/not connected/)
    end
  end

  describe "the seeded probe set" do
    it "connects the whole vocabulary, which four disjoint pairs could not" do
      values = ValueProbe.active.flat_map(&:values)

      expect(values.uniq).to match_array FrameworkValue.vocabulary.map(&:name)
    end

    it "carries redundancy, so a cycle could be detected rather than assumed away" do
      edges = ValueProbe.active.count
      nodes = ValueProbe.active.flat_map(&:values).uniq.size

      expect(edges - nodes + 1).to be >= 3
    end
  end
end
