class ReportCardsController < ApplicationController
  def show
    @student = accessible_students.find(params[:id])
    @terms = @student.enrollments.includes(classroom: { academic_year: :terms }).flat_map { |entry| entry.classroom.academic_year.terms }.uniq
    @term = @terms.find { |term| term.id == params[:term_id].to_i } || @terms.max_by(&:starts_on)
    @grades = grades_for_term
    @subject_results = build_subject_results
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
    @grades.group_by { |grade| grade.assessment.course_section.subject }.map do |subject, grades|
      earned = grades.sum { |grade| grade.points.to_d }
      possible = grades.sum { |grade| grade.assessment.maximum_points.to_d }
      percentage = possible.positive? ? earned / possible * 100 : 0
      scale = current_school.grading_scales.where("minimum_percentage <= ?", percentage).order(minimum_percentage: :desc).first
      { subject:, earned:, possible:, percentage:, scale: }
    end
  end
end
