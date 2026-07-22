class ReportCardComment < ApplicationRecord
  belongs_to :student
  belongs_to :term
  belongs_to :author, class_name: "User"
  enum :kind, { subject_teacher: 0, homeroom_teacher: 1, administrator: 2 }
  validates :body, presence: true
  validates :kind, uniqueness: { scope: %i[student_id term_id] }
end
