class TeachingAssignment < ApplicationRecord
  belongs_to :course_section
  belongs_to :teacher

  validates :teacher_id, uniqueness: { scope: :course_section_id }
end
