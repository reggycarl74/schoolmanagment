class ReportCardRemarkTemplatesController < ApplicationController
  before_action :require_staff
  before_action :set_kinds
  before_action :set_template, only: %i[edit update]

  def index
    @templates = current_school.report_card_remark_templates.includes(:author).order(:kind, :title)
    @template = current_school.report_card_remark_templates.new(kind: :homeroom_teacher, active: true)
  end

  def create
    template = current_school.report_card_remark_templates.new(template_params.merge(author: current_user))
    template.save!
    redirect_to report_card_remark_templates_path, notice: "Teacher remark was added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to report_card_remark_templates_path, alert: error.record.errors.full_messages.to_sentence
  end

  def edit; end

  def update
    @template.update!(template_params)
    redirect_to report_card_remark_templates_path, notice: "Teacher remark was updated."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  private

  def set_template
    @template = current_school.report_card_remark_templates.find(params[:id])
    return if current_user.administrator? || @template.author == current_user

    redirect_to report_card_remark_templates_path, alert: "You can only edit remarks that you created."
  end

  def template_params
    permitted = params.expect(report_card_remark_template: %i[title body kind active])
    permitted[:kind] = "homeroom_teacher" if !current_user.administrator? && permitted[:kind] == "administrator"
    permitted
  end

  def set_kinds
    @kinds = ReportCardRemarkTemplate.kinds.keys
    @kinds -= [ "administrator" ] unless current_user.administrator?
  end
end
