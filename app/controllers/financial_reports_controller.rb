class FinancialReportsController < ApplicationController
  before_action :require_finance

  def show
    @from = params[:from].presence&.to_date || Date.current.beginning_of_month
    @to = params[:to].presence&.to_date || Date.current
    @invoices = Invoice.joins(:student).where(students: { school_id: current_school.id })
    @payments = Payment.joins(invoice: :student).where(students: { school_id: current_school.id }, paid_on: @from..@to)
    @invoiced = @invoices.sum(:amount)
    @collected = @payments.sum(:amount)
    @outstanding = @invoices.to_a.sum(&:balance)
  end
end
