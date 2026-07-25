# The programmatic surface, for agents and for the CLI.
#
# One rule shapes everything here: a token acts as its REFERENT. Whatever calls
# this attributes its judgements to itself, so an agent driving the sentinels
# can never leave a record saying a person decided.
#
# Two gates, and both must pass:
#
#   * the POLICY — the same Pundit policies the browser uses, asking capability
#     questions. There is no second authorisation path.
#   * the DELEGATION — for judgements only. A person's token passes it by being
#     the person the gate was asking for; an agent's needs a standing decision
#     that this class of judgement may be made with nobody present.
class Api::V1::BaseController < ActionController::API
  include Pundit::Authorization

  before_action :authenticate_token!
  after_action :verify_authorized

  rescue_from Pundit::NotAuthorizedError, with: :forbidden
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  class NotDelegated < StandardError; end
  rescue_from NotDelegated, with: :not_delegated

  private

  attr_reader :current_token

  # Pundit asks capability questions, and a token answers them the same way a
  # user does — one implementation, in Capabilities.
  def pundit_user = current_token

  # The graph identity this call acts as. Judgements attribute here.
  def current_reviewer = current_token&.referent

  def authenticate_token!
    @current_token = ApiToken.authenticate(bearer_token)
    return if @current_token

    render json: { error: "unauthenticated",
                   detail: "Supply a token: Authorization: Bearer <token>." },
           status: :unauthorized
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    header[/\ABearer\s+(.+)\z/i, 1]
  end

  # Asked before any judgement. Reading needs no delegation; deciding does.
  def require_delegation!(act)
    raise NotDelegated, act unless current_token.may_judge?(act)
  end

  def forbidden(_error = nil)
    render json: { error: "forbidden", detail: "This token's role does not allow that." },
           status: :forbidden
  end

  def not_delegated(error)
    render json: {
      error: "not_delegated",
      detail: "#{current_reviewer&.name} may not #{error.message.humanize.downcase} without a person. " \
              "A delegation for this act has not been granted.",
      act: error.message,
      acting_as: current_reviewer&.key || current_reviewer&.name
    }, status: :forbidden
  end

  def not_found(_error = nil)
    render json: { error: "not_found" }, status: :not_found
  end

  def bad_request(error)
    render json: { error: "bad_request", detail: error.message }, status: :bad_request
  end

  def unprocessable(detail)
    render json: { error: "unprocessable", detail: detail }, status: :unprocessable_content
  end
end
