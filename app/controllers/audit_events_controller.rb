class AuditEventsController < ApplicationController
  before_action :require_administrator

  def index
    @events = current_school.audit_events.includes(:user, :auditable).order(created_at: :desc).limit(200)
  end
end
