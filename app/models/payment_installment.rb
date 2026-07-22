class PaymentInstallment < ApplicationRecord
  belongs_to :invoice
  enum :status, { scheduled: 0, due: 1, completed: 2, waived: 3 }
  validates :name, :due_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validate :installments_do_not_exceed_invoice

  private

  def installments_do_not_exceed_invoice
    return unless invoice && amount
    scheduled_total = invoice.payment_installments.where.not(id:).sum(:amount) + amount
    errors.add(:amount, "makes the payment plan exceed the invoice total") if scheduled_total > invoice.amount
  end
end
