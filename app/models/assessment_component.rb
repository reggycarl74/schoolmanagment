class AssessmentComponent < ApplicationRecord
  belongs_to :school
  belongs_to :classroom, optional: true
  enum :kind, Assessment.kinds
  validates :title, :position, presence: true
  validates :title, uniqueness: { scope: %i[school_id classroom_id] }
  validates :position, uniqueness: { scope: %i[school_id classroom_id] }
  validates :maximum_points, numericality: { greater_than: 0 }
end
