class TimetableEntriesController < ApplicationController
  before_action :require_staff
  before_action :require_administrator, only: %i[new create destroy]
  before_action :load_options, only: %i[new create]

  def index
    scope = TimetableEntry.joins(course_section: :classroom).where(classrooms: { id: accessible_classrooms.select(:id) })
    @entries = scope.includes(:teacher, course_section: %i[classroom subject]).order(:weekday, :period)
  end

  def new = @entry = TimetableEntry.new

  def create
    @entry = TimetableEntry.new(entry_params)
    if @entry.save
      TimetableNotificationService.created(@entry)
      return redirect_to(timetable_entries_path, notice: "Timetable period was added and the teacher was notified.")
    end

    render :new, status: :unprocessable_entity
  end

  def destroy
    TimetableEntry.joins(course_section: :classroom).where(classrooms: { school_id: current_school.id }).find(params[:id]).destroy!
    redirect_to timetable_entries_path, notice: "Timetable period was removed."
  end

  private

  def entry_params = params.expect(timetable_entry: %i[course_section_id teacher_id weekday period starts_at ends_at room])

  def load_options
    @courses = CourseSection.joins(:classroom).where(classrooms: { school_id: current_school.id }).includes(:classroom, :subject, :term)
    @teachers = current_school.teachers.where(active: true).order(:last_name)
  end
end
