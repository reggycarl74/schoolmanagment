class ReportCardsController < ApplicationController
  def show
    students = current_user.parent? ? accessible_students_with_guardian_permission(:academic_access) : accessible_students
    @student = students.find(params[:id])
    @terms = @student.enrollments.includes(classroom: { academic_year: :terms }).flat_map { |entry| entry.classroom.academic_year.terms }.uniq
    @term = @terms.find { |term| term.id == params[:term_id].to_i } || @terms.max_by(&:starts_on)
    @classroom = @student.enrollments.includes(:classroom).map(&:classroom)
      .find { |classroom| classroom.academic_year_id == @term&.academic_year_id }
    @report_template = @classroom&.report_template || "classic"
    @grades = grades_for_term
    @subject_results = build_subject_results
    @overall_average = @subject_results.any? ? @subject_results.sum { |result| result[:total_percentage] } / @subject_results.size : 0
    @comments = @term ? @student.report_card_comments.where(term: @term).includes(:author).order(:kind) : ReportCardComment.none
    @comments = @comments.where(approved: true) if current_user.parent? || current_user.student?
    @remark_templates = current_school.report_card_remark_templates.available
    @comment_kinds = ReportCardComment.kinds.keys
    @comment_kinds -= [ "administrator" ] unless current_user.administrator?
    @remark_templates = @remark_templates.where(kind: @comment_kinds)
    enrollment_ids = @student.enrollments.pluck(:id)
    @attendance = if @term
      AttendanceRecord.where(enrollment_id: enrollment_ids, attendance_date: @term.starts_on..@term.ends_on).group(:status).count
    else
      {}
    end
  end

  private

  def grades_for_term
    return Grade.none unless @term

    scope = Grade.joins(assessment: :course_section, enrollment: :student)
      .where(students: { id: @student.id }, course_sections: { term_id: @term.id })
      .includes(assessment: { course_section: :subject })
    current_user.parent? || current_user.student? ? scope.joins(:assessment).where(assessments: { status: :published }) : scope
  end

  def build_subject_results
    results = @grades.group_by { |grade| grade.assessment.course_section.subject }.map do |subject, grades|
      earned = grades.sum { |grade| grade.points.to_d }
      possible = grades.sum { |grade| grade.assessment.maximum_points.to_d }
      percentage = possible.positive? ? earned / possible * 100 : 0
      continuous_grades, exam_grades = grades.partition { |grade| !grade.assessment.exam? }
      continuous_score = normalized_score(continuous_grades, 30)
      exam_score = normalized_score(exam_grades, 70)
      total_percentage = continuous_score + exam_score
      scales = current_school.grading_scales_for(@classroom)
      scale = scales.where("minimum_percentage <= ?", percentage).order(minimum_percentage: :desc).first
      jhs_scale = scales.where("minimum_percentage <= ?", total_percentage).order(minimum_percentage: :desc).first
      { subject:, earned:, possible:, percentage:, scale:, continuous_score:, exam_score:, total_percentage:, jhs_scale: }
    end
    classroom = @student.enrollments.find { |enrollment| enrollment.classroom.academic_year_id == @term&.academic_year_id }&.classroom
    positions = classroom&.class_subject_orders&.pluck(:subject_id, :position)&.to_h || {}
    results.sort_by { |result| [ positions.fetch(result[:subject].id, 10_000), result[:subject].name ] }
  end

  def normalized_score(grades, target)
    possible = grades.sum { |grade| grade.assessment.maximum_points.to_d }
    return 0.to_d unless possible.positive?

    earned = grades.sum { |grade| grade.points.to_d }
    (earned / possible * target).round(1)
  end
end
