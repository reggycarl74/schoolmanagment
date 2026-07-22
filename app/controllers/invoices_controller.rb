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
    student = current_school.students.find(invoice_params[:student_id])
    fee = current_school.fee_structures.find(invoice_params[:fee_structure_id])
    @invoice = Invoice.new(student:, fee_structure: fee, amount: invoice_params[:amount], due_on: invoice_params[:due_on])
    return redirect_to(invoices_path, notice: "Invoice was created.") if @invoice.save

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

  def invoice_params = params.expect(invoice: %i[student_id fee_structure_id amount due_on])

  def load_options
    @students = current_school.students.active.order(:last_name)
    @fees = current_school.fee_structures.includes(:academic_year).order(due_on: :desc)
  end
end
