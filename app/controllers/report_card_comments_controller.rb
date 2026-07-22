class ReportCardCommentsController < ApplicationController
  before_action :require_staff

  def create
    student = accessible_students.find(comment_params[:student_id])
    term = Term.joins(:academic_year).where(academic_years: { school_id: current_school.id }).find(comment_params[:term_id])
    kind = comment_params[:kind]
    kind = "homeroom_teacher" if !current_user.administrator? && kind == "administrator"
    comment = student.report_card_comments.find_or_initialize_by(term:, kind:)
    comment.assign_attributes(body: comment_params[:body], author: current_user, approved: current_user.administrator?)
    comment.save!
    redirect_to report_card_path(student, term_id: term.id), notice: "Report comment was saved."
  end

  def update
    comment = ReportCardComment.joins(:student).where(students: { school_id: current_school.id }).find(params[:id])
    comment.update!(approved: params[:approved])
    redirect_to report_card_path(comment.student, term_id: comment.term_id), notice: "Comment approval was updated."
  end

  private

  def comment_params = params.expect(report_card_comment: %i[student_id term_id kind body])
end
