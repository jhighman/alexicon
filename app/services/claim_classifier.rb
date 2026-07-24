# Proposes what kind of claim a statement is.
#
# This is the one place a language model is allowed to judge, and it is
# deliberately fenced:
#
#   * It PROPOSES. The proposal is recorded as an assertion by the classifier
#     referent -- an inference, attributable and challengeable, never a finding.
#   * It may ABSTAIN. "uncertain" is a first-class answer, and a proposal below
#     the confidence floor is discarded. An unclassified claim leaves its
#     transitions unjudged, which is the honest outcome.
#   * It does NOT govern. The Governance Sentinel rules on whether a promotion
#     was earned, and refuses to do so if it authored the classification --
#     Chapter 6's independence requirement, enforced in code.
#
# The abstention floor is a policy decision, not a cognitive necessity:
# prediction is unavoidable, but treating a prediction as operational truth is
# a choice. This is where that choice is made explicit and tunable.
#
# The categories are read from the seeded framework rather than hardcoded, so
# revising the taxonomy is a `db:seed` run and the prompt follows.
class ClaimClassifier
  MODEL = "claude-opus-5".freeze
  MAX_TOKENS = 1024
  EFFORT = "medium".freeze

  # Below this, the proposal is discarded rather than recorded.
  DEFAULT_CONFIDENCE_FLOOR = 0.75

  ABSTAIN = "uncertain".freeze

  Proposal = Data.define(:category_key, :confidence, :rationale, :abstained) do
    def abstained? = abstained
  end

  class MissingCredentials < StandardError; end

  def self.classify!(claim, asserter: nil, **) = new(claim, **).classify!(asserter: asserter)

  def initialize(claim, client: nil, framework: nil, confidence_floor: DEFAULT_CONFIDENCE_FLOOR)
    @claim = claim
    @client = client
    @framework = framework || Framework.current!
    @confidence_floor = confidence_floor
  end

  # Returns the proposal without recording anything.
  def call
    response = request
    parse(response)
  end

  # Records the proposal as an assertion, unless the classifier abstained.
  # Returns the assertion, or nil when nothing was recorded.
  def classify!(asserter: nil)
    proposal = call
    return nil if proposal.abstained?

    category = categories.find { it.key == proposal.category_key }
    return nil if category.nil?

    claim.classify!(category,
                    asserter: asserter || classifier_referent,
                    confidence: proposal.confidence,
                    rationale: proposal.rationale)
  end

  private

  attr_reader :claim, :framework, :confidence_floor

  def categories = @categories ||= framework.claim_categories.to_a

  def classifier_referent = Referent.find_by!(key: "claim-classifier")

  def client
    @client ||= begin
      key = ENV["ANTHROPIC_API_KEY"]
      raise MissingCredentials, "ANTHROPIC_API_KEY is not set" if key.blank?

      Anthropic::Client.new(api_key: key)
    end
  end

  def request
    client.messages.create(
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: system_prompt,
      messages: [ { role: "user", content: claim.text } ],
      output_config: { format: { type: "json_schema", schema: schema }, effort: EFFORT }
    )
  end

  # The model is told what the categories mean, that they differ in kind rather
  # than in rank, and that abstaining is a permitted answer.
  def system_prompt
    <<~PROMPT
      You classify a single statement by what KIND of claim it is.

      The categories differ in kind, not in rank. None outranks another, and
      merging them is the error this classification exists to prevent.

      #{categories.map { "- #{it.key}: #{it.definition} Confidence rests on: #{it.confidence_source.downcase}." }.join("\n")}

      Judge only the statement given. Do not judge whether it is true, whether
      you agree with it, or whether the speaker is justified in holding it.
      A false statement still has a category; so does one you find implausible.

      If the statement does not clearly belong to one category -- because it is
      ambiguous, fragmentary, or does more than one thing at once -- answer
      "#{ABSTAIN}". Abstaining is a correct answer and is preferred over a
      guess. Downstream governance treats an unclassified claim as unjudged,
      which is safe; it treats a wrong classification as a finding, which is not.

      State your confidence as a number between 0 and 1, and give a one-sentence
      rationale naming the feature of the statement that decided it.
    PROMPT
  end

  def schema
    {
      type: "object",
      properties: {
        category: { type: "string", enum: categories.map(&:key) + [ ABSTAIN ] },
        confidence: { type: "number" },
        rationale: { type: "string" }
      },
      required: %w[category confidence rationale],
      additionalProperties: false
    }
  end

  def parse(response)
    payload = JSON.parse(text_of(response))
    category = payload["category"]
    confidence = payload["confidence"].to_f
    rationale = payload["rationale"].to_s

    # Never trust the label without checking it against the seeded taxonomy --
    # the schema constrains the model, but the system verifies regardless.
    known = categories.any? { it.key == category }
    abstained = category == ABSTAIN || !known || confidence < confidence_floor

    Proposal.new(category_key: category, confidence: confidence,
                 rationale: rationale, abstained: abstained)
  rescue JSON::ParserError, TypeError
    Proposal.new(category_key: ABSTAIN, confidence: 0.0,
                 rationale: "classifier returned unparseable output", abstained: true)
  end

  def text_of(response)
    block = Array(response.content).find { it.type.to_s == "text" }
    block&.text.to_s
  end
end
