class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_reviewer, :reviewer_identified?

  private

  # The person answering a flag. Not authentication -- identity here exists so
  # a disposition has an accountable author, which is the same rule the rest of
  # the architecture applies to every other judgement.
  def current_reviewer
    @current_reviewer ||= Referent.find_by(id: session[:reviewer_id])
  end

  def reviewer_identified? = current_reviewer.present?

  def require_reviewer!
    return if reviewer_identified?

    # Send them back to the page they were on, not the endpoint they hit -- a
    # PATCH path is not somewhere a browser can be redirected.
    session[:return_to] = request.get? ? request.fullpath : request.referer
    redirect_to new_reviewer_path,
                alert: "Tell us who you are first — a disposition has to be attributable."
  end
end
