class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    attributes = profile_params

    if attributes[:password].present? && !@user.authenticate(params[:current_password])
      @user.errors.add(:current_password, "is incorrect")
      return render :edit, status: :unprocessable_entity
    end

    attributes = attributes.except(:password, :password_confirmation) if attributes[:password].blank?
    if @user.update(attributes)
      redirect_to edit_profile_path, notice: "Your profile was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.expect(user: %i[first_name last_name email password password_confirmation])
  end
end
