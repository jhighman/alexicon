# Judgment at the scope of a closed episode.
#
# `StepTensionProposer` asks whether a step contains a conflict, shown two
# sentences. Three designs at that scope failed to tell a real step from an
# unrelated pair (BASELINE-v3 §§4–6, 9), and the recorded diagnosis was that
# the question has no ground truth in a found text. Alexandra Krížová's answer
# to the third call sharpens that diagnosis rather than accepting it: the
# ground truth is not IN the pair, because a person does not judge isolated
# sentences — they judge completed episodes, where the ending is allowed to
# reinterpret the beginning. A father inventing a game inside a camp lies at
# every step; judged sentence-by-sentence the lie is a violation, and judged at
# the closure of the episode it is Kindness put before Truth, visibly and
# deliberately. Her architecture reaches the whole case through attention
# geometry; this layer does not have attention, so it realises the same
# requirement at the evaluation layer instead — DEFERRED EVALUATION. The
# Observer's subject is a `Case`, and a case that has not closed does not
# exist, so judgment structurally cannot outrun closure.
#
# The question is deliberately identical to the pair-scoped one — a conflict at
# THIS step, or none — with only the visible scope changed. That is what makes
# the discrimination control comparable across scopes: if the observer tells
# real steps from unrelated pairs where the pair-scoped judge could not, the
# scope was the missing variable; if it cannot, the diagnosis survives its
# strongest challenge.
#
# The observer proposes and does not rule, keeping the split the Sentinel
# Principle asks for: the actor that surfaces a tension is not the actor that
# decides what it means.
class CaseObserver
  ACTION = "observe-case".freeze
  OBSERVER = "case-observer".freeze
  MAX_TOKENS = 768

  class MissingCredentials < StandardError; end
  class NoGovernedModel < StandardError; end
  class OutsideCase < StandardError; end

  def self.call(kase, step:, **) = new(kase, step: step, **).call

  def initialize(kase, step:, client: nil, vocabulary: FrameworkValue.vocabulary)
    @kase = kase
    @step = step
    @client = client
    @vocabulary = vocabulary.to_a

    raise OutsideCase, "step is not inside #{kase}" unless kase.include?(step)
  end

  # Returns a Tension — the same shape the pair-scoped proposer returns,
  # because it is the same question. `none?` is the expected answer for most
  # steps at this scope too: a closed episode reinterprets some of its steps
  # and leaves most of them exactly what they looked like.
  def call
    resolution = LlmResolver.resolve(agent: observer, action_type: ACTION)
    raise NoGovernedModel, resolution.error unless resolution.resolved?

    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = request(resolution.model)
    record_invocation(resolution, started: started, response: response)
    parse(response)
  end

  private

  attr_reader :kase, :step, :vocabulary

  def observer = @observer ||= Referent.find_by!(key: OBSERVER)

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
      agent: observer, action_type: ACTION,
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
    none = StepTensionProposer::Tension

    return none.new(first: nil, second: nil, rationale: rationale, none: true) if
      first.nil? || second.nil? || first == second

    none.new(first: first, second: second, rationale: rationale, none: false)
  rescue JSON::ParserError, TypeError, NoMethodError
    StepTensionProposer::Tension.new(first: nil, second: nil, rationale: "unparseable", none: true)
  end

  def schema
    keys = vocabulary.map(&:key) + [ StepTensionProposer::NONE ]
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
      You are shown a COMPLETE, CLOSED episode from a text, and one marked step
      inside it — the move from one statement to the next.

      Your only question is whether that marked move, READ AT THE SCOPE OF THE
      WHOLE EPISODE, involves a conflict between two commitments — one held
      onto at the cost of another. The ending of the episode is allowed to
      reinterpret the step: a move that looks like a violation in isolation may
      be the visible cost of a commitment the whole episode serves, and a move
      that looks fine alone may be part of a trade the episode makes.

      Choose the two commitments from this list, or answer
      "#{StepTensionProposer::NONE}" for both:

      #{vocabulary.map { "- #{it.key}: #{it.name} — #{it.definition} Put before: #{it.subordinates}" }.join("\n")}

      Answer "#{StepTensionProposer::NONE}" unless a conflict at the marked
      step is actually visible from the episode. MOST STEPS HAVE NO CONFLICT IN
      THEM, at any scope. An argument that goes further than its support, an
      aside, a change of subject — none of those trade one commitment against
      another, and the episode around them does not change that. Naming a pair
      for them would be inventing a dilemma the episode does not contain.

      You are not being asked which commitment won, and you are not judging the
      episode as a whole. Only whether two commitments are in tension AT THE
      MARKED STEP, in the light of everything around it.

      Give a one-sentence rationale naming what in the episode shows the
      conflict at that step, or why there is none.
    PROMPT
  end

  def user_prompt
    lines = kase.claims.map do |c|
      marker = if c.id == step.from_claim.id then ">> FROM"
      elsif c.id == step.to_claim.id then ">> TO  "
      else "       "
      end
      "#{marker} [#{c.position}] #{c.text}"
    end

    <<~TEXT
      The closed episode (claims #{kase.opening.position}–#{kase.closing.position}).
      The marked step is FROM [#{step.from_claim.position}] (#{step.from_claim.category&.key}) TO [#{step.to_claim.position}] (#{step.to_claim.category&.key}).

      #{lines.join("\n")}
    TEXT
  end
end
