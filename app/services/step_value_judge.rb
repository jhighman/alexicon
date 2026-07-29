# What a step protects, at the places judgement already found something.
#
# The third level. Jeff Highman's chapter names three: trust — can I lean on
# this claim; judgement — did it survive contact with consequence; and beneath
# both, values, the commitments that decide which arguments feel reasonable
# before evidence arrives. Classification is the first. `GovernanceSentinel` is
# the second. This is the third, and it sits *beneath* judgement literally
# rather than metaphorically: it runs only where a verdict has already been
# reached, and only where that verdict was **unearned**.
#
# That is the whole of its scope, and the restraint is deliberate. An unearned
# step is a place where somebody moved without warrant. This asks the one
# question underneath it — what made that move feel warranted? — and asks it
# nowhere else. Where an argument holds, there is nothing here to explain.
#
# The method is Alexandra Krížová's Observed Value Priority, turned from a model
# onto a text ([ADR 14](docs/decisions/0014-observed-value-priority.md)). Her
# rule holds unchanged: behaviour is evidence, priority is a claim ABOUT the
# evidence, and the second never gets recorded as the first.
#
# --- Three things it must not do ---------------------------------------------
#
#   * It is a claim about the MOVE, never about the person. That is enforced by
#     the shape of the record rather than by the prompt: the assertion's subject
#     is the `Transition`. It is not possible for this class to write a claim
#     whose subject is a Referent, so "this author values X" is not a sentence
#     it can express. Inferring what somebody values from the points where their
#     reasoning failed is a short walk from psychologising them, and a promise
#     in a system prompt is not a guard.
#
#   * It does not re-judge the step. The verdict is the Sentinel's and stays.
#     This is a different question about the same place, asked by a different
#     actor — the separation the Sentinel keeps from the classifier, kept again
#     here.
#
#   * It is the least measurable thing in this system, and should look it. There
#     is no baseline that can validate an inferred value; it is weaker than the
#     correctness gap, because a category at least has an answer somebody could
#     argue for. So it abstains readily, always carries its confidence, and is
#     superseded by the author's own account of the move if one is ever given.
class StepValueJudge
  ACTION = "judge-step-value".freeze
  JUDGE = "step-value-judge".freeze
  MAX_TOKENS = 1024

  # Higher than the classifier's. A weak reading of a category is still a
  # category; a weak reading of what somebody was protecting is an accusation
  # with a number next to it.
  DEFAULT_CONFIDENCE_FLOOR = 0.85

  ABSTAIN = "uncertain".freeze

  Reading = Data.define(:protects, :subordinates, :confidence, :rationale, :abstained) do
    def abstained? = abstained
    def priority = abstained? ? nil : "#{protects} over #{subordinates}"
  end

  class MissingCredentials < StandardError; end
  class NoGovernedModel < StandardError; end

  # Raised when asked to read a step nothing has ruled on, or one that was
  # earned. The value question belongs beneath a finding, not instead of one.
  class NotFlagged < StandardError; end

  # Raised if the actor that ruled the step is also the one asked to read it.
  class NotIndependent < StandardError; end

  def self.call(transition, **) = new(transition, **).call

  # Every unearned step in a document, skipping any already read.
  def self.for_document(document, **)
    document.transitions.select(&:unearned?).reject { already_read?(it) }
            .filter_map { call(it, **) }
  end

  def self.already_read?(transition)
    transition.assertions.standing.any? { it.claim["inference"] == "step value" }
  end

  def initialize(transition, client: nil, confidence_floor: DEFAULT_CONFIDENCE_FLOOR)
    @transition = transition
    @client = client
    @confidence_floor = confidence_floor
  end

  def call
    guard!
    resolution = resolve_model
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      response = request(resolution.model)
    rescue StandardError => e
      record_invocation(resolution, started: started, status: status_for(e), error: e.message)
      raise
    end

    persist(parse(response), resolution, started, response)
  end

  private

  attr_reader :transition, :confidence_floor

  def judge = @judge ||= Referent.find_by!(key: JUDGE)

  def guard!
    raise NotFlagged, "step #{transition.id} was not judged unearned" unless transition.unearned?

    ruled_by = transition.assertions.standing.filter_map(&:asserter).map(&:key)
    return unless ruled_by.include?(judge.key)

    raise NotIndependent, "#{judge.key} ruled on this step and may not also read it"
  end

  def resolve_model
    resolution = LlmResolver.resolve(agent: judge, action_type: ACTION)
    raise NoGovernedModel, resolution.error unless resolution.resolved?

    resolution
  end

  def request(model)
    adapter = @client || model.client
    raise MissingCredentials, "no adapter for #{model.llm_provider.key}" if adapter.nil?

    adapter.complete(system: system_prompt, user: user_prompt, schema: schema,
                     max_tokens: MAX_TOKENS)
  rescue LlmClients::MissingCredentials => e
    raise MissingCredentials, e.message
  end

  # The subject is the TRANSITION. That is the guard, not a convention: this
  # class cannot write a claim about a person because it cannot name one as a
  # subject.
  def persist(reading, resolution, started, response)
    assertion = nil

    ActiveRecord::Base.transaction do
      invocation = record_invocation(resolution, started: started, status: "success",
                                                 response: response)
      unless reading.abstained?
        assertion = Assertion.create!(
          asserter: judge, subject: transition, act: "assert", llm_invocation: invocation,
          claim: { "inference" => "step value",
                   "move" => "#{transition.source.category&.key} -> #{transition.target.category&.key}",
                   "protects" => reading.protects, "subordinates" => reading.subordinates,
                   "confidence" => reading.confidence, "rationale" => reading.rationale }
        )
      end
    end

    assertion
  end

  def record_invocation(resolution, started:, status:, response: nil, error: nil)
    LlmInvocation.create!(
      llm_model: resolution.model, llm_assignment: resolution.assignment,
      agent: judge, action_type: ACTION,
      input_tokens: response&.input_tokens.to_i, output_tokens: response&.output_tokens.to_i,
      latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round,
      status: status, error_message: error
    )
  end

  def status_for(error)
    case error
    when LlmClients::RateLimited then "rate_limited"
    when LlmClients::ConnectionFailed then "timeout"
    else error.class.name.include?("Timeout") ? "timeout" : "error"
    end
  end

  # Unparseable output abstains rather than raising. A judge that returned
  # nonsense has told you nothing, which is the same position as a judge that
  # could not tell — and this is not a reading anything should stall on.
  def parse(response)
    payload = JSON.parse(response.text.to_s)
    protects = payload["protects"].to_s.strip
    confidence = payload["confidence"].to_f
    abstained = protects.blank? || protects == ABSTAIN || confidence < confidence_floor

    Reading.new(protects: protects, subordinates: payload["subordinates"].to_s.strip,
                confidence: confidence, rationale: payload["rationale"].to_s.strip,
                abstained: abstained)
  rescue JSON::ParserError, TypeError, NoMethodError
    Reading.new(protects: nil, subordinates: nil, confidence: 0.0,
                rationale: "judge returned unparseable output", abstained: true)
  end

  def schema
    {
      type: "object",
      properties: {
        protects: { type: "string" },
        subordinates: { type: "string" },
        confidence: { type: "number" },
        rationale: { type: "string" }
      },
      required: %w[protects subordinates confidence rationale],
      additionalProperties: false
    }
  end

  def system_prompt
    <<~PROMPT
      You are shown two consecutive statements from a text, and told that the
      move from the first to the second was judged UNEARNED — the second claims
      more than the first supports.

      Say what that MOVE puts first, and what it sets aside.

      Write about the move, not about the writer. "Treats a hard-won personal
      insight as generalisable" is a claim about a step. "The writer is
      arrogant" is not, and is not what is being asked. Never name, describe or
      characterise the person. You are reading one step in an argument, and you
      know nothing else about whoever made it.

      Do not say whether the move was right or wrong. The verdict has already
      been given by somebody else and is not yours to revisit. You are asked the
      different question underneath it: what would have to matter to somebody
      for this step to feel warranted?

      Answer "#{ABSTAIN}" for `protects` if the move does not clearly put one
      thing before another — because it is a turn of phrase, an aside, a change
      of subject, or too slight to read. Abstaining is correct and is preferred
      over a guess. Most steps do not reveal a commitment, and a value nobody
      could see is not a value.

      Give a confidence between 0 and 1 and a one-sentence rationale naming the
      feature of the two statements that decided it.
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
