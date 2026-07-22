class TimetableEntry < ApplicationRecord
  belongs_to :course_section
  belongs_to :teacher
  enum :weekday, { monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5 }
  validates :weekday, :period, :starts_at, :ends_at, presence: true
  validates :period, numericality: { only_integer: true, greater_than: 0 }
  validate :ends_after_start

  private

  def ends_after_start
    errors.add(:ends_at, "must be after start time") if starts_at && ends_at && ends_at <= starts_at
  end
end
