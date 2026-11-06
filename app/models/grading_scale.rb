class GradingScale < ApplicationRecord
  belongs_to :school
  belongs_to :classroom, optional: true
  validates :letter, :minimum_percentage, presence: true
  validates :letter, uniqueness: { scope: %i[school_id classroom_id] }
  validates :minimum_percentage, numericality: { in: 0..100 }
end
