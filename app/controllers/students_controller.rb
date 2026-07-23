class StudentsController < ResourceIndexController
  before_action :require_administrator, only: %i[new create edit update import]
  before_action :load_classrooms, only: %i[new create edit update]
  before_action :set_student, only: %i[show edit update]

  def index
    @records = accessible_students.order(:last_name, :first_name).limit(50)
    respond_to do |format|
      format.html
      format.csv { send_data students_csv, filename: "students-#{Date.current}.csv" }
    end
  end

  def show
    @attendance = @student.enrollments.joins(:attendance_records).group("attendance_records.status").count
  end

  def new
    @student = current_school.students.new(admitted_on: Date.current, status: :active)
  end

  def create
    @student = current_school.students.new(student_params)

    if save_student
      redirect_to students_path, notice: "Student was added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @student.update(student_params)
      redirect_to @student, notice: "Student profile was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def import
    require "csv"
    imported = 0
    CSV.foreach(params[:file].path, headers: true) do |row|
      student = current_school.students.find_or_initialize_by(admission_number: row["admission_number"])
      student.assign_attributes(row.to_h.slice("first_name", "last_name", "date_of_birth", "gender", "admitted_on"))
      student.status ||= :active
      student.save!
      imported += 1
    end
    redirect_to students_path, notice: "Imported #{imported} students."
  rescue CSV::MalformedCSVError, ActiveRecord::RecordInvalid => error
    redirect_to students_path, alert: "Import failed: #{error.message}"
  end

  def assessments
    students = current_user.parent? ? accessible_students_with_guardian_permission(:academic_access) : accessible_students
    @student = students.find(params[:id])
    @grades = Grade.joins(:assessment, enrollment: :student)
      .where(enrollments: { student_id: @student.id })
      .includes(:enrollment, assessment: { course_section: %i[classroom subject term] })
      .order("assessments.due_on DESC", "assessments.title")
    @grades = @grades.where(assessments: { status: :published }) if current_user.parent? || current_user.student?
  end

  private

  def set_student
    @student = accessible_students.find(params[:id])
  end

  def student_params
    params.expect(student: %i[admission_number first_name last_name date_of_birth gender admitted_on status medical_notes])
  end

  def save_student
    ActiveRecord::Base.transaction do
      @student.save!
      classroom_id = params.dig(:student, :classroom_id)
      if classroom_id.present?
        classroom = current_school.classrooms.find(classroom_id)
        Enrollment.create!(student: @student, classroom:, enrolled_on: @student.admitted_on)
      end
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => error
    @student.errors.add(:base, error.message) if @student.errors.empty?
    false
  end

  def load_classrooms
    @classrooms = current_school.classrooms.includes(:academic_year).order(:name)
  end

  def students_csv
    require "csv"
    CSV.generate(headers: true) do |csv|
      csv << %w[admission_number first_name last_name date_of_birth gender admitted_on status]
      accessible_students.find_each { |student| csv << [ student.admission_number, student.first_name, student.last_name, student.date_of_birth, student.gender, student.admitted_on, student.status ] }
    end
  end
end
