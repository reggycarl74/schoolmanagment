class InvoicesController < ApplicationController
  before_action :authorize_billing
  before_action :require_finance, only: %i[new create]

  def index
    @invoices = invoice_scope.includes(:payments, :fee_structure, :student).order(created_at: :desc)
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

  private

  def authorize_billing
    return if current_user.administrator? || current_user.accountant? || current_user.parent? || current_user.student?

    redirect_to root_path, alert: "You do not have permission to view billing."
  end

  def invoice_scope
    return Invoice.joins(:student).where(students: { school_id: current_school.id }) unless current_user.parent? || current_user.student?

    Invoice.where(student_id: accessible_students.select(:id))
  end

  def invoice_params = params.expect(invoice: [ :fee_structure_id, { student_ids: [] } ])

  def load_options
    @students = current_school.students.active.includes(:classrooms).order(:last_name, :first_name)
    @fees = current_school.fee_structures.includes(:academic_year).order(due_on: :desc)
  end
end
