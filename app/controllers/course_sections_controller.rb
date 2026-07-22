class CourseSectionsController < ResourceIndexController
  before_action :require_staff

  def index
    scope = CourseSection.joins(:classroom).where(classrooms: { id: accessible_classrooms.select(:id) }).order(created_at: :desc)
    render_index(scope, title: "Course sections")
  end
end
