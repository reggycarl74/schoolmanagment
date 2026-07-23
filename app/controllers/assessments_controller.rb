class AssessmentsController < ApplicationController
  before_action :require_staff

  def index
    @records = Assessment.joins(course_section: :classroom)
      .where(classrooms: { id: accessible_classrooms.select(:id) })
      .includes(course_section: %i[classroom subject term])
      .order(due_on: :desc)
  end

  def advance
    assessment = Assessment.joins(course_section: :classroom).where(classrooms: { id: accessible_classrooms.select(:id) }).find(params[:id])
    next_status = permitted_next_status(assessment)
    return redirect_to assessments_path, alert: "That assessment cannot be advanced." unless next_status

    assessment.update!(status: next_status, published_at: (Time.current if next_status == :published))
    notify_publication(assessment) if assessment.published?
    redirect_to assessments_path, notice: "Assessment is now #{next_status}."
  end

  private

  def permitted_next_status(assessment)
    return :submitted if current_user.teacher? && assessment.draft?
    return :approved if current_user.administrator? && assessment.submitted?
    :published if current_user.administrator? && assessment.approved?
  end

  def notify_publication(assessment)
    assessment.course_section.classroom.students.includes(:guardians).find_each do |student|
      student.guardians.merge(StudentGuardian.for_academics).where(active: true).each do |guardian|
        delivery = NotificationDelivery.create!(school: current_school, recipient: guardian, channel: :email, subject: "Results published", body: "New #{assessment.title} results are available for #{student.full_name}.")
        NotificationDeliveryJob.perform_later(delivery)
      end
    end
  end
end
