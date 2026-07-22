class BillingAdjustmentsController < ApplicationController
  before_action :require_administrator

  def create
    invoice = Invoice.joins(:student).where(students: { school_id: current_school.id }).find(params[:invoice_id])
    adjustment = invoice.billing_adjustments.create!(adjustment_params.merge(created_by: current_user, approved_by: current_user))
    invoice.refresh_status!
    AuditEvent.create!(school: current_school, user: current_user, auditable: adjustment, action: "billing_adjustment_approved")
    redirect_to invoice_path(invoice), notice: "#{adjustment.kind.humanize} adjustment applied."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to invoice_path(invoice), alert: error.record.errors.full_messages.to_sentence
  end

  private

  def adjustment_params = params.expect(billing_adjustment: %i[kind amount reason])
end
