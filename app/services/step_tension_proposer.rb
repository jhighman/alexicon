# Whether a step contains a conflict at all, before anything rules on one.
#
# The missing precondition. Alexandra Krížová's probe CONSTRUCTS a conflict —
# the scenario is built so that two named values are in tension, and the judge
# then rules on a dilemma that is known to exist. A step found in a text has no
# such construction, and `StepValueJudge` never established that one was there.
# It asked what every flagged step protects, including steps that protect
# nothing, and a question shaped that way produces an answer either way: it
# named a commitment on 68% of claim pairs with no relation at all.
#
# So this runs first and is allowed to say there is nothing here. It proposes at
# most two values in tension, or `none`. Only if it commits does the judge get
# asked which of the two came first — a binary with a real refusal available,
# rather than a menu wide enough to fit anything.
#
# The split is hers, kept: the probe observes and infers nothing, the judge
# rules and did not produce the evidence. Two actors, because one actor doing
# both is the arrangement the Sentinel Principle exists to forbid.
class StepTensionProposer
  ACTION = "propose-step-tension".freeze
  PROPOSER = "step-tension-proposer".freeze
  MAX_TOKENS = 512
  NONE = "none".freeze

  Tension = Data.define(:first, :second, :rationale, :none) do
    def none? = none
    def pair = none? ? [] : [ first, second ]
    def to_s = none? ? "no tension" : "#{first.name} against #{second.name}"
  end

  class MissingCredentials < StandardError; end
  class NoGovernedModel < StandardError; end

  def self.call(transition, **) = new(transition, **).call

  def initialize(transition, client: nil, vocabulary: FrameworkValue.vocabulary)
    @transition = transition
    @client = client
    @vocabulary = vocabulary.to_a
  end

  # Returns a Tension. `none?` is the expected answer for most steps: an
  # argument that holds, an aside, a change of subject. Most steps do not put
  # one commitment before another and saying so is the job.
  def call
    resolution = LlmResolver.resolve(agent: proposer, action_type: ACTION)
    raise NoGovernedModel, resolution.error unless resolution.resolved?

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = request(resolution.model)
    record_invocation(resolution, started: started, response: response)
    parse(response)
  end

  private

  attr_reader :transition, :vocabulary

  def proposer = @proposer ||= Referent.find_by!(key: PROPOSER)

  def request(model)
    adapter = @client || model.client
    raise MissingCredentials, "no adapter for #{model.llm_provider.key}" if adapter.nil?

    adapter.complete(system: system_prompt, user: user_prompt, schema: schema,
                     max_tokens: MAX_TOKENS)
  rescue LlmClients::MissingCredentials => e
    raise MissingCredentials, e.message
  end

  def record_invocation(resolution, started:, response:)
    LlmInvocation.create!(
      llm_model: resolution.model, llm_assignment: resolution.assignment,
      agent: proposer, action_type: ACTION,
      input_tokens: response&.input_tokens.to_i, output_tokens: response&.output_tokens.to_i,
      latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
      status: "success"
    )
  end

  def parse(response)
    payload = JSON.parse(response.text.to_s)
    first = vocabulary.find { it.key == payload["first"].to_s.strip }
    second = vocabulary.find { it.key == payload["second"].to_s.strip }
    rationale = payload["rationale"].to_s.strip

    return Tension.new(first: nil, second: nil, rationale: rationale, none: true) if
      first.nil? || second.nil? || first == second

    Tension.new(first: first, second: second, rationale: rationale, none: false)
  rescue JSON::ParserError, TypeError, NoMethodError
    Tension.new(first: nil, second: nil, rationale: "unparseable", none: true)
  end

  def schema
    keys = vocabulary.map(&:key) + [ NONE ]
    {
      type: "object",
      properties: {
        first: { type: "string", enum: keys },
        second: { type: "string", enum: keys },
        rationale: { type: "string" }
      },
      required: %w[first second rationale],
      additionalProperties: false
    }
  end

  def system_prompt
    <<~PROMPT
      You are shown two consecutive statements from a text. The move from the
      first to the second was judged to claim more than the first supports.

      Your only question is whether that move involves a CONFLICT between two
      commitments — one held onto at the cost of another. Not what the move is
      about. Whether something was given up for something else.

      Choose the two commitments from this list, or answer "#{NONE}" for both:

      #{vocabulary.map { "- #{it.key}: #{it.name} — #{it.definition} Put before: #{it.subordinates}" }.join("\n")}

      Answer "#{NONE}" unless a conflict is actually visible in these two
      sentences. MOST STEPS HAVE NO CONFLICT IN THEM. An argument that simply
      goes too far, an aside, a change of subject, a turn of phrase — none of
      those trade one commitment against another, and naming a pair for them
      would be inventing a dilemma that is not there.

      You are not being asked which commitment won. Only whether two were in
      tension at all. Something else decides the winner, and it will not be
      asked unless you say a tension exists.

      Give a one-sentence rationale naming what in the two statements shows the
      conflict, or says why there is none.
    PROMPT
  end

  def user_prompt
    <<~TEXT
      From (#{transition.source.category&.key}):
      #{transition.source.text}

      To (#{transition.target.category&.key}):
      #{transition.target.text}
    TEXT
  end
end
