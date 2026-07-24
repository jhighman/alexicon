class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(username: params[:username].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      # Capture before reset_session: rotating the session on sign-in prevents
      # fixation, and would otherwise discard where they were headed.
      destination = session[:return_to]
      reset_session
      session[:user_id] = user.id
      redirect_to(destination || root_path,
                  notice: "Signed in as #{user.username} (#{user.role}).")
    else
      flash.now[:alert] = "That username and password do not match."
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
