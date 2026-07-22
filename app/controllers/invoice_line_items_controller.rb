class InvoiceLineItemsController < ApplicationController
  before_action :require_finance

  def create
    invoice = school_invoice
    return redirect_to(invoice_path(invoice), alert: "Use an audited adjustment after payments have been recorded.") unless charges_editable?(invoice)

    item = invoice.line_items.create!(line_item_params)
    audit(item, "invoice_line_item_added")
    redirect_to invoice_path(invoice), notice: "Invoice line item added."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to invoice_path(invoice), alert: error.record.errors.full_messages.to_sentence
  end

  def destroy
    invoice = school_invoice
    return redirect_to(invoice_path(invoice), alert: "Use an audited adjustment after payments have been recorded.") unless charges_editable?(invoice)

    item = invoice.line_items.find(params[:id])
    return redirect_to(invoice_path(invoice), alert: "An invoice must keep at least one line item.") if invoice.line_items.one?

    audit(item, "invoice_line_item_removed")
    item.destroy!
    redirect_to invoice_path(invoice), notice: "Invoice line item removed."
  end

  private

  def school_invoice = Invoice.joins(:student).where(students: { school_id: current_school.id }).find(params[:invoice_id])
  def line_item_params = params.expect(invoice_line_item: %i[description category quantity unit_amount])
  def audit(record, action) = AuditEvent.create!(school: current_school, user: current_user, auditable: record, action:)
  def charges_editable?(invoice) = !invoice.cancelled? && invoice.paid_amount.zero?
end
