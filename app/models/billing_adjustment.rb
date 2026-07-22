class BillingAdjustment < ApplicationRecord
  belongs_to :invoice
  belongs_to :created_by, class_name: "User"
  belongs_to :approved_by, class_name: "User"
  enum :kind, { discount: 0, scholarship: 1, credit: 2, charge: 3, refund: 4 }
  validates :amount, numericality: { greater_than: 0 }
  validates :reason, presence: true

  def self.credit_kinds = kinds.values_at("discount", "scholarship", "credit")
  def self.debit_kinds = kinds.values_at("charge", "refund")
  def credit? = kind.in?(%w[discount scholarship credit])
end
