class PaymentsController < ApplicationController
  before_action :require_finance

  def create
    invoice = Invoice.joins(:student).where(students: { school_id: current_school.id }).find(params[:invoice_id])
    payment = invoice.payments.create!(payment_params)
    invoice.update!(status: invoice.balance <= 0 ? :paid : :partially_paid)
    redirect_to invoices_path, notice: "Payment #{payment.reference} was recorded."
  end

  private

  def payment_params = params.expect(payment: %i[amount paid_on reference payment_method])
end
