class AttendanceRecord < ApplicationRecord
  include AuditableChanges
  belongs_to :enrollment
  belongs_to :recorded_by, class_name: "User", optional: true

  enum :status, { present: 0, absent: 1, late: 2, excused: 3 }

  validates :attendance_date, presence: true, uniqueness: { scope: :enrollment_id }
  validate :departure_after_arrival

  private

  def audit_school = enrollment.student.school

  def departure_after_arrival
    errors.add(:departed_at, "must be after arrival") if arrived_at && departed_at && departed_at <= arrived_at
  end
end
