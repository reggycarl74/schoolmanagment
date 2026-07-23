class TeachersController < ResourceIndexController
  before_action :require_administrator
  def index
    @records = current_school.teachers.includes(:teaching_assignments, :assigned_classrooms).order(:last_name, :first_name).limit(50)
  end

  def new
    @teacher = current_school.teachers.new(active: true)
  end

  def create
    @teacher = current_school.teachers.new(teacher_params)

    if @teacher.save
      redirect_to teachers_path, notice: "Teacher was added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def teacher_params
    params.expect(teacher: %i[employee_number first_name last_name email phone hired_on active])
  end
end
