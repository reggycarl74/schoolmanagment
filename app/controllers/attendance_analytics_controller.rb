class AttendanceAnalyticsController < ApplicationController
  before_action :require_staff

  def show
    @from = params[:from].presence&.to_date || Date.current.beginning_of_month
    @to = params[:to].presence&.to_date || Date.current
    @classroom = accessible_classrooms.find_by(id: params[:classroom_id])
    enrollment_scope = @classroom ? @classroom.enrollments : Enrollment.where(classroom_id: accessible_classrooms.select(:id))
    @records = AttendanceRecord.where(enrollment: enrollment_scope, attendance_date: @from..@to)
    @summary = @records.group(:status).count
    @frequent_absences = @records.absent.group(:enrollment_id).having("COUNT(*) >= 3").count
    @enrollments = Enrollment.includes(:student).where(id: @frequent_absences.keys).index_by(&:id)
    @classrooms = accessible_classrooms.order(:name)
  end
end
