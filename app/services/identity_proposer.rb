# Proposes what a document's unfamiliar names refer to.
#
# The extractor is a regex, so it cannot tell "Michael Polanyi" from
# "Fortunately" -- the difference is world knowledge. Until now that gap was
# filled by a person, one form at a time: a single essay handed over 75
# questions including "Wow", "Part Two" and "Ironically". The model doing the
# classifying knew every one of those answers and was never asked.
#
# So this is the same fence the classifier sits behind, applied where the hard
# work actually is:
#
#   * It PROPOSES. Every proposal is an assertion by the Identity Proposer --
#     inference, attributable, challengeable, never a resolution. A STOP lifts
#     when a person accepts, not when the model answers.
#   * It is NOT the Identity Sentinel. An actor that proposed the ground and
#     then accepted it would be the conflation Chapter 6 forbids.
#   * It may ABSTAIN. "I don't know what this is" is a first-class answer, and
#     better than a plausible passport for a name the model has never met.
#   * It reads the WHOLE document. A name is identified by its context, and
#     asking about a surface form in isolation throws that context away.
#   * Every call is RECORDED, like any other.
class IdentityProposer
  ACTION = "resolve".freeze
  # Generous, because a thinking model charges its thinking against this budget
  # and the visible answer is what is left.
  MAX_TOKENS = 16_384

  # Names are proposed in batches so one refusal cannot cost a whole document,
  # and so a long list does not run into the output limit. Forty was too many:
  # the answer was truncated mid-object every time.
  BATCH_SIZE = 15

  Proposal = Data.define(:name, :kind, :subject, :role, :same_as, :confidence, :rationale) do
    def subject? = kind == "subject"
    def not_a_subject? = kind == "not_a_subject"
    def abstained? = kind == "unknown"
  end

  class MissingCredentials < StandardError; end
  class NoGovernedModel < StandardError; end

  def self.call(document, **) = new(document, **).call

  def initialize(document, client: nil)
    @document = document
    @client = client
  end

  # Records one proposal per unresolved surface form. Returns those recorded.
  def call
    names = unresolved_names
    return [] if names.empty?

    names.each_slice(BATCH_SIZE).flat_map { propose_batch(it) }
  end

  private

  attr_reader :document

  def proposer = @proposer ||= Referent.find_by!(key: "identity-proposer")

  # One question per name, in document order, so the model sees them as they
  # appear rather than alphabetised into nonsense.
  def unresolved_names
    document.open_stops
            .select { it.subject.is_a?(Mention) }
            .map { it.subject.text }
            .uniq
  end

  def propose_batch(names)
    resolution = resolve_model
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    begin
      response = request(resolution.model, names)
    rescue StandardError => e
      record_invocation(resolution, started: started, status: status_for(e), error: e.message)
      raise
    end

    persist(parse(response, names), resolution, response, started)
  end

  def resolve_model
    resolution = LlmResolver.resolve(agent: proposer, action_type: ACTION)
    raise NoGovernedModel, resolution.error unless resolution.resolved?

    resolution
  end

  def request(model, names)
    adapter = @client || model.client
    raise MissingCredentials, "no adapter for #{model.llm_provider.key}" if adapter.nil?

    adapter.complete(system: system_prompt, user: user_prompt(names),
                     schema: schema, max_tokens: MAX_TOKENS)
  rescue LlmClients::MissingCredentials => e
    raise MissingCredentials, e.message
  end

  def persist(proposals, resolution, response, started)
    recorded = []

    ActiveRecord::Base.transaction do
      proposals.reject(&:abstained?).each do |proposal|
        mention = representative_mention(proposal.name)
        next if mention.nil?

        recorded << Assertion.create!(
          asserter: proposer, subject: mention, act: "assert",
          claim: { "proposal" => proposal.kind, "name" => proposal.name,
                   "subject" => proposal.subject, "role" => proposal.role,
                   "same_as" => proposal.same_as,
                   "confidence" => proposal.confidence, "rationale" => proposal.rationale }
        )
      end

      record_invocation(resolution, started: started, status: "success", response: response)
    end

    recorded
  end

  # The proposal is about a name; it is attached to one of its occurrences
  # because an assertion is always about a record.
  def representative_mention(name)
    document.mentions.find { it.text == name }
  end

  def record_invocation(resolution, started:, status:, response: nil, error: nil)
    LlmInvocation.create!(
      llm_model: resolution.model, llm_assignment: resolution.assignment,
      agent: proposer, action_type: ACTION,
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

  def system_prompt
    <<~PROMPT
      You are given a document and a list of capitalised strings extracted from
      it by a regular expression. The extractor cannot tell a name from a word
      that merely starts a sentence, so most of the list is not names at all.

      For each string, answer one of three ways.

      "subject" -- it refers to a specific entity: a person, organisation,
      place, work, deity, or named concept. Give a SUBJECT (the kind of thing
      it is: Person, Place, Organisation, Work, Deity, Concept) and a ROLE
      (what it is in relation to the document or the world: Philosopher,
      Author, Band, Film, City). Both are required; a partial passport is not a
      weaker anchor, it is no anchor.

      "not_a_subject" -- it is an ordinary word whose capital is explained by
      sentence position, emphasis, a heading, or document structure.
      "Fortunately", "Wow", "Part Two" and "Postscript" are all this.

      If a string is a variant of another name in the SAME list -- a
      misspelling, a surname alone, a possessive, a shortening -- still answer
      "subject", and additionally give SAME_AS: the fullest form of that name
      as it appears in the list. "Polayani" is a misspelling of "Polanyi";
      "Goggins" is the surname of "David Goggins". Leave SAME_AS empty when the
      name stands on its own. Getting this right keeps one person from becoming
      three.

      "unknown" -- you genuinely cannot tell from the document or from what you
      know. Answer this rather than guessing. A wrong passport is worse than no
      passport, because the whole point of this step is to refuse to invent a
      subject.

      Use the document as context: the same string may be a name in one text
      and a common word in another. Give a confidence between 0 and 1 and a
      one-sentence rationale naming what decided it.

      Every string in the list must appear exactly once in your answer.
    PROMPT
  end

  def user_prompt(names)
    <<~PROMPT
      DOCUMENT
      #{document.body.to_s.truncate(24_000)}

      STRINGS TO JUDGE
      #{names.map { "- #{it}" }.join("\n")}
    PROMPT
  end

  def schema
    {
      type: "object",
      properties: {
        proposals: {
          type: "array",
          items: {
            type: "object",
            properties: {
              name: { type: "string" },
              kind: { type: "string", enum: %w[subject not_a_subject unknown] },
              subject: { type: "string" },
              role: { type: "string" },
              same_as: { type: "string" },
              confidence: { type: "number" },
              rationale: { type: "string" }
            },
            required: %w[name kind subject role same_as confidence rationale],
            additionalProperties: false
          }
        }
      },
      required: %w[proposals],
      additionalProperties: false
    }
  end

  # Never trust the returned names: only strings actually asked about are kept,
  # and a "subject" without a complete passport is downgraded to abstention
  # rather than recorded as a half-anchor.
  def parse(response, asked)
    payload = JSON.parse(response.text.to_s)

    Array(payload["proposals"]).filter_map do |row|
      name = row["name"].to_s
      next unless asked.include?(name)

      kind = row["kind"].to_s
      subject = row["subject"].to_s.presence
      role = row["role"].to_s.presence
      kind = "unknown" if kind == "subject" && (subject.nil? || role.nil?)

      # Only a name actually asked about, and never itself: a self-alias would
      # be a referent that is another name for itself.
      same_as = row["same_as"].to_s.presence
      same_as = nil unless asked.include?(same_as) && same_as != name

      Proposal.new(name: name, kind: kind, subject: subject, role: role, same_as: same_as,
                   confidence: row["confidence"].to_f, rationale: row["rationale"].to_s)
    end
  rescue JSON::ParserError, TypeError, NoMethodError
    []
  end
end
