require "rails_helper"

# ADR 22's acceptance criteria. `primitive` is authority configuration — it
# decides whose reading settles a claim and who may grant a delegation — so it
# is never inferred, never silently flipped, and changes only through an act
# that records who, from what, to what, and why.
RSpec.describe "authority is recognized, not inferred" do
  let(:jeff) { Referent.create!(name: "Jeff", subject: "Person", role: "Admin", primitive: "person") }
  let(:agent) { Referent.create!(name: "Agent", subject: "System", role: "Reviewer", primitive: "system") }
  let(:georgia) { Referent.create!(name: "Georgia", subject: "Place", role: "State", primitive: "entity") }

  # Criterion 1. The demonstrated silent flip is impossible.
  it "refuses a direct update of primitive" do
    expect { georgia.update!(primitive: "person") }
      .to raise_error(ActiveRecord::RecordInvalid, /only through recognition/)
    expect(georgia.reload.primitive).to eq "entity"
  end

  # Criterion 2.
  it "changes kind through recognition, recording who, from what, to what, and why" do
    concept = Referent.create!(name: "Alexicon", subject: "Concept", role: "Framework",
                               primitive: "person")

    concept.recognize_as!("entity", by: jeff, rationale: "a concept does not judge")

    expect(concept.reload.primitive).to eq "entity"
    record = concept.assertions.sole
    expect(record.asserter).to eq jeff
    expect(record.claim).to include("primitive" => "entity", "was" => "person",
                                    "rationale" => "a concept does not judge")
  end

  it "records nothing if the column write fails, and writes nothing if the record fails" do
    expect { georgia.recognize_as!("elder", by: jeff, rationale: "…") }
      .to raise_error(ArgumentError)
    expect(georgia.assertions).to be_empty
  end

  # Criterion 3. An agent cannot mint a person.
  it "refuses recognition from anything but a person" do
    expect { georgia.recognize_as!("person", by: agent, rationale: "let me in") }
      .to raise_error(Referent::RecognitionRefused, /agent cannot mint a person/)
    expect(georgia.reload.primitive).to eq "entity"
    expect(georgia.assertions).to be_empty
  end

  # Criterion 4. The undefined neither-decision-nor-inference state closes
  # while it has zero occupants.
  it "refuses an assertion authored by an entity" do
    assertion = Assertion.new(asserter: georgia, subject: jeff, act: "assert", claim: {})

    expect(assertion).not_to be_valid
    expect(assertion.errors[:asserter].sole).to match(/does not author/)
  end

  it "still lets an entity be a subject and an endpoint — it just cannot speak" do
    expect(Assertion.create!(asserter: jeff, subject: georgia, act: "assert",
                             claim: { "note" => "about a place" })).to be_persisted
  end

  # Criterion 7. Demotion removes settling and granting authority in the same
  # act that records it.
  it "removes authority by the same path that grants it" do
    impostor = Referent.create!(name: "Impostor", subject: "Concept", role: "Framework",
                                primitive: "person")
    expect(Assertion.new(asserter: impostor, subject: georgia, act: "assert", claim: {})).to be_valid

    grant = lambda do
      Delegation.new(agent_pattern: "x", act: "dispose_flag", granted_by: impostor,
                     rationale: "a spec exercising the person gate")
    end
    expect(grant.call).to be_valid

    impostor.recognize_as!("entity", by: jeff, rationale: "a concept does not judge")

    expect(Assertion.new(asserter: impostor, subject: georgia, act: "assert", claim: {}))
      .not_to be_valid
    expect(grant.call.tap(&:validate).errors[:granted_by].sole).to match(/must be a person/)
  end

  it "promotes by recognition, and the new person's readings then settle" do
    georgia_person = Referent.create!(name: "Georgia Reyes", subject: "Person", role: "Reviewer",
                                      primitive: "entity")
    georgia_person.recognize_as!("person", by: jeff, rationale: "mistyped at grounding")

    a = Assertion.create!(asserter: georgia_person.reload, subject: jeff, act: "assert", claim: {})
    expect(a).to be_human
  end
end
