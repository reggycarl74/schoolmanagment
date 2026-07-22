class Payment < ApplicationRecord
  belongs_to :invoice
  enum :payment_method, { cash: 0, bank_transfer: 1, card: 2, mobile_money: 3 }
  validates :reference, :paid_on, presence: true
  validates :reference, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }
end
