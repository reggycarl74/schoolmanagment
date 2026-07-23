class AttendanceRegistersController < ApplicationController
  require "csv"
  before_action :require_staff
  before_action :load_classrooms

  def show
    @date = params[:date].presence&.to_date || Date.current
    return if params[:classroom_id].blank?

    @classroom = accessible_classrooms.find(params[:classroom_id])
    @enrollments = @classroom.enrollments.includes(:student).where(status: :enrolled).sort_by { |entry| entry.student.full_name }
    @records = AttendanceRecord.where(enrollment: @enrollments, attendance_date: @date).index_by(&:enrollment_id)
    respond_to do |format|
      format.html
      format.csv { send_data attendance_csv, filename: "attendance-#{@classroom.name.parameterize}-#{@date}.csv" }
    end
  end

  def create
    @classroom = accessible_classrooms.find(params[:classroom_id])
    date = params[:date].to_date

    ActiveRecord::Base.transaction do
      params.fetch(:attendance, {}).permit!.each do |enrollment_id, values|
        enrollment = @classroom.enrollments.find(enrollment_id)
        record = AttendanceRecord.find_or_initialize_by(enrollment:, attendance_date: date)
        record.update!(status: values[:status], notes: values[:notes], arrived_at: values[:arrived_at], departed_at: values[:departed_at], absence_reason: values[:absence_reason], recorded_by: current_user)
        notify_absence(record) if record.absent? && !record.guardian_notified?
      end
    end
    redirect_to attendance_register_path(classroom_id: @classroom.id, date:), notice: "Attendance was saved."
  end

  private

  def load_classrooms
    @classrooms = accessible_classrooms.order(:name)
  end

  def notify_absence(record)
    record.enrollment.student.guardians.merge(StudentGuardian.for_attendance).where(active: true).each do |guardian|
      body = "#{record.enrollment.student.full_name} was marked absent on #{record.attendance_date}.#{" Reason: #{record.absence_reason}." if record.absence_reason.present?}"
      channels = []
      channels << :email if guardian.email.present?
      channels << :sms if guardian.phone.present?
      channels.each do |channel|
        delivery = NotificationDelivery.create!(school: current_school, recipient: guardian, source: record, channel:, subject: "Student absence", body:)
        NotificationDeliveryJob.perform_later(delivery)
      end
    end
    record.update_column(:guardian_notified, true)
  end

  def attendance_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[student admission_number date status arrival departure absence_reason notes]
      @enrollments.each do |enrollment|
        record = @records[enrollment.id]
        csv << [ enrollment.student.full_name, enrollment.student.admission_number, @date, record&.status || "not_recorded", record&.arrived_at, record&.departed_at, record&.absence_reason, record&.notes ]
      end
    end
  end
end
