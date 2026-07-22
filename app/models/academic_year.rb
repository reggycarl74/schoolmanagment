class AcademicYear < ApplicationRecord
  belongs_to :school
  has_many :terms, dependent: :destroy
  has_many :classrooms, dependent: :restrict_with_error

  validates :name, :starts_on, :ends_on, presence: true
  validates :name, uniqueness: { scope: :school_id }
  validate :ends_after_start

  private

  def ends_after_start
    errors.add(:ends_on, "must be after the start date") if starts_on && ends_on && ends_on <= starts_on
  end
end
