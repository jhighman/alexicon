class ApplicationController < ActionController::Base
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login!
  # Fail closed: an action that forgets to authorize raises rather than
  # quietly allowing the request. There is no `except:` list -- an exempt
  # action is one nobody remembers to revisit.
  after_action :verify_authorized, unless: :public_action?
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  helper_method :current_user, :current_reviewer, :signed_in?

  private

  def current_user
    @current_user ||= User.includes(:referent).find_by(id: session[:user_id])
  end

  # The graph identity the signed-in person acts as. Judgements attribute here,
  # never to the User -- authorisation and provenance stay separate concerns.
  def current_reviewer = current_user&.referent

  def signed_in? = current_user.present?

  def require_login!
    return if signed_in? || public_action?

    session[:return_to] = request.get? ? request.fullpath : request.referer
    redirect_to new_session_path, alert: "Sign in to continue."
  end

  # Signing in is the only thing you may do without being signed in.
  def public_action? = controller_name == "sessions"

  def not_authorized
    redirect_back fallback_location: root_path, alert: "Your role does not allow that."
  end
end
