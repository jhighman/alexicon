# Read-only by construction: there is no action a person takes on an
# invocation, so the policy closes every write verb rather than guarding it.
class LlmInvocationsController < ApplicationController
  def index
    authorize LlmInvocation
    @invocations = policy_scope(LlmInvocation).includes(:llm_model, :agent, :assertion).recent.limit(200)
  end
end
