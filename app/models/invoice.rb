class Invoice < ApplicationRecord
  belongs_to :student
  belongs_to :fee_structure
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :payments, dependent: :restrict_with_error
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy
  has_many :billing_adjustments, dependent: :restrict_with_error
  has_many :payment_installments, dependent: :destroy
  enum :status, { unpaid: 0, partially_paid: 1, paid: 2, overdue: 3, cancelled: 4, draft: 5 }
  before_validation :assign_number, on: :create
  before_validation :set_issued_on, on: :create
  validates :number, presence: true, uniqueness: true
  validates :amount, numericality: { greater_than: 0 }
  validates :charge_on, uniqueness: { scope: %i[student_id fee_structure_id] }, allow_nil: true

  def paid_amount = payments.active.sum(:amount)
  def credit_adjustments = billing_adjustments.where(kind: BillingAdjustment.credit_kinds).sum(:amount)
  def debit_adjustments = billing_adjustments.where(kind: BillingAdjustment.debit_kinds).sum(:amount)
  def balance = amount + debit_adjustments - discount - credit_adjustments - paid_amount

  def refresh_status!
    return if cancelled?

    next_status = if balance <= 0
      :paid
    elsif paid_amount.positive?
      :partially_paid
    elsif due_on < Date.current
      :overdue
    else
      :unpaid
    end
    update!(status: next_status) unless public_send("#{next_status}?")
    refresh_installments!
  end

  def refresh_installments!
    remaining_payment = paid_amount
    payment_installments.order(:due_on, :id).each do |installment|
      next if installment.waived?

      next_status = if remaining_payment >= installment.amount
        remaining_payment -= installment.amount
        :completed
      elsif installment.due_on <= Date.current
        :due
      else
        :scheduled
      end
      installment.update!(status: next_status) unless installment.public_send("#{next_status}?")
    end
  end

  private

  def assign_number
    self.number ||= "INV-#{Date.current.year}-#{SecureRandom.hex(4).upcase}"
  end

  def set_issued_on
    self.issued_on ||= Date.current
  end
end
