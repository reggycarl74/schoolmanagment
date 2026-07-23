class PromotionsController < ApplicationController
  before_action :require_teacher_or_administrator
  before_action :load_classrooms

  def new
    load_students
  end

  def create
    from = promotion_source_scope.find(params[:from_classroom_id])
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
    redirect_to new_promotion_path, notice: "Selected students were promoted."
  end

  private

  def load_classrooms
    @destination_classrooms = current_school.classrooms.joins(:academic_year).includes(:academic_year).order("academic_years.starts_on", :name)
    @source_classrooms = if current_user.teacher?
      promotion_source_scope.joins(:academic_year).includes(:academic_year).order("academic_years.starts_on", :name)
    else
      @destination_classrooms
    end
  end

  def load_students
    return if params[:from_classroom_id].blank?

    @from_classroom = promotion_source_scope.find(params[:from_classroom_id])
    @enrollments = @from_classroom.enrollments.includes(:student).where(status: :enrolled)
  end

  def promotion_source_scope
    current_user.teacher? ? accessible_classrooms : current_school.classrooms
  end

  def require_teacher_or_administrator
    return if current_user.administrator? || current_user.teacher?

    redirect_to root_path, alert: "Only administrators and assigned teachers can promote students."
  end
end
