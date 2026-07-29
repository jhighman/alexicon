require "rails_helper"

# The read layer. What it is for is walking assertions about assertions in one
# request; what it must not become is a second way to write, or a way to read
# something the browser would refuse.
RSpec.describe "the graphql endpoint", type: :request do
  before { seed_quietly }

  let(:framework) { Framework.current! }
  let(:classifier) { Referent.find_by!(key: "claim-classifier") }
  let(:person) { Referent.create!(name: "Ana", subject: "Person", role: "Reviewer", primitive: "person") }
  let(:agent) do
    Referent.create!(key: "reader-agent", name: "Reader", subject: "System",
                     role: "Reviewer", primitive: "system")
  end

  def token_for(referent, role: "reviewer") = ApiToken.issue!(referent: referent, name: "spec", role: role)
  def auth(token) = { "Authorization" => "Bearer #{token.plaintext}" }
  def json = JSON.parse(response.body)
  def category(key) = ClaimCategory.find_by!(framework: framework, key: key)

  let(:token) { token_for(agent) }
  let(:document) { Document.create!(body: "…") }

  def claim(position, text = "Claim #{position}.")
    document.claims.create!(position: position, text: text)
  end

  def query(text, as: token)
    post api_v1_graphql_path, params: { query: text }, headers: auth(as)
  end

  describe "authentication" do
    it "refuses a request with no token" do
      post api_v1_graphql_path, params: { query: "{ categories { key } }" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "reads with a live token" do
      query("{ categories { key name } }")

      expect(json.dig("data", "categories").map { it["key"] })
        .to match_array framework.claim_categories.map(&:key)
    end
  end

  # The reason the layer exists.
  describe "walking the recursion" do
    it "returns assertions about assertions in one request" do
      target = claim(1)
      flag = Assertion.create!(asserter: classifier, subject: target, act: "flag",
                               claim: { "severity" => "stop" })
      Assertion.create!(asserter: person, subject: flag, act: "reject", claim: {})

      query("{ assertion(id: #{flag.id}) { act assertions { act asserter { name primitive } } } }")

      about = json.dig("data", "assertion", "assertions")
      expect(json.dig("data", "assertion", "act")).to eq "flag"
      expect(about.first).to include("act" => "reject")
      expect(about.first.dig("asserter", "primitive")).to eq "person"
    end

    it "names what an assertion is about, whatever kind of thing that is" do
      target = claim(1, "The wall fell.")
      a = Assertion.create!(asserter: classifier, subject: target, act: "flag",
                            claim: { "severity" => "notice" })

      query("{ assertion(id: #{a.id}) { subjectType subjectLabel } }")

      expect(json.dig("data", "assertion"))
        .to include("subjectType" => "Claim", "subjectLabel" => "The wall fell.")
    end

    # Unbounded by construction, so the cap is not boilerplate.
    it "refuses a query that nests past the cap" do
      a = Assertion.create!(asserter: classifier, subject: claim(1), act: "flag",
                            claim: { "severity" => "notice" })
      deep = "{ assertion(id: #{a.id}) #{'{ assertions ' * 14}{ id }#{' }' * 14} }"

      query(deep)

      expect(json["errors"].first["message"]).to match(/exceeds max depth of 12/)
    end
  end

  describe "derived values" do
    it "reports a claim's category and how firmly it is held" do
      target = claim(1)
      3.times { target.classify!(category("interpretive"), asserter: classifier, confidence: 0.9) }

      query("{ claim(id: #{target.id}) { category { key } agreement { description unanimous } } }")

      expect(json.dig("data", "claim", "category", "key")).to eq "interpretive"
      expect(json.dig("data", "claim", "agreement"))
        .to include("description" => "3 of 3", "unanimous" => true)
    end

    # A blind reading is a second opinion, not a further vote, and the two
    # figures must be separately readable or the distinction is invisible here.
    it "separates the classifier's tally from a blind reader's opinion" do
      target = claim(1)
      3.times { target.classify!(category("ontological"), asserter: classifier, confidence: 0.9) }
      target.classify!(category("normative"), asserter: agent, confidence: 1.0, blind: true)

      query("{ claim(id: #{target.id}) { machineAgreement { description category { key } } " \
            "classifications { blind } } }")

      expect(json.dig("data", "claim", "machineAgreement", "category", "key")).to eq "ontological"
      expect(json.dig("data", "claim", "machineAgreement", "description")).to eq "3 of 3"
      expect(json.dig("data", "claim", "classifications").count { it["blind"] }).to eq 1
    end

    it "reports a step's verdict, which is derived and never stored" do
      a, b = claim(1), claim(2)
      a.classify!(category("interpretive"), asserter: classifier, confidence: 0.9)
      b.classify!(category("ontological"), asserter: classifier, confidence: 0.9)
      step = Transition.create!(source: a, target: b)
      step.record_verdict!("unearned", asserter: Referent.find_by!(key: "governance-sentinel"))

      query("{ document(id: #{document.id}) { transitions { verdict categoryChange } } }")

      expect(json.dig("data", "document", "transitions").first)
        .to include("verdict" => "unearned", "categoryChange" => true)
    end
  end

  describe "what it will not do" do
    it "has no mutation root at all" do
      expect(AlexiconSchema.mutation).to be_nil
    end

    it "rejects a mutation rather than ignoring it" do
      query("mutation { anything }")

      expect(json["errors"].first["message"]).to match(/not configured for mutations/)
    end

    it "refuses a viewer nothing, since reading is what a viewer may do" do
      claim(1)

      query("{ documents { id } }", as: token_for(person, role: "viewer"))

      expect(json.dig("data", "documents")).to be_present
    end

    # The one capability question inside the schema: a measurement about the
    # model is not something every role may read.
    it "refuses a baseline to a role that may not see the model registry" do
      query('{ baseline(version: "v1") { criterion } }')

      expect(json["errors"].first["message"]).to match(/model registry/)
    end

    it "returns one to a role that may" do
      Baseline.record!(version: "v9", criterion: "a measurement", model: LlmModel.first,
                       measured: { rate: 0.5 }, sample: {}, conditions: { categories: 5 },
                       caveats: [ "one document" ])

      query('{ baseline(version: "v9") { criterion rate caveats conditions } }', as: token_for(agent, role: "auditor"))

      measurement = json.dig("data", "baseline").first
      expect(measurement).to include("criterion" => "a measurement", "rate" => 0.5)
      expect(measurement["caveats"]).to eq [ "one document" ]
      expect(measurement["conditions"]).to eq({ "categories" => 5 })
    end
  end
end
