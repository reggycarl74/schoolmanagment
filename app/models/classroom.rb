class Classroom < ApplicationRecord
  belongs_to :school
  belongs_to :academic_year
  belongs_to :grade_level
  belongs_to :homeroom_teacher, class_name: "Teacher", optional: true, inverse_of: :homeroom_classrooms
  belongs_to :result_entry_term, class_name: "Term", optional: true
  has_many :enrollments, dependent: :restrict_with_error
  has_many :students, through: :enrollments
  has_many :course_sections, dependent: :destroy
  has_many :teaching_assignments, through: :course_sections
  has_many :teachers, through: :teaching_assignments
  has_many :class_subject_orders, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :academic_year_id }
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
