class GradingScale < ApplicationRecord
  belongs_to :school
  validates :letter, :minimum_percentage, presence: true
  validates :letter, uniqueness: { scope: :school_id }
  validates :minimum_percentage, numericality: { in: 0..100 }
end
