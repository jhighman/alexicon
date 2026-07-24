# Proposes what kind of claim a statement is.
#
# This is the one place a language model is allowed to judge, and it is
# deliberately fenced:
#
#   * The model is RESOLVED, not chosen here. Which model answers is a
#     governed decision recorded in the registry, and an uncertified model is
#     unreachable — nobody's judgement runs because a constant said so.
#   * It PROPOSES. The proposal is recorded as an assertion by the classifier
#     referent — an inference, attributable and challengeable, never a finding.
#   * It may ABSTAIN. "uncertain" is a first-class answer, and a proposal below
#     the confidence floor is discarded. An unclassified claim leaves its
#     transitions unjudged, which is the honest outcome.
#   * It does NOT govern. The Governance Sentinel rules on whether a promotion
#     was earned, and refuses to do so if it authored the classification.
#   * Every call is RECORDED — model, tokens, cost, latency, outcome — in the
#     same transaction as the assertion it produced. A judgement with no
#     account of the call behind it is the gap this system refuses elsewhere.
#
# The abstention floor is a policy decision, not a cognitive necessity:
# prediction is unavoidable, but treating a prediction as operational truth is
# a choice. This is where that choice is made explicit and tunable.
class ClaimClassifier
  ACTION = "classify".freeze
  MAX_TOKENS = 1024
  EFFORT = "medium".freeze

  # Below this, the proposal is discarded rather than recorded.
  DEFAULT_CONFIDENCE_FLOOR = 0.75

  ABSTAIN = "uncertain".freeze

  Proposal = Data.define(:category_key, :confidence, :rationale, :abstained) do
    def abstained? = abstained
  end

  class MissingCredentials < StandardError; end
  class NoGovernedModel < StandardError; end

  def self.classify!(claim, asserter: nil, **) = new(claim, **).classify!(asserter: asserter)

  def initialize(claim, client: nil, framework: nil, confidence_floor: DEFAULT_CONFIDENCE_FLOOR)
    @claim = claim
    @client = client
    @framework = framework || Framework.current!
    @confidence_floor = confidence_floor
  end

  # Records the proposal as an assertion, unless the classifier abstained.
  # The invocation is recorded either way.
  def classify!(asserter: nil)
    resolution = resolve_model
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      response = request(resolution.model)
    rescue StandardError => e
      record_invocation(resolution, started: started, status: status_for(e), error: e.message)
      raise
    end

    proposal = parse(response)
    persist(proposal, resolution, response, started, asserter)
  end

  # The proposal alone, recording nothing.
  def call
    parse(request(resolve_model.model))
  end

  private

  attr_reader :claim, :framework, :confidence_floor

  def categories = @categories ||= framework.claim_categories.to_a

  def classifier_referent = @classifier_referent ||= Referent.find_by!(key: "claim-classifier")

  # Which model may answer is a governed decision, not a constant.
  def resolve_model
    resolution = LlmResolver.resolve(agent: classifier_referent, action_type: ACTION)
    raise NoGovernedModel, resolution.error unless resolution.resolved?

    resolution
  end

  # The adapter comes from the resolved model's provider, so which vendor is
  # called is a governed decision rather than a hardcoded client.
  def client_for(model) = @client || model.client

  def request(model)
    adapter = client_for(model)
    raise MissingCredentials, "no adapter for #{model.llm_provider.key}" if adapter.nil?

    adapter.complete(system: system_prompt, user: claim.text,
                     schema: schema, max_tokens: MAX_TOKENS)
  rescue LlmClients::MissingCredentials => e
    raise MissingCredentials, e.message
  end

  def persist(proposal, resolution, response, started, asserter)
    assertion = nil

    ActiveRecord::Base.transaction do
      unless proposal.abstained?
        category = categories.find { it.key == proposal.category_key }
        assertion = claim.classify!(category,
                                    asserter: asserter || classifier_referent,
                                    confidence: proposal.confidence,
                                    rationale: proposal.rationale) if category
      end

      record_invocation(resolution, started: started, status: "success",
                        response: response, assertion: assertion)
    end

    assertion
  end

  def record_invocation(resolution, started:, status:, response: nil, assertion: nil, error: nil)
    LlmInvocation.create!(
      llm_model: resolution.model,
      llm_assignment: resolution.assignment,
      agent: classifier_referent,
      assertion: assertion,
      action_type: ACTION,
      input_tokens: response&.input_tokens.to_i,
      output_tokens: response&.output_tokens.to_i,
      latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
      status: status,
      error_message: error
    )
  end

  def status_for(error)
    error.class.name.include?("Timeout") ? "timeout" : "error"
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
    payload = JSON.parse(response.text.to_s)
    category = payload["category"]
    confidence = payload["confidence"].to_f
    rationale = payload["rationale"].to_s

    # Never trust the label without checking it against the seeded taxonomy --
    # the schema constrains the model, but the system verifies regardless.
    known = categories.any? { it.key == category }
    abstained = category == ABSTAIN || !known || confidence < confidence_floor

    Proposal.new(category_key: category, confidence: confidence,
                 rationale: rationale, abstained: abstained)
  rescue JSON::ParserError, TypeError, NoMethodError
    Proposal.new(category_key: ABSTAIN, confidence: 0.0,
                 rationale: "classifier returned unparseable output", abstained: true)
  end
end
