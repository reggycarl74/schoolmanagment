class TeachingAssignment < ApplicationRecord
  belongs_to :classroom
  belongs_to :subject
  belongs_to :course_section, optional: true
  belongs_to :teacher

  before_validation :copy_course_details, if: :course_section
  validates :teacher_id, uniqueness: { scope: %i[classroom_id subject_id] }

  def course_section_for(date)
    term = classroom.academic_year.terms.find { |candidate| date.between?(candidate.starts_on, candidate.ends_on) }
    raise ActiveRecord::RecordNotFound, "No school term contains the selected teaching date." unless term

    CourseSection.find_or_create_by!(classroom:, subject:, term:)
  end

  private

  def copy_course_details
    self.classroom ||= course_section.classroom
    self.subject ||= course_section.subject
  end
end
