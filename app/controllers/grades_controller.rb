class GradesController < ApplicationController
  before_action :require_staff
  before_action :set_grade

  def edit
  end

  def update
    if @grade.update(grade_params.merge(graded_at: Time.current))
      redirect_to assessments_student_path(@grade.enrollment.student), notice: "Assessment result was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_grade
    @grade = Grade.joins(enrollment: :student)
      .where(students: { id: accessible_students.select(:id) })
      .includes(:enrollment, assessment: { course_section: %i[classroom subject term] })
      .find(params[:id])
  end

  def grade_params
    params.expect(grade: %i[points feedback])
  end
end
