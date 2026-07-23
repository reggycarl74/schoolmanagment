class PaymentsController < ApplicationController
  before_action :require_finance, only: :create
  before_action :require_administrator, only: :reverse
  before_action :authorize_billing, only: :show

  def create
    invoice = school_invoice
    payment = invoice.payments.create!(payment_params.merge(recorded_by: current_user))
    invoice.refresh_status!
    audit(payment, "payment_recorded")
    notify_guardians(payment)
    redirect_to invoice_payment_path(invoice, payment), notice: "Payment #{payment.reference} was recorded."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to invoice_path(invoice), alert: error.record.errors.full_messages.to_sentence
  end

  def show
    @invoice = school_invoice
    @payment = @invoice.payments.find(params[:id])
  end

  def reverse
    @invoice = school_invoice
    payment = @invoice.payments.active.find(params[:id])
    reason = params[:reversal_reason].to_s.strip
    return redirect_to(invoice_payment_path(@invoice, payment), alert: "Provide a reversal reason.") if reason.blank?

    payment.update!(reversed_at: Time.current, reversed_by: current_user, reversal_reason: reason)
    @invoice.refresh_status!
    audit(payment, "payment_reversed")
    redirect_to invoice_path(@invoice), notice: "Payment #{payment.reference} was reversed without deleting its audit history."
  end

  private

  def authorize_billing
    return if current_user.administrator? || current_user.accountant?
    students = current_user.parent? ? accessible_students_with_guardian_permission(:billing_access) : accessible_students
    return if students.where(id: school_invoice.student_id).exists?

    redirect_to root_path, alert: "You do not have permission to view that receipt."
  end

  def school_invoice = Invoice.joins(:student).where(students: { school_id: current_school.id }).find(params[:invoice_id])

  def payment_params = params.expect(payment: %i[amount paid_on reference payment_method])

  def audit(record, action)
    AuditEvent.create!(school: current_school, user: current_user, auditable: record, action:)
  end

  def notify_guardians(payment)
    payment.invoice.student.guardians.merge(StudentGuardian.for_billing).where(active: true).find_each do |guardian|
      delivery = NotificationDelivery.create!(school: current_school, recipient: guardian, channel: :email, subject: "Payment received", body: "Receipt #{payment.receipt_number}: received #{payment.amount} #{current_school.currency_code} for #{payment.invoice.student.full_name}. Remaining balance: #{payment.invoice.balance}.")
      NotificationDeliveryJob.perform_later(delivery)
    end
  end
end
