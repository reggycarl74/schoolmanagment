class AcademicReportsController < ApplicationController
  require "csv"
  before_action :require_staff

  def show
    @classrooms = accessible_classrooms.includes(academic_year: :terms).order(:name)
    @classroom = accessible_classrooms.find_by(id: params[:classroom_id])
    @term = @classroom&.academic_year&.terms&.find_by(id: params[:term_id])
    @rows = report_rows
    @summary = report_summary
    respond_to do |format|
      format.html { render :results }
      format.csv { send_data report_csv, filename: "academic-performance-#{@classroom&.name&.parameterize || 'all'}.csv" }
    end
  end

  private

  def report_rows
    return [] unless @classroom && @term

    grades = Grade.joins(:enrollment, assessment: { course_section: :subject })
      .where(enrollments: { classroom_id: @classroom.id }, course_sections: { term_id: @term.id })
      .includes(enrollment: :student, assessment: { course_section: :subject })
    scales = current_school.grading_scales_for(@classroom).order(minimum_percentage: :desc).to_a
    grades.group_by(&:enrollment).map do |enrollment, records|
      earned = records.sum { |grade| grade.points.to_d }
      possible = records.sum { |grade| grade.assessment.maximum_points.to_d }
      percentage = possible.positive? ? earned / possible * 100 : 0
      scale = scales.find { |candidate| percentage >= candidate.minimum_percentage }
      { student: enrollment.student, earned:, possible:, percentage:, grade: scale&.letter || "—", remark: scale&.remark || "Not graded" }
    end.sort_by { |row| -row[:percentage] }
  end

  def report_summary
    return { total_students: 0, average_score: 0, pass_rate: 0 } if @rows.empty?

    passing = @rows.count { |row| row[:percentage] >= 50 }
    {
      total_students: @rows.size,
      average_score: @rows.sum { |row| row[:percentage] } / @rows.size,
      pass_rate: passing.to_d / @rows.size * 100
    }
  end

  def report_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[position admission_number student earned possible percentage grade remark]
      @rows.each_with_index do |row, index|
        csv << [ index + 1, row[:student].admission_number, row[:student].full_name, row[:earned], row[:possible], row[:percentage].round(2), row[:grade], row[:remark] ]
      end
    end
  end
end
