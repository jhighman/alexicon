# Decides which model answers a given caller and act.
#
# Resolution is by specificity first and priority second, so a narrow rule is
# never captured by a broad one that happens to carry a bigger number.
#
# There is deliberately no fallback to "the cheapest certified model". A
# fallback of that shape means a call silently runs on a model nobody chose for
# it, and the invocation record would then be the only place that fact appears.
# If no rule matches, this says so and the caller stops -- the same posture the
# Identity Sentinel takes toward an unresolved name.
class LlmResolver
  Result = Data.define(:model, :assignment, :error) do
    def resolved? = model.present? && error.nil?
  end

  NO_CERTIFIED_MODEL = "no model is certified — a model must be certified by a named " \
                       "person before it can be used".freeze

  PROVIDERS_INACTIVE = "every certified model belongs to an inactive provider".freeze

  def self.resolve(agent:, action_type:) = new(agent: agent, action_type: action_type).resolve

  def initialize(agent:, action_type:)
    @agent = agent
    @action_type = action_type
  end

  def resolve
    return failure("caller has no key to match an assignment against") if agent_key.blank?
    return failure(nothing_assignable) if LlmModel.assignable.none?

    best = candidates.max_by { [ it.specificity, it.priority ] }
    return failure(no_usable_rule) if best.nil?

    Result.new(model: best.llm_model, assignment: best, error: nil)
  end

  private

  attr_reader :agent, :action_type

  def agent_key = agent&.key

  def candidates
    LlmAssignment.active.with_assignable_model.includes(llm_model: :llm_provider)
                 .select { it.matches?(agent_key: agent_key, action_type: action_type) }
  end

  # Rules that name this caller and act, whether or not their model can be used.
  def matching_rules
    LlmAssignment.includes(llm_model: :llm_provider)
                 .select { it.matches?(agent_key: agent_key, action_type: action_type) }
  end

  # "No assignment matches" and "the assignment that matches points somewhere
  # unusable" send an admin to opposite places -- one to write a rule, the other
  # to fix the model a rule already names. Reporting both as the first was
  # sending people to look for a rule that was sitting right in front of them.
  def no_usable_rule
    stale = matching_rules
    return "no assignment matches #{agent_key.inspect} / #{action_type.inspect}" if stale.empty?

    "#{agent_key} is routed to #{stale.map { unusable(it) }.uniq.to_sentence}"
  end

  def unusable(assignment)
    model = assignment.llm_model
    reason =
      if !assignment.active then "the rule is switched off"
      elsif model.revoked? then "it is revoked"
      elsif !model.certified? then "it is not certified"
      elsif !model.llm_provider.active? then "#{model.llm_provider.name} is inactive"
      else "it is unavailable"
      end

    "#{model.display_name}, which cannot be used because #{reason}"
  end

  # "Nothing is assignable" has two quite different causes, and telling them
  # apart is the difference between "go certify something" and "you switched a
  # provider off and forgot".
  def nothing_assignable
    LlmModel.certified.any? ? PROVIDERS_INACTIVE : NO_CERTIFIED_MODEL
  end

  def failure(message) = Result.new(model: nil, assignment: nil, error: message)
end
