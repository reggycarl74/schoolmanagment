module AuditableChanges
  extend ActiveSupport::Concern

  included do
    after_update_commit :record_audit_event
  end

  private

  def record_audit_event
    AuditEvent.create!(school: audit_school, user: Current.user, auditable: self, action: "updated", changes_data: saved_changes)
  end
end
