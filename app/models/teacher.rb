class Teacher < ApplicationRecord
  belongs_to :school
  belongs_to :user, optional: true
  has_many :homeroom_classrooms, class_name: "Classroom", foreign_key: :homeroom_teacher_id, dependent: :nullify, inverse_of: :homeroom_teacher
  has_many :teaching_assignments, dependent: :destroy
  has_many :assigned_classrooms, through: :teaching_assignments, source: :classroom
  has_many :assigned_subjects, through: :teaching_assignments, source: :subject
  has_many :lesson_notes, dependent: :restrict_with_error
  has_many :timetable_entries, dependent: :restrict_with_error

  validates :employee_number, :first_name, :last_name, presence: true
  validates :employee_number, uniqueness: { scope: :school_id }

  def full_name = "#{first_name} #{last_name}"

  def accessible_classrooms
    school.classrooms.where(id: teaching_assignments.select(:classroom_id))
      .or(school.classrooms.where(homeroom_teacher_id: id))
      .distinct
  end
end
