class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice
  enum :category, { tuition: 0, transport: 1, meals: 2, books: 3, activities: 4, other: 5 }
  validates :description, presence: true
  validates :quantity, :unit_amount, numericality: { greater_than: 0 }
  after_save :recalculate_invoice
  after_destroy :recalculate_invoice

  def total = quantity * unit_amount

  private

  def recalculate_invoice
    new_total = invoice.line_items.reload.sum { |item| item.quantity * item.unit_amount }
    invoice.update_columns(amount: new_total, updated_at: Time.current) if new_total.positive?
  end
end
