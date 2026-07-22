class PasswordsController < ApplicationController
  skip_before_action :require_authentication
  before_action :set_user_by_token, only: %i[edit update]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    UserMailer.password_reset(user).deliver_later if user
    redirect_to new_session_path, notice: "If that account exists, password reset instructions have been sent."
  end

  def edit; end

  def update
    if @user.update(params.expect(user: %i[password password_confirmation]))
      redirect_to new_session_path, notice: "Your password was reset."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_token_for!(:password_reset, params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "That reset link is invalid or expired."
  end
end
