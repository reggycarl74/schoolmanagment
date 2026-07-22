class Enrollment < ApplicationRecord
  include AuditableChanges
  belongs_to :student
  belongs_to :classroom
  has_many :attendance_records, dependent: :destroy
  has_many :grades, dependent: :destroy

  enum :status, { enrolled: 0, completed: 1, transferred: 2, withdrawn: 3 }

  validates :enrolled_on, presence: true
  validates :classroom_id, uniqueness: { scope: :student_id }

  private

  def audit_school = student.school
end
