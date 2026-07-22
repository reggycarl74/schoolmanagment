class Term < ApplicationRecord
  belongs_to :academic_year
  has_many :course_sections, dependent: :restrict_with_error
  has_many :report_card_comments, dependent: :destroy

  validates :name, :starts_on, :ends_on, :position, presence: true
  validates :position, uniqueness: { scope: :academic_year_id }
  validate :dates_within_academic_year

  private

  def dates_within_academic_year
    return unless academic_year && starts_on && ends_on
    return if starts_on >= academic_year.starts_on && ends_on <= academic_year.ends_on && ends_on > starts_on

    errors.add(:base, "term dates must be ordered and inside the academic year")
  end
end
