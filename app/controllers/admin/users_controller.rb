module Admin
  class UsersController < ApplicationController
    before_action :require_administrator
    before_action :set_user, only: %i[edit update]

    def index
      @users = current_school.users.order(:role, :last_name, :first_name)
      if params[:query].present?
        pattern = "%#{ActiveRecord::Base.sanitize_sql_like(params[:query].strip)}%"
        @users = @users.where("first_name LIKE :query OR last_name LIKE :query OR email LIKE :query", query: pattern)
      end
      @users = @users.limit(100)
    end

    def edit; end

    def update
      if password_params[:password].blank?
        @user.errors.add(:password, "cannot be blank")
        return render :edit, status: :unprocessable_entity
      end

      if @user.update(password_params)
        redirect_to admin_users_path, notice: "Password for #{@user.full_name} was changed successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_school.users.find(params[:id])
    end

    def password_params
      params.expect(user: %i[password password_confirmation])
    end
  end
end
