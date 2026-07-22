class AcademicYearRolloversController < ApplicationController
  before_action :require_administrator

  def new
    @source_year = current_school.academic_years.find_by(current: true) || current_school.academic_years.order(:starts_on).last
    @classrooms = @source_year&.classrooms&.includes(:grade_level)
  end

  def create
    source = current_school.academic_years.find(params[:source_year_id])
    target = nil
    ActiveRecord::Base.transaction do
      current_school.academic_years.where(current: true).update_all(current: false)
      target = current_school.academic_years.create!(rollover_params.merge(current: true))
      create_terms(target)
      source.classrooms.where(id: params[:classroom_ids]).includes(:enrollments).each do |old_class|
        new_class = current_school.classrooms.create!(academic_year: target, grade_level: old_class.grade_level, name: old_class.name, capacity: old_class.capacity, homeroom_teacher: old_class.homeroom_teacher)
        old_class.enrollments.enrolled.each do |old_enrollment|
          old_enrollment.update!(status: :completed, left_on: source.ends_on)
          Enrollment.create!(student: old_enrollment.student, classroom: new_class, enrolled_on: target.starts_on)
        end
      end
    end
    redirect_to root_path, notice: "Academic year #{target.name} was created and selected classes were rolled over."
  end

  private

  def rollover_params = params.expect(academic_year: %i[name starts_on ends_on])

  def create_terms(year)
    duration = ((year.ends_on - year.starts_on).to_i / 3)
    3.times do |index|
      starts_on = year.starts_on + (duration * index).days
      ends_on = index == 2 ? year.ends_on : year.starts_on + (duration * (index + 1)).days - 1.day
      year.terms.create!(name: "Term #{index + 1}", position: index + 1, starts_on:, ends_on:)
    end
  end
end
