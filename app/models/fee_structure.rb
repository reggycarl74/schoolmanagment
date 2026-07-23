class FeeStructure < ApplicationRecord
  belongs_to :school
  belongs_to :academic_year
  has_many :invoices, dependent: :restrict_with_error
  enum :frequency, { one_time: 0, daily: 1 }
  validates :name, :due_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :starts_on, presence: true, if: :daily?
  validate :ends_after_start

  def chargeable_on?(date)
    active? && daily? && date >= starts_on && (ends_on.nil? || date <= ends_on) && date.between?(academic_year.starts_on, academic_year.ends_on)
  end

  private

  def ends_after_start
    errors.add(:ends_on, "must be on or after the start date") if starts_on && ends_on && ends_on < starts_on
  end
end
