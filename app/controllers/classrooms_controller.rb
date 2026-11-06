class ClassroomsController < ResourceIndexController
  before_action :require_administrator, only: %i[new create edit update]
  before_action :set_classroom, only: %i[edit update]
  before_action :load_options, only: %i[new create edit update]

  def index
    @records = accessible_classrooms.includes(:academic_year, :grade_level, :homeroom_teacher).order(created_at: :desc).limit(50)
  end

  def new
    @classroom = current_school.classrooms.new
  end

  def create
    @classroom = current_school.classrooms.new(classroom_params)

    if @classroom.save
      redirect_to classrooms_path, notice: "Class was added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @classroom.update(classroom_params)
      redirect_to classrooms_path, notice: "Class settings were updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def classroom_params
    params.expect(classroom: %i[name academic_year_id grade_level_id homeroom_teacher_id capacity report_template])
  end

  def set_classroom
    @classroom = current_school.classrooms.find(params[:id])
  end

  def load_options
    @academic_years = current_school.academic_years.order(starts_on: :desc)
    @grade_levels = current_school.grade_levels.order(:position)
    @teachers = current_school.teachers.where(active: true).order(:last_name, :first_name)
  end
end
