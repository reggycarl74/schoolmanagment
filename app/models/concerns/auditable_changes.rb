module AuditableChanges
  extend ActiveSupport::Concern

  included do
    after_update_commit :record_audit_event, unless: :audit_events_suppressed?
  end

  private

  def record_audit_event
    AuditEvent.create!(school: audit_school, user: Current.user, auditable: self, action: "updated", changes_data: saved_changes)
  end

  def audit_events_suppressed?
    ActiveModel::Type::Boolean.new.cast(ENV["DISABLE_AUDIT_EVENTS"])
  end
end
