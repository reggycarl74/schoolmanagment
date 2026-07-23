class AssessmentSettingsController < ApplicationController
  before_action :require_administrator

  def show
    @classrooms = current_school.classrooms.includes(academic_year: :terms).order(:name)
    @classroom = current_school.classrooms.find_by(id: params[:classroom_id])
    @components = current_school.assessment_components.where(classroom: @classroom).order(:position)
    @scales = current_school.grading_scales.order(minimum_percentage: :desc)
    @subjects = current_school.subjects.order(:name)
    @subject_positions = @classroom ? @classroom.class_subject_orders.index_by(&:subject_id) : {}
  end

  def create
    if params[:setting_type] == "classroom"
      return save_classroom_configuration
    end

    record = if params[:setting_type] == "scale"
      current_school.grading_scales.new(params.expect(grading_scale: %i[letter minimum_percentage remark]))
    else
      classroom = current_school.classrooms.find_by(id: params.dig(:assessment_component, :classroom_id))
      current_school.assessment_components.new(params.expect(assessment_component: %i[classroom_id title maximum_points kind position active]).merge(classroom: classroom))
    end
    record.save!
    redirect_to assessment_settings_path, notice: "Assessment setting was added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to assessment_settings_path, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def save_classroom_configuration
    classroom = current_school.classrooms.find(params[:classroom_id])
    term = params[:result_entry_term_id].present? ? classroom.academic_year.terms.find(params[:result_entry_term_id]) : nil
    positions = params.fetch(:subject_positions, {}).permit!.to_h

    ActiveRecord::Base.transaction do
      classroom.update!(result_entry_term: term)
      classroom.class_subject_orders.destroy_all
      positions.filter_map { |subject_id, position| [ subject_id, position ] if position.present? }.each do |subject_id, position|
        classroom.class_subject_orders.create!(subject: current_school.subjects.find(subject_id), position: position)
      end
    end
    redirect_to assessment_settings_path(classroom_id: classroom.id), notice: "Class assessment workflow was updated."
  end
end
