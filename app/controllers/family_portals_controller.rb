class FamilyPortalsController < ApplicationController
  def show
    unless current_user.parent? || current_user.student?
      return redirect_to root_path, alert: "The family portal is available to guardians and students."
    end

    @students = accessible_students.includes(:guardians, enrollments: :classroom)
    student_ids = @students.select(:id)
    @open_invoices = Invoice.where(student_id: student_ids).where.not(status: %i[paid cancelled]).includes(:student, :payments, :billing_adjustments).order(:due_on)
    @recent_attendance = AttendanceRecord.joins(enrollment: :student).where(students: { id: student_ids }).includes(enrollment: :student).order(attendance_date: :desc).limit(20)
    @submissions = StudentSubmission.where(student_id: student_ids).includes(:student, classroom_post: { course_section: %i[classroom subject] }).order(updated_at: :desc).limit(20)
    audiences = current_user.parent? ? %i[everyone parents] : %i[everyone students]
    @announcements = current_school.announcements.where(audience: audiences).order(published_at: :desc).limit(10)
  end
end
