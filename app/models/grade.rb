class Grade < ApplicationRecord
  include AuditableChanges
  belongs_to :assessment
  belongs_to :enrollment
  belongs_to :graded_by, class_name: "User", optional: true

  validates :enrollment_id, uniqueness: { scope: :assessment_id }
  validates :points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :points_do_not_exceed_maximum
  validate :enrollment_matches_assessment_classroom

  private

  def audit_school = enrollment.student.school

  def points_do_not_exceed_maximum
    errors.add(:points, "cannot exceed maximum points") if points && assessment && points > assessment.maximum_points
  end

  def enrollment_matches_assessment_classroom
    return unless enrollment && assessment
    return if enrollment.classroom_id == assessment.course_section.classroom_id

    errors.add(:enrollment, "must be in the assessment's class")
  end
end
