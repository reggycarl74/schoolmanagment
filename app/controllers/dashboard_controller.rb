class DashboardController < ApplicationController
  def index
    @statistics = if current_user.teacher?
      {
        "my students" => accessible_students.active.count,
        "my classes" => accessible_classrooms.count,
        "assigned subjects" => current_user.teacher&.teaching_assignments&.select(:subject_id)&.distinct&.count || 0,
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
    @recent_announcements = current_school.announcements.order(published_at: :desc).limit(4)
    @published_assessments = Assessment.joins(course_section: :classroom).where(classrooms: { school_id: current_school.id }, status: :published).count
    percentages = Grade.joins(enrollment: :student, assessment: { course_section: :classroom })
      .where(students: { school_id: current_school.id }, classrooms: { school_id: current_school.id })
      .where.not(points: nil).pluck("grades.points", "assessments.maximum_points")
      .filter_map { |points, maximum| maximum.to_d.positive? ? points.to_d / maximum.to_d * 100 : nil }
    @overall_performance = percentages.any? ? percentages.sum / percentages.size : 0
  end
end
