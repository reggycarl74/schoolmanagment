class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @results = {}
    return if @query.blank?

    pattern = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
    @results["Students"] = accessible_students.where("students.first_name LIKE :q OR students.last_name LIKE :q OR students.admission_number LIKE :q", q: pattern).order(:last_name).limit(20)
    @results["Classes"] = accessible_classrooms.where("classrooms.name LIKE ?", pattern).order(:name).limit(20)
    @results["Subjects"] = current_school.subjects.where("name LIKE :q OR code LIKE :q", q: pattern).order(:name).limit(20)
    audiences = case current_user.role
    when "teacher", "registrar", "accountant" then %i[everyone staff]
    when "parent" then %i[everyone parents]
    when "student" then %i[everyone students]
    else Announcement.audiences.keys
    end
    @results["Announcements"] = current_school.announcements.where(audience: audiences).where("title LIKE :q OR body LIKE :q", q: pattern).order(published_at: :desc).limit(20)

    if current_user.administrator?
      @results["Teachers"] = current_school.teachers.where("first_name LIKE :q OR last_name LIKE :q OR employee_number LIKE :q OR email LIKE :q", q: pattern).order(:last_name).limit(20)
      @results["Guardians"] = current_school.guardians.where("first_name LIKE :q OR last_name LIKE :q OR phone LIKE :q OR email LIKE :q", q: pattern).order(:last_name).limit(20)
    end

    if current_user.administrator? || current_user.teacher? || current_user.registrar?
      plans = LessonNote.joins(:teacher, course_section: %i[classroom subject]).where(classrooms: { id: accessible_classrooms.select(:id) })
      plans = plans.where(teacher_id: current_user.teacher.id) if current_user.teacher?
      @results["Lesson plans"] = plans.where("lesson_notes.topic LIKE :q OR lesson_notes.content LIKE :q OR subjects.name LIKE :q OR classrooms.name LIKE :q OR teachers.first_name LIKE :q OR teachers.last_name LIKE :q", q: pattern).includes(:teacher, course_section: %i[classroom subject]).limit(20)
    end

    if current_user.administrator? || current_user.accountant?
      @results["Fees"] = current_school.fee_structures.where("name LIKE ?", pattern).order(due_on: :desc).limit(20)
      @results["Invoices"] = Invoice.joins(:student, :fee_structure).where(students: { school_id: current_school.id }).where("students.first_name LIKE :q OR students.last_name LIKE :q OR fee_structures.name LIKE :q", q: pattern).includes(:student, :fee_structure).limit(20)
    end
  end
end
