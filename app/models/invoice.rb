class Invoice < ApplicationRecord
  belongs_to :student
  belongs_to :fee_structure
  has_many :payments, dependent: :restrict_with_error
  enum :status, { unpaid: 0, partially_paid: 1, paid: 2, overdue: 3 }
  validates :amount, numericality: { greater_than: 0 }

  def paid_amount = payments.sum(:amount)
  def balance = amount - discount - paid_amount
end
