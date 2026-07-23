class LessonNote < ApplicationRecord
  attr_accessor :teaching_assignment_id, :prefill_from_files
  belongs_to :course_section
  belongs_to :teacher
  has_many_attached :files

  enum :status, { draft: 0, ready: 1, taught: 2 }

  validates :lesson_date, :topic, :content, presence: true
  validates :duration_minutes, numericality: { greater_than: 0, less_than_or_equal_to: 480 }, allow_blank: true
  validate :teacher_and_course_belong_to_same_school
  validate :teacher_is_assigned_to_course
  validate :lesson_date_is_inside_term
  validate :acceptable_files

  private

  def teacher_and_course_belong_to_same_school
    return unless teacher && course_section
    return if teacher.school_id == course_section.classroom.school_id

    errors.add(:teacher, "must belong to the same school as the class")
  end

  def teacher_is_assigned_to_course
    return unless teacher && course_section
    return if TeachingAssignment.exists?(teacher:, classroom: course_section.classroom, subject: course_section.subject)

    errors.add(:teacher, "must be assigned to this class and subject")
  end

  def acceptable_files
    files.each do |file|
      errors.add(:files, "must be text, PDF, Word, PowerPoint, or an image") unless file.content_type.in?(%w[text/plain application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation image/png image/jpeg image/webp])
      errors.add(:files, "must each be smaller than 15 MB") if file.byte_size > 15.megabytes
    end
  end

  def lesson_date_is_inside_term
    return unless lesson_date && course_section&.term
    return if lesson_date.between?(course_section.term.starts_on, course_section.term.ends_on)

    errors.add(:lesson_date, "must fall within the selected term")
  end
end
