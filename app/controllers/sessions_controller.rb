class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    redirect_to root_path if authenticated?
  end

  def create
    school = School.find_by("LOWER(code) = ?", credentials[:school_code].to_s.strip.downcase)
    user = school&.users&.find_by(email: credentials[:email].to_s.strip.downcase, active: true)

    if user&.authenticate(credentials[:password])
      record_login(user, true)
      return_to = start_new_session_for(user)
      redirect_to return_to || root_path, notice: "Welcome back, #{user.first_name}."
    else
      record_login(user, false)
      flash.now[:alert] = "The school code, email, or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "You have signed out."
  end

  private

  def credentials
    params.expect(session: %i[school_code email password])
  end

  def record_login(user, successful)
    LoginActivity.create!(user:, email: credentials[:email].to_s, successful:, ip_address: request.remote_ip, user_agent: request.user_agent)
  end
end
