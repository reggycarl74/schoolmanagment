class PaymentInstallmentsController < ApplicationController
  before_action :require_finance

  def create
    invoice = school_invoice
    installment = invoice.payment_installments.create!(installment_params)
    AuditEvent.create!(school: current_school, user: current_user, auditable: installment, action: "installment_scheduled")
    redirect_to invoice_path(invoice), notice: "Payment installment scheduled."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to invoice_path(invoice), alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    invoice = school_invoice
    installment = invoice.payment_installments.find(params[:id])
    installment.destroy!
    redirect_to invoice_path(invoice), notice: "Payment installment removed."
  end

  private

  def school_invoice = Invoice.joins(:student).where(students: { school_id: current_school.id }).find(params[:invoice_id])
  def installment_params = params.expect(payment_installment: %i[name amount due_on])
end
