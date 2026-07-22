class FeeStructure < ApplicationRecord
  belongs_to :school
  belongs_to :academic_year
  has_many :invoices, dependent: :restrict_with_error
  validates :name, :due_on, presence: true
  validates :amount, numericality: { greater_than: 0 }
end
