require "rails_helper"

RSpec.describe Entity do
  it "assigns a system_id on creation" do
    entity = described_class.create!(name: "Wednesday")

    expect(entity.system_id).to be_present
  end

  # Object constancy (Mahler): without a stable identity the system cannot tell
  # whether a claim changed or the subject did.
  it "refuses to let the system_id change" do
    entity = described_class.create!(name: "Wednesday")

    entity.system_id = SecureRandom.uuid

    expect(entity).not_to be_valid
    expect(entity.errors[:system_id].join).to include "immutable"
  end

  it "survives a rename with its identity intact" do
    entity = described_class.create!(name: "Wednesday", subject: "Family", role: "Sister")
    original = entity.system_id

    entity.update!(name: "Wednesday Addams", role: "Daughter")

    expect(entity.reload.system_id).to eq original
  end

  describe "#anchored?" do
    it "is true only with a complete passport" do
      expect(described_class.create!(name: "W", subject: "Family", role: "Sister")).to be_anchored
    end

    it "is false when a level is missing — a partial passport is no anchor" do
      expect(described_class.create!(name: "W", subject: "Family")).not_to be_anchored
      expect(described_class.create!(name: "W", role: "Sister")).not_to be_anchored
      expect(described_class.create!(name: "W")).not_to be_anchored
    end
  end

  it "renders the passport hierarchy" do
    entity = described_class.create!(name: "Wednesday", subject: "Family", role: "Sister")

    expect(entity.passport).to eq "Wednesday → Family → Sister"
  end
end
