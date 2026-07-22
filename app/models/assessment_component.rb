class AssessmentComponent < ApplicationRecord
  belongs_to :school
  enum :kind, Assessment.kinds
  validates :title, :position, presence: true
  validates :title, uniqueness: { scope: :school_id }
  validates :maximum_points, numericality: { greater_than: 0 }
end
