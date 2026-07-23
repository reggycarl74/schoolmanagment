class ClassroomPostsController < ApplicationController
  before_action :require_classroom_portal_access
  before_action :require_teacher_or_administrator, only: %i[new create]

  def index
    @posts = post_scope.includes(:author, course_section: %i[classroom subject term]).with_attached_files.order(published_at: :desc).limit(100)
  end

  def show
    @post = post_scope.includes(:author, :student_submissions, course_section: %i[classroom subject term]).find(params[:id])
    @submission = if current_user.student?
      @post.student_submissions.find_or_initialize_by(student: current_user.student)
    end
  end

  def new
    @post = ClassroomPost.new(kind: :announcement, published_at: Time.current)
    load_courses
  end

  def create
    course = writable_courses.find(post_params[:course_section_id])
    @post = course.classroom_posts.new(post_params.except(:course_section_id, :files).merge(author: current_user))
    @post.files.attach(Array(post_params[:files]).reject(&:blank?))
    if @post.save
      redirect_to classroom_post_path(@post), notice: "Classroom post was published."
    else
      load_courses
      render :new, status: :unprocessable_entity
    end
  end

  private

  def post_scope
    ClassroomPost.joins(course_section: :classroom).where(classrooms: { id: accessible_classrooms.select(:id) })
  end

  def writable_courses
    scope = CourseSection.joins(:classroom).where(classrooms: { school_id: current_school.id })
    if current_user.teacher?
      scope = scope.where(
        "EXISTS (SELECT 1 FROM teaching_assignments ta WHERE ta.teacher_id = ? AND ta.classroom_id = course_sections.classroom_id AND ta.subject_id = course_sections.subject_id)",
        current_user.teacher.id
      )
    end
    scope.distinct
  end

  def load_courses
    @courses = writable_courses.includes(:classroom, :subject, :term).order("classrooms.name")
  end

  def post_params
    params.expect(classroom_post: [ :course_section_id, :kind, :title, :body, :due_at, :published_at, { files: [] } ])
  end

  def require_classroom_portal_access
    return if current_user.administrator? || current_user.teacher? || current_user.student? || current_user.parent?

    redirect_to root_path, alert: "The classroom portal is available to teachers, students, and guardians."
  end

  def require_teacher_or_administrator
    return if current_user.administrator? || current_user.teacher?

    redirect_to classroom_posts_path, alert: "Only teachers can publish classroom posts."
  end
end
