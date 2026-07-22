class AnnouncementsController < ApplicationController
  before_action :require_administrator, only: %i[new create]

  def index
    allowed = case current_user.role
    when "teacher", "registrar", "accountant" then %i[everyone staff]
    when "parent" then %i[everyone parents]
    when "student" then %i[everyone students]
    else Announcement.audiences.keys
    end
    @announcements = current_school.announcements.where(audience: allowed).includes(:author).order(published_at: :desc)
  end

  def new = @announcement = current_school.announcements.new(published_at: Time.current)

  def create
    @announcement = current_school.announcements.new(announcement_params.merge(author: current_user))
    return redirect_to(announcements_path, notice: "Announcement was published.") if @announcement.save

    render :new, status: :unprocessable_entity
  end

  private

  def announcement_params = params.expect(announcement: %i[title body audience published_at])
end
