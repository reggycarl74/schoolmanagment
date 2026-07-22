class PromotionsController < ApplicationController
  before_action :require_administrator
  before_action :load_classrooms

  def new
    load_students
  end

  def create
    from = current_school.classrooms.find(params[:from_classroom_id])
    target = current_school.classrooms.find(params[:to_classroom_id])
    student_ids = params.fetch(:student_ids, [])

    ActiveRecord::Base.transaction do
      from.enrollments.where(student_id: student_ids, status: :enrolled).find_each do |enrollment|
        enrollment.update!(status: :completed, left_on: Date.current)
        Enrollment.find_or_create_by!(student: enrollment.student, classroom: target) do |new_enrollment|
          new_enrollment.enrolled_on = Date.current
        end
      end
    end
    redirect_to new_promotion_path(from_classroom_id: target.id), notice: "Selected students were promoted."
  end

  private

  def load_classrooms
    @classrooms = current_school.classrooms.includes(:academic_year).order("academic_years.starts_on", :name)
  end

  def load_students
    return if params[:from_classroom_id].blank?

    @from_classroom = current_school.classrooms.find(params[:from_classroom_id])
    @enrollments = @from_classroom.enrollments.includes(:student).where(status: :enrolled)
  end
end
