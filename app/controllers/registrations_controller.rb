class RegistrationsController < ApplicationController
  PUBLIC_ROLES = %w[teacher registrar accountant parent].freeze

  skip_before_action :require_authentication
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to new_registration_path, alert: "Try again later." }

  def new
    redirect_to root_path if authenticated?
    @user = User.new(role: :teacher)
  end

  def create
    school = School.find_by("LOWER(code) = ?", registration_params[:school_code].to_s.strip.downcase)
    administrator_signup = ActiveSupport::SecurityUtils.secure_compare(
      registration_params[:registration_code].to_s,
      ENV.fetch("ADMIN_SIGNUP_CODE", "checkers")
    )
    attributes = user_attributes.merge(
      role: administrator_signup ? "administrator" : user_attributes[:role],
      active: administrator_signup
    )
    @user = school&.users&.new(attributes) || User.new(attributes)

    unless school
      @user.errors.add(:base, "School code was not found")
      return render :new, status: :unprocessable_entity
    end

    if @user.save
      message = if administrator_signup
        "Administrator account created. You can now sign in."
      else
        "Registration submitted. An administrator must approve your account before you can sign in."
      end
      redirect_to new_session_path, notice: message
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: %i[school_code registration_code first_name last_name email role password password_confirmation])
  end

  def user_attributes
    attributes = registration_params.except(:school_code, :registration_code)
    attributes[:role] = "teacher" unless PUBLIC_ROLES.include?(attributes[:role])
    attributes
  end
end
