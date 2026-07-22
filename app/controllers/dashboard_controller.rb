class DashboardController < ApplicationController
  def index
    @statistics = if current_user.teacher?
      {
        "my students" => accessible_students.active.count,
        "my classes" => accessible_classrooms.count,
        "assigned subjects" => current_user.teacher&.course_sections&.select(:subject_id)&.distinct&.count || 0,
        "lesson plans" => current_user.teacher&.lesson_notes&.count || 0
      }
    else
      {
        students: accessible_students.active.count,
        teachers: current_school.teachers.where(active: true).count,
        classrooms: accessible_classrooms.count,
        subjects: current_school.subjects.count
      }
    end
  end
end
