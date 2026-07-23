class StudentGuardian < ApplicationRecord
  include AuditableChanges
  belongs_to :student
  belongs_to :guardian

  validates :relationship, presence: true
  validates :guardian_id, uniqueness: { scope: :student_id }
  validates :emergency_priority, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :contactable, -> { where(contact_allowed: true) }
  scope :for_academics, -> { where(academic_access: true, contact_allowed: true) }
  scope :for_attendance, -> { where(attendance_access: true, contact_allowed: true) }
  scope :for_billing, -> { where(billing_access: true, contact_allowed: true) }

  private

  def audit_school = guardian.school
end
