class AssessmentSettingsController < ApplicationController
  before_action :require_administrator

  def show
    @components = current_school.assessment_components.order(:position)
    @scales = current_school.grading_scales.order(minimum_percentage: :desc)
  end

  def create
    record = if params[:setting_type] == "scale"
      current_school.grading_scales.new(params.expect(grading_scale: %i[letter minimum_percentage remark]))
    else
      current_school.assessment_components.new(params.expect(assessment_component: %i[title maximum_points kind position active]))
    end
    record.save!
    redirect_to assessment_settings_path, notice: "Assessment setting was added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to assessment_settings_path, alert: error.record.errors.full_messages.to_sentence
  end
end
