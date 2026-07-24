require "rails_helper"

# The resolver's three non-resolving outcomes map onto the framework's three
# detection criteria for Entity Noise.
RSpec.describe EntityResolver do
  let(:document) { Document.create!(body: "…") }
  let(:claim)    { document.claims.create!(position: 1, text: "Wednesday left.") }

  def mention(text) = claim.mentions.create!(text: text)

  def entity(name, subject: "Family", role: "Sister")
    Entity.create!(name: name, subject: subject, role: role)
  end

  describe "resolution" do
    it "resolves a unique match with a complete passport" do
      addams = entity("Wednesday")

      result = described_class.new(mention("Wednesday")).call

      expect(result).to be_resolved
      expect(result.entity).to eq addams
    end

    it "matches case-insensitively" do
      entity("Wednesday")

      expect(described_class.new(mention("wednesday")).call).to be_resolved
    end

    it "resolves through a declared alias" do
      addams = entity("Wednesday Addams")
      addams.entity_aliases.create!(name: "Wednesday")

      result = described_class.new(mention("Wednesday")).call

      expect(result.entity).to eq addams
    end
  end

  describe "out_of_distribution — no match in memory" do
    it "flags an identifier that matches nothing" do
      result = described_class.new(mention("Pugsley")).call

      expect(result.status).to eq :out_of_distribution
      expect(result.reason).to include "matches no known entity"
    end

    # A blank mention cannot be persisted -- Mention validates presence. The
    # guard covers an unsaved record reaching the resolver, and fails closed.
    it "does not invent a referent for blank text" do
      result = described_class.new(Mention.new(claim: claim, text: " ")).call

      expect(result.status).to eq :out_of_distribution
      expect(result.entity).to be_nil
    end
  end

  describe "ambiguous — attention-map dispersion" do
    it "refuses when several entities share a surface form" do
      entity("Wednesday", role: "Sister")
      entity("Wednesday", subject: "Organisation", role: "Venue")

      result = described_class.new(mention("Wednesday")).call

      expect(result.status).to eq :ambiguous
      expect(result.candidates.size).to eq 2
      expect(result.reason).to include "2 candidate entities"
    end

    # A single entity match does not establish the referent when the surface
    # form is known to carry non-entity senses.
    it "refuses a lone match reached through a form with non-entity senses" do
      addams = entity("Wednesday Addams")
      addams.entity_aliases.create!(name: "Wednesday", ambiguous: true)

      result = described_class.new(mention("Wednesday")).call

      expect(result.status).to eq :ambiguous
      expect(result.reason).to include "non-entity senses"
    end
  end

  describe "unanchored — Cognitive Passport could not be assigned" do
    it "refuses an entity with no role" do
      entity("Wednesday", role: nil)

      result = described_class.new(mention("Wednesday")).call

      expect(result.status).to eq :unanchored
      expect(result.reason).to include "missing role"
    end

    it "names every missing level" do
      entity("Wednesday", subject: nil, role: nil)

      result = described_class.new(mention("Wednesday")).call

      expect(result.reason).to include "missing subject and role"
    end
  end
end
