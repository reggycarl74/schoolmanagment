class GradeLevel < ApplicationRecord
  belongs_to :school
  has_many :classrooms, dependent: :restrict_with_error

  validates :name, :position, presence: true
  validates :name, :position, uniqueness: { scope: :school_id }
end
