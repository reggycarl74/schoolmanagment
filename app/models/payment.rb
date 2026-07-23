class Payment < ApplicationRecord
  belongs_to :invoice
  belongs_to :recorded_by, class_name: "User", optional: true
  belongs_to :reversed_by, class_name: "User", optional: true
  belongs_to :reconciled_by, class_name: "User", optional: true
  has_many :notification_deliveries, as: :source, dependent: :nullify
  enum :payment_method, { cash: 0, bank_transfer: 1, card: 2, mobile_money: 3 }
  before_validation :assign_receipt_number, on: :create
  scope :active, -> { where(reversed_at: nil) }
  validates :reference, :paid_on, presence: true
  validates :reference, uniqueness: true
  validates :receipt_number, presence: true, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }
  validate :amount_does_not_exceed_balance, on: :create
  validate :invoice_accepts_payments, on: :create

  def reversed? = reversed_at.present?
  def reconciled? = reconciled_at.present?

  private

  def assign_receipt_number
    self.receipt_number ||= "RCT-#{Date.current.year}-#{SecureRandom.hex(4).upcase}"
  end

  def amount_does_not_exceed_balance
    return unless invoice && amount
    return if amount <= invoice.balance

    errors.add(:amount, "cannot exceed the outstanding balance")
  end

  def invoice_accepts_payments
    errors.add(:invoice, "is cancelled and cannot accept payments") if invoice&.cancelled?
  end
end
