class PromotionsController < ApplicationController
  before_action :require_teacher_or_administrator
  before_action :require_administrator, only: %i[approve reverse]
  before_action :load_classrooms

  def new
    load_students
    batches = current_school.promotion_batches.includes(:initiated_by, :approved_by, :from_classroom, :to_classroom, promotion_items: :student).order(created_at: :desc)
    @promotion_batches = current_user.teacher? ? batches.where(initiated_by: current_user) : batches.limit(50)
  end

  def create
    from = promotion_source_scope.find(params[:from_classroom_id])
    target = current_school.classrooms.find(params[:to_classroom_id])
    student_ids = Array(params[:student_ids]).reject(&:blank?).uniq
    enrollments = from.enrollments.includes(:student).where(student_id: student_ids, status: :enrolled)
    return redirect_to(new_promotion_path(from_classroom_id: from.id), alert: "Select at least one enrolled student.") if enrollments.empty?
    return redirect_to(new_promotion_path(from_classroom_id: from.id), alert: "The destination academic year cannot be earlier than the current class.") if target.academic_year.starts_on < from.academic_year.starts_on

    if params[:confirmed] != "1"
      @from_classroom = from
      @target_classroom = target
      @selected_enrollments = enrollments
      @reason = params[:reason]
      return render :preview
    end

    batch = current_school.promotion_batches.create!(from_classroom: from, to_classroom: target, initiated_by: current_user, reason: params[:reason])
    enrollments.each { |enrollment| batch.promotion_items.create!(student: enrollment.student, source_enrollment: enrollment) }
    batch.approve!(current_user) if current_user.administrator?
    AuditEvent.create!(school: current_school, user: current_user, auditable: batch, action: batch.approved? ? "promotion_approved" : "promotion_requested")
    redirect_to new_promotion_path, notice: current_user.administrator? ? "Students were promoted." : "Promotion request was sent to an administrator for approval."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to new_promotion_path, alert: error.record.errors.full_messages.to_sentence
  end

  def approve
    batch = current_school.promotion_batches.pending.find(params[:id])
    batch.approve!(current_user)
    AuditEvent.create!(school: current_school, user: current_user, auditable: batch, action: "promotion_approved")
    redirect_to new_promotion_path, notice: "Promotion request was approved."
  end

  def reverse
    batch = current_school.promotion_batches.approved.find(params[:id])
    batch.reverse!(current_user)
    AuditEvent.create!(school: current_school, user: current_user, auditable: batch, action: "promotion_reversed")
    redirect_to new_promotion_path, notice: "Promotion was reversed and the students were restored to their previous class."
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
