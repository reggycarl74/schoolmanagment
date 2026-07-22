module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  private

  def authenticated?
    current_user.present?
  end

  def current_user
    Current.user ||= User.find_by(id: session[:user_id], active: true)
  end

  def require_authentication
    return if authenticated?

    session[:return_to] = request.fullpath if request.get? && request.format.html?
    redirect_to new_session_path, alert: "Please sign in to continue."
  end

  def start_new_session_for(user)
    return_to = session.delete(:return_to)
    reset_session
    session[:user_id] = user.id
    Current.user = user
    return_to
  end

  def terminate_session
    reset_session
    Current.reset
  end
end
