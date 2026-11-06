class TeachersController < ResourceIndexController
  before_action :require_administrator
  def index
    scope = current_school.teachers.includes(:user, :homeroom_classrooms, :teaching_assignments, :assigned_classrooms, :assigned_subjects)
    @statistics = {
      total: current_school.teachers.count,
      active: current_school.teachers.where(active: true).count,
      portal_accounts: current_school.teachers.where.not(user_id: nil).count,
      unassigned: current_school.teachers.left_joins(:teaching_assignments).where(teaching_assignments: { id: nil }).distinct.count
    }
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip.downcase)}%"
      scope = scope.where("LOWER(teachers.first_name) LIKE :query OR LOWER(teachers.last_name) LIKE :query OR LOWER(teachers.email) LIKE :query OR LOWER(teachers.employee_number) LIKE :query", query:)
    end
    @records = scope.order(:last_name, :first_name).limit(100)
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
