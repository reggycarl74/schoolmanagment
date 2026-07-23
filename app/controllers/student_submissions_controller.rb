class StudentSubmissionsController < ApplicationController
  before_action :set_post

  def create
    require_student
    return if performed?

    submission = @post.student_submissions.find_or_initialize_by(student: current_user.student)
    save_student_submission(submission)
  end

  def update
    submission = @post.student_submissions.find(params[:id])
    if current_user.student?
      return redirect_to(root_path, alert: "That submission is not yours.") unless submission.student_id == current_user.student_id

      save_student_submission(submission)
    else
      require_teacher_or_administrator
      return if performed?

      submission.update!(params.expect(student_submission: %i[score feedback status]))
      redirect_to classroom_post_path(@post), notice: "Submission feedback was saved."
    end
  end

  private

  def set_post
    @post = ClassroomPost.joins(course_section: :classroom).where(classrooms: { id: accessible_classrooms.select(:id) }).find(params[:classroom_post_id])
  end

  def save_student_submission(submission)
    attributes = params.expect(student_submission: [ :body, { files: [] } ])
    submission.assign_attributes(body: attributes[:body], status: :submitted, submitted_at: Time.current)
    submission.files.attach(Array(attributes[:files]).reject(&:blank?))
    submission.save!
    redirect_to classroom_post_path(@post), notice: "Your work was submitted."
  end

  def require_student
    return if current_user.student? && current_user.student

    redirect_to classroom_post_path(@post), alert: "Only students can submit work."
  end

  def require_teacher_or_administrator
    return if current_user.administrator? || current_user.teacher?

    redirect_to root_path, alert: "You do not have permission to grade submissions."
  end
end
