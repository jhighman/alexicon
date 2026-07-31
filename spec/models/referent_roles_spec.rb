require "rails_helper"

# ADR 21's acceptance criteria, each one a spec. A role is a standing assertion
# about the referent — attributable, contestable, plural by construction — and
# the passport's third level is "at least one standing role".
RSpec.describe "a role is an assertion" do
  let(:referent) { Referent.create!(name: "Alexandra Krížová", subject: "Person", primitive: "person") }
  let(:jeff) { Referent.create!(name: "Jeff", subject: "Person", role: "Admin", primitive: "person") }
  let(:ana)  { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }

  # Criterion 1.
  it "holds three roles standing simultaneously, each with its own asserter" do
    referent.assert_role!("Collaborator", by: jeff)
    referent.assert_role!("Co-author", by: jeff)
    referent.assert_role!("Engineer", by: ana)

    expect(referent.roles).to eq [ "Collaborator", "Co-author", "Engineer" ]
    expect(referent.role_attributions).to eq(
      "Collaborator" => [ "Jeff" ], "Co-author" => [ "Jeff" ], "Engineer" => [ "Ana" ]
    )
  end

  # Criterion 2. Roles are deliberately NOT the contested machinery: two roles
  # do not contradict, so there is no majority to take. What can be disputed is
  # one role assertion, and disputing it unseats nothing.
  it "lets a challenge dispute one role and leaves the others standing" do
    engineer = referent.assert_role!("Engineer", by: jeff)
    referent.assert_role!("Caregiver", by: ana)

    Assertion.create!(asserter: ana, subject: engineer, act: "challenge",
                      claim: { "reason" => "not established" })

    expect(engineer).to be_challenged
    expect(referent.roles).to eq [ "Engineer", "Caregiver" ]
  end

  it "does not change the standing of the first role when a second is added" do
    first = referent.assert_role!("Collaborator", by: jeff)

    expect { referent.assert_role!("Engineer", by: ana) }
      .not_to change { first.reload.superseded_by.count }
  end

  # Criterion 3.
  it "retires a role by supersession, keeping both in the history" do
    engineer = referent.assert_role!("Engineer", by: jeff)
    Assertion.create!(asserter: jeff, subject: referent, act: "assert",
                      claim: { "retired" => "Engineer", "rationale" => "no longer holds" },
                      supersedes: engineer)

    expect(referent.roles).to be_empty
    expect(engineer.reload.claim["role"]).to eq "Engineer"
    expect(referent.assertions.count).to eq 2
  end

  # Criterion 4. A partial passport is not a weaker anchor — it is no anchor.
  it "is refused by the resolver as unanchored while no role stands" do
    result = ReferentResolver.new(claim_mention(referent.name)).call

    expect(result.status).to eq :unanchored
    expect(result.reason).to include "missing role"

    referent.assert_role!("Collaborator", by: jeff)

    expect(ReferentResolver.new(claim_mention(referent.name)).call.status).to eq :resolved
  end

  # Criterion 6, first half: a legacy referent renders exactly as it always
  # did — the passport string is unchanged.
  it "renders a legacy referent identically to before" do
    legacy = Referent.create!(name: "Mom", subject: "Person", role: "Mother", primitive: "person")

    expect(legacy.passport).to eq "Mom → Person → Mother"
    expect(legacy.roles).to eq [ "Mother" ]
    expect(legacy).to be_anchored
  end

  # Criterion 6, second half: the legacy value's attribution is absent, which
  # is a different fact from "nobody said it" and is reported as absent.
  it "reports a legacy role as unattributed rather than inventing an asserter" do
    legacy = Referent.create!(name: "Mom", subject: "Person", role: "Mother", primitive: "person")
    legacy.assert_role!("Grandmother", by: jeff)

    expect(legacy).to be_unattributed_role
    expect(legacy.role_attributions).to eq("Mother" => nil, "Grandmother" => [ "Jeff" ])
  end

  it "keeps the legacy value first and does not double a role asserted again" do
    legacy = Referent.create!(name: "Mom", subject: "Person", role: "Mother", primitive: "person")
    legacy.assert_role!("Mother", by: jeff)
    legacy.assert_role!("Grandmother", by: ana)

    expect(legacy.roles).to eq %w[Mother Grandmother]
    expect(legacy.role_attributions["Mother"]).to eq [ "Jeff" ]
  end

  # Criterion 7. #role survives for presentation only; behavior reads #roles or
  # nothing. The guard is textual because the temptation is textual: the next
  # convenient `referent.role` will be written in a service, and this fails.
  it "lets nothing behavioral read the singular role" do
    behavioral = Dir[Rails.root.join("app/{models,services,policies,jobs,graphql}/**/*.rb")]
    offenders = behavioral.select { File.read(it).match?(/referent\.role\b|\breferent&\.role\b/) }

    expect(offenders).to be_empty
  end

  it "still answers #role for display, preferring the legacy value" do
    referent.assert_role!("Engineer", by: jeff)

    expect(referent.role).to eq "Engineer"
    expect(Referent.new(name: "x", role: "Seeded").role).to eq "Seeded"
  end

  # Two people asserting the same role is agreement, not two roles.
  it "lists a role once however many people assert it" do
    referent.assert_role!("Engineer", by: jeff)
    referent.assert_role!("Engineer", by: ana)

    expect(referent.roles).to eq [ "Engineer" ]
    expect(referent.role_attributions["Engineer"]).to eq %w[Jeff Ana]
  end

  def claim_mention(text)
    doc = Document.create!(body: "…")
    doc.claims.create!(position: 1, text: "#{text} left.").mentions.create!(text: text)
  end
end
