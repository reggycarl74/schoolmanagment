class FinancialReportsController < ApplicationController
  before_action :require_finance
  require "csv"

  def show
    @from = params[:from].presence&.to_date || Date.current.beginning_of_month
    @to = params[:to].presence&.to_date || Date.current
    @invoices = Invoice.joins(:student).where(students: { school_id: current_school.id })
    @payments = Payment.joins(invoice: :student).where(students: { school_id: current_school.id }, paid_on: @from..@to)
      .active
    @invoiced = @invoices.sum(:amount)
    @collected = @payments.sum(:amount)
    @reconciled = @payments.where.not(reconciled_at: nil).sum(:amount)
    @unreconciled = @payments.where(reconciled_at: nil).sum(:amount)
    open_invoices = @invoices.where.not(status: :cancelled).includes(:payments, :billing_adjustments, :student)
    @outstanding = open_invoices.sum(&:balance)
    @aging = { "Current" => 0.to_d, "1–30 days" => 0.to_d, "31–60 days" => 0.to_d, "61–90 days" => 0.to_d, "90+ days" => 0.to_d }
    open_invoices.each do |invoice|
      days = (Date.current - invoice.due_on).to_i
      bucket = if days <= 0 then "Current" elsif days <= 30 then "1–30 days" elsif days <= 60 then "31–60 days" elsif days <= 90 then "61–90 days" else "90+ days" end
      @aging[bucket] += invoice.balance
    end

    respond_to do |format|
      format.html
      format.csv { send_data payment_csv, filename: "collections-#{@from}-to-#{@to}.csv" }
    end
  end

  private

  def payment_csv
    CSV.generate(headers: true) do |csv|
      csv << %w[receipt date student invoice method reference amount status]
      @payments.includes(invoice: :student).order(:paid_on).each do |payment|
        csv << [ payment.receipt_number, payment.paid_on, payment.invoice.student.full_name, payment.invoice.number, payment.payment_method, payment.reference, payment.amount, payment.reversed? ? "reversed" : "received" ]
      end
    end
  end
end
