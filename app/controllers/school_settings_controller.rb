class SchoolSettingsController < ApplicationController
  before_action :require_administrator

  def show
    @terms = current_school.academic_years.includes(:terms).flat_map(&:terms).sort_by(&:starts_on).reverse
  end

  def update
    ActiveRecord::Base.transaction do
      current_school.update!(school_params)
      current_school.logo.attach(params.dig(:school, :logo)) if params.dig(:school, :logo).present?
      current_school.logo.purge if params[:remove_logo] == "1"

      if params[:term_id].present?
        term = Term.joins(:academic_year).where(academic_years: { school_id: current_school.id }).find(params[:term_id])
        term.update!(reopening_date: params[:reopening_date].presence)
      end
    end
    redirect_to school_setting_path, notice: "School branding and report-card settings were updated."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to school_setting_path, alert: error.record.errors.full_messages.to_sentence
  end

  private

  def school_params
    params.expect(school: %i[name email phone address])
  end
end
