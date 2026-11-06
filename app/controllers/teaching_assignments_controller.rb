class TeachingAssignmentsController < ApplicationController
  before_action :require_administrator
  before_action :set_assignment, only: %i[edit update destroy]
  before_action :load_options, only: %i[new create edit update]

  def index
    @assignments = TeachingAssignment.joins(:teacher, :classroom)
      .where(classrooms: { school_id: current_school.id })
      .includes(:teacher, :classroom, :subject)
      .order("classrooms.name", "teachers.last_name", "teachers.first_name")
  end

  def new
    @assignment = TeachingAssignment.new(teacher_id: params[:teacher_id])
  end

  def create
    attributes = bulk_assignment_params
    classroom = current_school.classrooms.find(attributes[:classroom_id])
    teacher = current_school.teachers.find(attributes[:teacher_id])
    subjects = current_school.subjects.where(id: attributes[:subject_ids].reject(&:blank?))
    if subjects.empty?
      invalid = TeachingAssignment.new
      invalid.errors.add(:base, "Select at least one subject.")
      raise ActiveRecord::RecordInvalid.new(invalid)
    end

    created = 0
    ActiveRecord::Base.transaction do
      subjects.each do |subject|
        assignment = TeachingAssignment.find_or_initialize_by(classroom:, subject:, teacher:)
        assignment.lead = attributes[:lead]
        created += 1 if assignment.new_record?
        assignment.save!
      end
    end
    redirect_to teaching_assignments_path, notice: "Teacher was assigned to #{subjects.count} subject#{'s' unless subjects.one?}. #{created} new assignment#{'s' unless created == 1} created."
  rescue ActiveRecord::RecordNotFound => error
    @assignment ||= TeachingAssignment.new
    @assignment.errors.add(:base, error.message)
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => error
    @assignment = error.record
    load_options
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    classroom = current_school.classrooms.find(assignment_params[:classroom_id])
    teacher = current_school.teachers.find(assignment_params[:teacher_id])
    subject = current_school.subjects.find(assignment_params[:subject_id])
    if @assignment.update(classroom:, subject:, teacher:, course_section: nil, lead: assignment_params[:lead])
      redirect_to teaching_assignments_path, notice: "Teacher assignment was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => error
    @assignment.errors.add(:base, error.message)
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @assignment.destroy!
    redirect_to teaching_assignments_path, notice: "Teacher assignment was removed."
  end

  private

  def set_assignment
    @assignment = TeachingAssignment.joins(:classroom)
      .where(classrooms: { school_id: current_school.id })
      .find(params[:id])
  end

  def assignment_params
    params.expect(teaching_assignment: %i[teacher_id classroom_id subject_id lead])
  end

  def bulk_assignment_params
    params.require(:teaching_assignment).permit(:teacher_id, :classroom_id, :lead, subject_ids: [])
  end

  def load_options
    @teachers = current_school.teachers.where(active: true).order(:last_name, :first_name)
    @classrooms = current_school.classrooms.includes(academic_year: :terms).order(:name)
    @subjects = current_school.subjects.order(:name)
  end
end
