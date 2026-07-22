class ApplicationController < ActionController::Base
  include Authentication
  include SchoolAccess

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_school

  private

  def current_school
    @current_school ||= current_user.school
  end
end
