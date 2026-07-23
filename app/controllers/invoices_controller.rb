class InvoicesController < ApplicationController
  before_action :authorize_billing
  before_action :require_finance, only: %i[new create]
  before_action :require_finance, only: :send_reminder
  before_action :require_administrator, only: :cancel

  def index
    invoice_scope.where(status: :unpaid).where("due_on < ?", Date.current).update_all(status: Invoice.statuses[:overdue])
    @invoices = invoice_scope.includes(:payments, :billing_adjustments, :fee_structure, :student).order(created_at: :desc)
    @total_outstanding = @invoices.reject(&:cancelled?).sum(&:balance)
    @total_collected = @invoices.sum(&:paid_amount)
  end

  def show
    @invoice = invoice_scope.includes(:line_items, :billing_adjustments, :payment_installments, payments: %i[recorded_by reversed_by]).find(params[:id])
  end

  def new
    @invoice = Invoice.new
    load_options
  end

  def create
    fee = current_school.fee_structures.find(invoice_params[:fee_structure_id])
    student_ids = Array(invoice_params[:student_ids]).reject(&:blank?).uniq
    @invoice = Invoice.new(fee_structure: fee)

    if student_ids.empty?
      @invoice.errors.add(:base, "Select at least one student")
      load_options
      return render :new, status: :unprocessable_entity
    end

    students = current_school.students.active.find(student_ids)
    created_count = 0
    skipped_count = 0

    ActiveRecord::Base.transaction do
      students.each do |student|
        invoice = Invoice.find_or_initialize_by(student:, fee_structure: fee)
        if invoice.persisted?
          skipped_count += 1
        else
          invoice.update!(amount: fee.amount, due_on: fee.due_on)
          invoice.line_items.create!(description: fee.name, category: :tuition, quantity: 1, unit_amount: fee.amount)
          created_count += 1
        end
      end
    end

    message = "Generated #{created_count} #{'invoice'.pluralize(created_count)}."
    message += " Skipped #{skipped_count} existing #{'invoice'.pluralize(skipped_count)}." if skipped_count.positive?
    redirect_to invoices_path, notice: message
  rescue ActiveRecord::RecordNotFound
    @invoice ||= Invoice.new
    @invoice.errors.add(:base, "One or more selected students or the fee structure is invalid")
    load_options
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => error
    @invoice ||= error.record
    @invoice.errors.add(:base, error.record.errors.full_messages.to_sentence)

    load_options
    render :new, status: :unprocessable_entity
  end

  def cancel
    invoice = school_invoice
    return redirect_to(invoice_path(invoice), alert: "Paid invoices cannot be cancelled.") if invoice.paid_amount.positive?

    invoice.update!(status: :cancelled, cancelled_at: Time.current, cancelled_by: current_user)
    audit(invoice, "invoice_cancelled")
    redirect_to invoice_path(invoice), notice: "Invoice #{invoice.number} was cancelled."
  end

  def send_reminder
    invoice = school_invoice
    invoice.student.guardians.merge(StudentGuardian.for_billing).where(active: true).find_each do |guardian|
      delivery = NotificationDelivery.create!(school: current_school, recipient: guardian, channel: :email, subject: "Fee payment reminder", body: "#{invoice.number} for #{invoice.student.full_name} has an outstanding balance of #{invoice.balance} #{current_school.currency_code}, due #{invoice.due_on}.")
      NotificationDeliveryJob.perform_later(delivery)
    end
    audit(invoice, "payment_reminder_sent")
    redirect_to invoice_path(invoice), notice: "Payment reminder queued for the student's guardians."
  end

  private

  def authorize_billing
    return if current_user.administrator? || current_user.accountant? || current_user.parent? || current_user.student?

    redirect_to root_path, alert: "You do not have permission to view billing."
  end

  def invoice_scope
    return Invoice.joins(:student).where(students: { school_id: current_school.id }) unless current_user.parent? || current_user.student?

    students = current_user.parent? ? accessible_students_with_guardian_permission(:billing_access) : accessible_students
    Invoice.where(student_id: students.select(:id))
  end

  def school_invoice = Invoice.joins(:student).where(students: { school_id: current_school.id }).find(params[:id])

  def audit(record, action)
    AuditEvent.create!(school: current_school, user: current_user, auditable: record, action:)
  end

  def invoice_params = params.expect(invoice: [ :fee_structure_id, { student_ids: [] } ])

  def load_options
    @students = current_school.students.active.includes(:classrooms).order(:last_name, :first_name)
    @fees = current_school.fee_structures.includes(:academic_year).order(due_on: :desc)
  end
end
