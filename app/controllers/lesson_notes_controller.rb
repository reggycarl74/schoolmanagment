class LessonNotesController < ApplicationController
  before_action :require_staff
  before_action :set_lesson_note, only: %i[edit update]
  before_action :load_options, only: %i[new create edit update]

  def index
    scope = LessonNote.joins(course_section: :classroom).where(classrooms: { id: accessible_classrooms.select(:id) })
    scope = scope.where(teacher_id: current_user.teacher.id) if current_user.teacher?
    if current_user.administrator?
      scope = scope.where(teacher_id: params[:teacher_id]) if params[:teacher_id].present?
      scope = scope.where(classrooms: { id: params[:classroom_id] }) if params[:classroom_id].present?
      @teachers = current_school.teachers.where(active: true).order(:last_name, :first_name)
      @classrooms = current_school.classrooms.order(:name)
    end
    @lesson_notes = scope.with_attached_files.includes(:teacher, course_section: %i[classroom subject term]).order(lesson_date: :desc, starts_at: :asc).limit(100)
  end

  def new
    terms = @assignments.map { |assignment| assignment.course_section.term }.uniq
    current_term = terms.find { |term| Date.current.between?(term.starts_on, term.ends_on) }
    next_term = terms.select { |term| term.starts_on > Date.current }.min_by(&:starts_on)
    @lesson_note = LessonNote.new(lesson_date: current_term ? Date.current : next_term&.starts_on, status: :draft, duration_minutes: 45)
  end

  def create
    assignment = available_assignments.find(plan_params[:teaching_assignment_id])
    @lesson_note = assignment.course_section.lesson_notes.new(plan_attributes.merge(teacher: assignment.teacher))
    LessonPlanDocumentReader.prefill(@lesson_note, uploaded_files) if prefill_from_files?
    @lesson_note.files.attach(uploaded_files) if uploaded_files.any?

    if @lesson_note.save
      redirect_to lesson_notes_path, notice: "Lesson plan was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    @lesson_note ||= LessonNote.new(plan_attributes)
    @form_error = "Choose one of your assigned classes and subjects."
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    attributes = plan_attributes
    if plan_params[:teaching_assignment_id].present?
      assignment = available_assignments.find(plan_params[:teaching_assignment_id])
      attributes = attributes.merge(course_section: assignment.course_section, teacher: assignment.teacher)
    end
    @lesson_note.assign_attributes(attributes)
    LessonPlanDocumentReader.prefill(@lesson_note, uploaded_files) if prefill_from_files?
    @lesson_note.files.attach(uploaded_files) if uploaded_files.any?

    if @lesson_note.save
      redirect_to lesson_notes_path, notice: "Lesson plan was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_lesson_note
    scope = LessonNote.joins(course_section: :classroom).where(classrooms: { school_id: current_school.id })
    scope = scope.where(teacher_id: current_user.teacher.id) if current_user.teacher?
    @lesson_note = scope.find(params[:id])
  end

  def plan_params
    params.expect(lesson_note: [ :teaching_assignment_id, :lesson_date, :starts_at, :duration_minutes, :topic, :objectives, :materials, :content, :homework, :status, :prefill_from_files, { files: [] } ])
  end

  def plan_attributes
    plan_params.except(:teaching_assignment_id, :files, :prefill_from_files)
  end

  def uploaded_files
    Array(plan_params[:files]).reject(&:blank?)
  end

  def prefill_from_files?
    ActiveModel::Type::Boolean.new.cast(plan_params[:prefill_from_files]) && uploaded_files.any?
  end

  def available_assignments
    scope = TeachingAssignment.joins(course_section: :classroom).where(classrooms: { school_id: current_school.id })
    scope = scope.where(teacher_id: current_user.teacher.id) if current_user.teacher?
    scope.includes(:teacher, course_section: %i[classroom subject term])
  end

  def load_options
    @assignments = available_assignments.order("classrooms.name")
  end
end
