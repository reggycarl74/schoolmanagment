class ExamResultsController < ApplicationController
  before_action :require_staff
  DEFAULT_COMPONENTS = {
    class_work: { title: "Class Work", maximum_points: 10, kind: :assignment },
    class_test: { title: "Class Test", maximum_points: 10, kind: :quiz },
    project: { title: "Project", maximum_points: 10, kind: :project },
    mid_term: { title: "Mid Term", maximum_points: 20, kind: :exam },
    exam: { title: "Exam", maximum_points: 50, kind: :exam }
  }.freeze

  before_action :load_options

  def index
    redirect_to new_exam_result_path
  end

  def new
    required = filter_params.values_at(:classroom_id, :subject_id)
    load_grid if required.all?(&:present?) && (current_user.teacher? || filter_params[:term_id].present?)
  rescue ActiveRecord::RecordNotFound
    @form_error = "Choose a class, subject, and term from the same academic year."
  end

  def create
    load_selected_records

    ActiveRecord::Base.transaction do
      assessments = build_assessments

      score_params.each do |enrollment_id, scores|
        enrollment = @classroom.enrollments.find(enrollment_id)

        @components.each_key do |component|
          points = scores[component]
          next if points.blank?

          grade = assessments.fetch(component).grades.find_or_initialize_by(enrollment:)
          grade.assign_attributes(points:, graded_at: Time.current)
          grade.save!
        end
      end
    end

    redirect_to new_exam_result_path(filter_params), notice: "Exam results were saved successfully."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
    @form_error = error.message
    load_grid
    render :new, status: :unprocessable_entity
  end

  private

  def filter_params
    params.permit(:classroom_id, :subject_id, :term_id)
  end

  def score_params
    params.fetch(:scores, {}).permit!.to_h
  end

  def load_selected_records
    @classroom = accessible_classrooms.find(filter_params[:classroom_id])
    @subject = current_school.subjects.find(filter_params[:subject_id])
    requested_term_id = current_user.teacher? ? @classroom.result_entry_term_id : filter_params[:term_id]
    raise ActiveRecord::RecordNotFound if requested_term_id.blank?

    @term = @classroom.academic_year.terms.find(requested_term_id)
    @course = CourseSection.find_or_create_by!(classroom: @classroom, subject: @subject, term: @term)
    if current_user.teacher? && !TeachingAssignment.exists?(teacher: current_user.teacher, classroom: @classroom, subject: @subject)
      raise ActiveRecord::RecordNotFound, "You are not assigned to this class, subject, and term."
    end
    @components = component_definitions(@classroom)
  end

  def load_grid
    load_selected_records
    @enrollments = @classroom.enrollments.includes(:student).where(status: :enrolled).sort_by { |record| record.student.full_name }
    assessments = @course.assessments.where(title: @components.values.pluck(:title)).index_by(&:title)
    @saved_scores = Grade.where(assessment: assessments.values, enrollment: @enrollments)
      .pluck(:enrollment_id, :assessment_id, :points)
      .to_h { |enrollment_id, assessment_id, points| [ [ enrollment_id, assessment_id ], points ] }
    @assessment_ids = assessments.transform_values(&:id)
  end

  def build_assessments
    @components.to_h do |key, definition|
      assessment = @course.assessments.find_or_initialize_by(title: definition[:title])
      assessment.assign_attributes(
        maximum_points: definition[:maximum_points],
        kind: definition[:kind],
        weight: 1,
        due_on: @term.ends_on
      )
      assessment.save!
      [ key, assessment ]
    end
  end

  def load_options
    @components = DEFAULT_COMPONENTS
    @classrooms = accessible_classrooms.includes(:academic_year).order(:name)
    @subjects = current_school.subjects.order(:name)
    @terms = current_school.academic_years.includes(:terms).flat_map(&:terms).sort_by(&:starts_on).reverse
  end

  def component_definitions(classroom)
    records = current_school.assessment_components.where(classroom: classroom, active: true).order(:position)
    records = current_school.assessment_components.where(classroom_id: nil, active: true).order(:position) if records.empty?
    return DEFAULT_COMPONENTS if records.empty?

    records.to_h do |record|
      [ record.title.parameterize(separator: "_").to_sym, { title: record.title, maximum_points: record.maximum_points, kind: record.kind } ]
    end
  end
end
