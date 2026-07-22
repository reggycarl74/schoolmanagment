module SchoolAccess
  extend ActiveSupport::Concern

  private

  def accessible_classrooms
    case current_user.role
    when "teacher" then current_user.teacher&.accessible_classrooms || Classroom.none
    when "parent", "student" then current_school.classrooms.joins(:students).where(students: { id: accessible_students.select(:id) }).distinct
    else current_school.classrooms
    end
  end

  def accessible_students
    case current_user.role
    when "teacher"
      current_school.students.joins(:enrollments)
        .where(enrollments: { classroom_id: current_user.teacher&.accessible_classrooms&.select(:id), status: Enrollment.statuses[:enrolled] })
        .distinct
    when "parent" then current_user.guardian&.students || Student.none
    when "student" then current_school.students.where(id: current_user.student_id)
    else current_school.students
    end
  end

  def require_administrator
    return if current_user.administrator?

    redirect_to root_path, alert: "You do not have permission to manage that section."
  end

  def require_administrator_or_registrar
    return if current_user.administrator? || current_user.registrar?

    redirect_to root_path, alert: "You do not have permission to manage that section."
  end

  def require_staff
    return if current_user.administrator? || current_user.teacher? || current_user.registrar?

    redirect_to root_path, alert: "You do not have permission to manage that section."
  end

  def require_finance
    return if current_user.administrator? || current_user.accountant?

    redirect_to root_path, alert: "You do not have permission to manage billing."
  end
end
