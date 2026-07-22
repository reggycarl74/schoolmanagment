class BillingStatementsController < ApplicationController
  before_action :set_student

  def show
    @entries = ledger_entries
    running_balance = 0.to_d
    @entries.each { |entry| entry[:balance] = running_balance += entry[:amount] }
  end

  def update
    require_administrator
    return if performed?

    @student.update!(billing_opening_balance: params.expect(student: :billing_opening_balance))
    AuditEvent.create!(school: current_school, user: current_user, auditable: @student, action: "billing_opening_balance_updated")
    redirect_to student_billing_statement_path(@student), notice: "Opening balance updated."
  end

  private

  def set_student
    @student = accessible_students.find(params[:student_id])
  end

  def ledger_entries
    entries = []
    if @student.billing_opening_balance.nonzero?
      entries << { date: @student.admitted_on, type: "Opening balance", reference: "OPENING", description: "Balance brought forward", amount: @student.billing_opening_balance }
    end
    @student.invoices.includes(:payments, :billing_adjustments).where.not(status: :cancelled).each do |invoice|
      entries << { date: invoice.issued_on, type: "Invoice", reference: invoice.number, description: invoice.fee_structure.name, amount: invoice.amount - invoice.discount }
      invoice.billing_adjustments.each do |adjustment|
        entries << { date: adjustment.created_at.to_date, type: adjustment.kind.humanize, reference: invoice.number, description: adjustment.reason, amount: adjustment.credit? ? -adjustment.amount : adjustment.amount }
      end
      invoice.payments.active.each do |payment|
        entries << { date: payment.paid_on, type: "Payment", reference: payment.receipt_number, description: payment.payment_method.humanize, amount: -payment.amount }
      end
    end
    entries.sort_by { |entry| [ entry[:date], entry[:type] == "Payment" ? 1 : 0 ] }
  end
end
