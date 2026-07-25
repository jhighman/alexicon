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
  #
  # MEASURED INERT on the model currently routed here: zero of 242 proposals
  # fell below it, mean confidence 0.94-0.99 by category, 171 of them at exactly
  # 1.0. It has never rejected anything.
  #
  # Kept rather than removed, because it is a POLICY and not a tuning parameter.
  # Setting it from this model's distribution would make it a description of one
  # provider rather than a statement about what this system will act on, and the
  # registry can route to a model that does emit varied confidence tomorrow.
  #
  # What was wrong was the silence: a floor that never fires reads as a working
  # guard. `floor_effectiveness` reports what it has actually done, so the
  # assurance it appears to give can be checked rather than assumed.
  DEFAULT_CONFIDENCE_FLOOR = 0.75

  ABSTAIN = "uncertain".freeze

  Proposal = Data.define(:category_key, :confidence, :rationale, :abstained) do
    def abstained? = abstained
  end

  class MissingCredentials < StandardError; end
  class NoGovernedModel < StandardError; end

  # Claims are sent in batches with the run of text they sit in. One sentence
  # per call threw away the argument it belonged to -- and it showed: every
  # confidence came back 1.0, because there was nothing to be uncertain about.
  # An abstention floor only means something if the model can see enough to
  # doubt itself.
  BATCH_SIZE = 12

  # Claims immediately before the batch, sent as already-read context. The model
  # types only the batch; these are there so it knows what "It" refers to.
  CONTEXT_CLAIMS = 4

  def self.classify!(claim, asserter: nil, **) = new(claim, **).classify!(asserter: asserter)

  # What the confidence floor has actually rejected.
  #
  # A guard nobody has measured is a guard nobody should rely on. If `rejected`
  # is zero over a large `proposals`, the floor is not filtering — the refusal
  # doing the work is the model's own abstention, and any claim that weak
  # proposals are being caught is false.
  FloorEffect = Data.define(:proposals, :rejected, :floor, :min_confidence) do
    def inert? = proposals.positive? && rejected.zero?
    def rate = proposals.zero? ? nil : (rejected.to_f / proposals).round(4)

    def to_s
      return "no classifications recorded" if proposals.zero?

      "#{rejected} of #{proposals} rejected by a floor of #{floor}" \
        "#{inert? ? " — inert; lowest confidence seen was #{min_confidence}" : ''}"
    end
  end

  def self.floor_effectiveness(document: nil, floor: DEFAULT_CONFIDENCE_FLOOR)
    scope = Assertion.acting("classify").standing
    scope = scope.where(subject: document.claims) if document

    confidences = scope.filter_map(&:confidence)
    FloorEffect.new(proposals: confidences.size,
                    rejected: confidences.count { it < floor },
                    floor: floor, min_confidence: confidences.min)
  end

  Readiness = Data.define(:model, :problem) do
    def ready? = problem.nil?
  end

  # Can a classification actually run right now, and if not, why?
  #
  # Asked before queueing work, so a reviewer is told what is missing instead of
  # watching a job fail silently. It resolves the model rather than assuming
  # one: which provider answers is a governed decision, so naming a vendor here
  # would be this code overriding the registry.
  def self.readiness
    agent = Referent.find_by(key: "claim-classifier")
    return Readiness.new(model: nil, problem: "the classifier referent is missing — reseed") if agent.nil?

    resolution = LlmResolver.resolve(agent: agent, action_type: ACTION)
    return Readiness.new(model: nil, problem: resolution.error) unless resolution.resolved?

    provider = resolution.model.llm_provider
    return Readiness.new(model: resolution.model, problem: nil) if provider.credentialed?

    Readiness.new(model: resolution.model,
                  problem: "#{resolution.model.display_name} would answer, but #{provider.name} " \
                           "has no API key — set one on the Providers page, or export " \
                           "#{provider.credential_env}")
  end

  def initialize(claims, client: nil, framework: nil, confidence_floor: DEFAULT_CONFIDENCE_FLOOR,
                 context: [])
    @claims = Array(claims)
    @context = Array(context)
    @client = client
    @framework = framework || Framework.current!
    @confidence_floor = confidence_floor
  end

  # Records the proposal as an assertion, unless the classifier abstained.
  # The invocation is recorded either way.
  # Returns { claim => assertion-or-nil }, or a single assertion when a single
  # claim was given, so the common one-claim call reads as it always did.
  def classify!(asserter: nil)
    resolution = resolve_model
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      response = request(resolution.model)
    rescue StandardError => e
      record_invocation(resolution, started: started, status: status_for(e), error: e.message)
      raise
    end

    results = persist(parse(response), resolution, response, started, asserter)
    single? ? results.values.first : results
  end

  # The proposals alone, recording nothing.
  def call
    proposals = parse(request(resolve_model.model))
    single? ? proposals.values.first : proposals
  end

  private

  attr_reader :claims, :context, :framework, :confidence_floor

  def single? = claims.one?

  def claim = claims.first

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

    adapter.complete(system: system_prompt, user: user_prompt,
                     schema: schema, max_tokens: MAX_TOKENS * claims.size)
  rescue LlmClients::MissingCredentials => e
    raise MissingCredentials, e.message
  end

  def persist(proposals, resolution, response, started, asserter)
    results = {}

    ActiveRecord::Base.transaction do
      invocation = record_invocation(resolution, started: started, status: "success",
                                     response: response)

      claims.each do |c|
        proposal = proposals[c]
        results[c] = nil
        next if proposal.nil? || proposal.abstained?

        category = categories.find { it.key == proposal.category_key }
        next if category.nil?

        results[c] = c.classify!(category,
                                 asserter: asserter || classifier_referent,
                                 confidence: proposal.confidence,
                                 rationale: proposal.rationale,
                                 invocation: invocation)
      end
    end

    results
  end

  def record_invocation(resolution, started:, status:, response: nil, error: nil)
    LlmInvocation.create!(
      llm_model: resolution.model,
      llm_assignment: resolution.assignment,
      agent: classifier_referent,
      action_type: ACTION,
      input_tokens: response&.input_tokens.to_i,
      output_tokens: response&.output_tokens.to_i,
      latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
      status: status,
      error_message: error
    )
  end

  # The invocation record should say what kind of failure it was, because the
  # kinds call for different responses: throttling means slow down, a rejected
  # request means fix the request.
  def status_for(error)
    case error
    when LlmClients::RateLimited then "rate_limited"
    when LlmClients::ConnectionFailed then "timeout"
    else error.class.name.include?("Timeout") ? "timeout" : "error"
    end
  end

  # The model is told what the categories mean, that they differ in kind rather
  # than in rank, and that abstaining is a permitted answer.
  def system_prompt
    <<~PROMPT
      You classify statements by what KIND of claim each one is.

      The categories differ in kind, not in rank. None outranks another, and
      merging them is the error this classification exists to prevent.

      #{categories.map { "- #{it.key}: #{it.definition} Confidence rests on: #{it.confidence_source.downcase}." }.join("\n")}

      You are given a short run of preceding text as CONTEXT, then the numbered
      statements TO CLASSIFY. Classify only the numbered ones. The context is
      there so you can tell what a pronoun or a "therefore" is doing; it is not
      itself to be judged.

      Judge only what each statement does. Do not judge whether it is true,
      whether you agree with it, or whether the speaker is justified in holding
      it. A false statement still has a category; so does one you find
      implausible.

      If a statement does not clearly belong to one category -- because it is
      ambiguous, fragmentary, or does more than one thing at once -- answer
      "#{ABSTAIN}" for it. Abstaining is a correct answer and is preferred over
      a guess. Downstream governance treats an unclassified claim as unjudged,
      which is safe; it treats a wrong classification as a finding, which is not.

      Give each statement a confidence between 0 and 1 and a one-sentence
      rationale naming the feature that decided it. Confidence should reflect
      real uncertainty: a fragment read out of a longer argument deserves less
      than a self-contained assertion. Answer every number exactly once.
    PROMPT
  end

  def user_prompt
    parts = []
    if context.any?
      parts << "CONTEXT (already read, do not classify)"
      parts << context.map { "- #{it.text}" }.join("\n")
      parts << ""
    end
    parts << "TO CLASSIFY"
    parts << claims.each_with_index.map { |c, i| "#{i + 1}. #{c.text}" }.join("\n")
    parts.join("\n")
  end

  def schema
    {
      type: "object",
      properties: {
        classifications: {
          type: "array",
          items: {
            type: "object",
            properties: {
              number: { type: "integer" },
              category: { type: "string", enum: categories.map(&:key) + [ ABSTAIN ] },
              confidence: { type: "number" },
              rationale: { type: "string" }
            },
            required: %w[number category confidence rationale],
            additionalProperties: false
          }
        }
      },
      required: %w[classifications],
      additionalProperties: false
    }
  end

  # Returns { claim => Proposal }. A claim the model skipped simply has no
  # proposal, which reads downstream as an abstention rather than as a guess.
  def parse(response)
    payload = JSON.parse(response.text.to_s)
    rows = Array(payload["classifications"])

    # Tolerates the single-object shape too, so a model that answers the older
    # prompt shape is not silently treated as having said nothing.
    rows = [ payload.merge("number" => 1) ] if rows.empty? && payload["category"].present?

    parsed = rows.each_with_object({}) do |row, out|
      claim = claims[row["number"].to_i - 1]
      next if claim.nil?

      out[claim] = proposal_from(row)
    end

    fill_gaps(parsed, "classifier did not answer for this claim")
  rescue JSON::ParserError, TypeError, NoMethodError
    fill_gaps({}, "classifier returned unparseable output")
  end

  # A claim the model skipped is an abstention, explicitly recorded as one. The
  # alternative -- a silent absence -- would be indistinguishable downstream
  # from a claim nobody sent.
  def fill_gaps(parsed, reason)
    claims.each_with_object(parsed) do |claim, out|
      out[claim] ||= Proposal.new(category_key: ABSTAIN, confidence: 0.0,
                                  rationale: reason, abstained: true)
    end
  end

  def proposal_from(row)
    category = row["category"]
    confidence = row["confidence"].to_f

    # Never trust the label without checking it against the seeded taxonomy --
    # the schema constrains the model, but the system verifies regardless.
    known = categories.any? { it.key == category }
    abstained = category == ABSTAIN || !known || confidence < confidence_floor

    Proposal.new(category_key: category, confidence: confidence,
                 rationale: row["rationale"].to_s, abstained: abstained)
  end
end
