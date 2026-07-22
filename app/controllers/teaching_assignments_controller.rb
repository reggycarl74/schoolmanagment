class TeachingAssignmentsController < ApplicationController
  before_action :require_administrator
  before_action :load_options, only: %i[new create]

  def index
    @assignments = TeachingAssignment.joins(:teacher, course_section: :classroom)
      .where(classrooms: { school_id: current_school.id })
      .includes(:teacher, course_section: %i[classroom subject term])
      .order("classrooms.name", "teachers.last_name", "teachers.first_name")
  end

  def new
    @assignment = TeachingAssignment.new
  end

  def create
    classroom = current_school.classrooms.find(assignment_params[:classroom_id])
    teacher = current_school.teachers.find(assignment_params[:teacher_id])
    subject = current_school.subjects.find(assignment_params[:subject_id])
    term = classroom.academic_year.terms.find(assignment_params[:term_id])
    course = CourseSection.find_or_create_by!(classroom:, subject:, term:)
    @assignment = TeachingAssignment.new(course_section: course, teacher:, lead: assignment_params[:lead])

    if @assignment.save
      redirect_to teaching_assignments_path, notice: "Teacher was assigned successfully."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => error
    @assignment ||= TeachingAssignment.new
    @assignment.errors.add(:base, error.message)
    render :new, status: :unprocessable_entity
  end

  def destroy
    assignment = TeachingAssignment.joins(course_section: :classroom)
      .where(classrooms: { school_id: current_school.id })
      .find(params[:id])
    assignment.destroy!
    redirect_to teaching_assignments_path, notice: "Teacher assignment was removed."
  end

  private

  def assignment_params
    params.expect(teaching_assignment: %i[teacher_id classroom_id subject_id term_id lead])
  end

  def load_options
    @teachers = current_school.teachers.where(active: true).order(:last_name, :first_name)
    @classrooms = current_school.classrooms.includes(academic_year: :terms).order(:name)
    @subjects = current_school.subjects.order(:name)
    @terms = current_school.academic_years.includes(:terms).flat_map(&:terms).sort_by(&:starts_on).reverse
  end
end
