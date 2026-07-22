class AuditEvent < ApplicationRecord
  belongs_to :school
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true
  validates :action, presence: true
end
