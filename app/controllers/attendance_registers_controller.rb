class AttendanceRegistersController < ApplicationController
  before_action :require_staff
  before_action :load_classrooms

  def show
    @date = params[:date].presence&.to_date || Date.current
    return if params[:classroom_id].blank?

    @classroom = accessible_classrooms.find(params[:classroom_id])
    @enrollments = @classroom.enrollments.includes(:student).where(status: :enrolled).sort_by { |entry| entry.student.full_name }
    @records = AttendanceRecord.where(enrollment: @enrollments, attendance_date: @date).index_by(&:enrollment_id)
  end

  def create
    @classroom = accessible_classrooms.find(params[:classroom_id])
    date = params[:date].to_date

    ActiveRecord::Base.transaction do
      params.fetch(:attendance, {}).permit!.each do |enrollment_id, values|
        enrollment = @classroom.enrollments.find(enrollment_id)
        record = AttendanceRecord.find_or_initialize_by(enrollment:, attendance_date: date)
        record.update!(status: values[:status], notes: values[:notes], recorded_by: current_user)
        notify_absence(record) if record.absent?
      end
    end
    redirect_to attendance_register_path(classroom_id: @classroom.id, date:), notice: "Attendance was saved."
  end

  private

  def load_classrooms
    @classrooms = accessible_classrooms.order(:name)
  end

  def notify_absence(record)
    record.enrollment.student.guardians.each do |guardian|
      delivery = NotificationDelivery.create!(school: current_school, recipient: guardian, channel: :email, subject: "Student absence", body: "#{record.enrollment.student.full_name} was marked absent on #{record.attendance_date}.")
      NotificationDeliveryJob.perform_later(delivery)
    end
  end
end
