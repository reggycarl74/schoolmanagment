class Subject < ApplicationRecord
  belongs_to :school
  has_many :course_sections, dependent: :restrict_with_error

  validates :name, :code, presence: true
  validates :code, uniqueness: { scope: :school_id }
end
