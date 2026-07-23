class CourseSection < ApplicationRecord
  belongs_to :classroom
  belongs_to :subject
  belongs_to :term
  has_many :teaching_assignments, dependent: :destroy
  has_many :teachers, through: :teaching_assignments
  has_many :assessments, dependent: :destroy
  has_many :lesson_notes, dependent: :destroy
  has_many :timetable_entries, dependent: :destroy
  has_many :classroom_posts, dependent: :destroy

  validates :subject_id, uniqueness: { scope: %i[classroom_id term_id] }
end
